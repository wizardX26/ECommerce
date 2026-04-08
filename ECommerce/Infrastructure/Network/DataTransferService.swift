import Foundation

enum DataTransferError: Error {
    case noResponse
    case parsing(Error)
    case networkFailure(NetworkError)
    case resolvedNetworkFailure(Error)
}

protocol DataTransferDispatchQueue {
    func asyncExecute(work: @escaping () -> Void)
}

extension DispatchQueue: DataTransferDispatchQueue {
    func asyncExecute(work: @escaping () -> Void) {
        async(group: nil, execute: work)
    }
}

protocol DataTransferService {
    typealias CompletionHandler<T> = (Result<T, DataTransferError>) -> Void
    
    @discardableResult
    func request<T: Decodable, E: ResponseRequestable>(
        with endpoint: E,
        on queue: DataTransferDispatchQueue,
        completion: @escaping CompletionHandler<T>
    ) -> NetworkCancellable? where E.Response == T
    
    @discardableResult
    func request<T: Decodable, E: ResponseRequestable>(
        with endpoint: E,
        completion: @escaping CompletionHandler<T>
    ) -> NetworkCancellable? where E.Response == T

    @discardableResult
    func request<E: ResponseRequestable>(
        with endpoint: E,
        on queue: DataTransferDispatchQueue,
        completion: @escaping CompletionHandler<Void>
    ) -> NetworkCancellable? where E.Response == Void
    
    @discardableResult
    func request<E: ResponseRequestable>(
        with endpoint: E,
        completion: @escaping CompletionHandler<Void>
    ) -> NetworkCancellable? where E.Response == Void
}

protocol DataTransferErrorResolver {
    func resolve(error: NetworkError) -> Error
}

protocol ResponseDecoder {
    func decode<T: Decodable>(_ data: Data) throws -> T
}

protocol DataTransferErrorLogger {
    func log(error: Error)
}

final class DefaultDataTransferService {
    
    private let networkService: NetworkService
    private let errorResolver: DataTransferErrorResolver
    private let errorLogger: DataTransferErrorLogger
    
    init(
        with networkService: NetworkService,
        errorResolver: DataTransferErrorResolver = DefaultDataTransferErrorResolver(),
        errorLogger: DataTransferErrorLogger = DefaultDataTransferErrorLogger()
    ) {
        self.networkService = networkService
        self.errorResolver = errorResolver
        self.errorLogger = errorLogger
    }
}

extension DefaultDataTransferService: DataTransferService {
    
    func request<T: Decodable, E: ResponseRequestable>(
        with endpoint: E,
        on queue: DataTransferDispatchQueue,
        completion: @escaping CompletionHandler<T>
    ) -> NetworkCancellable? where E.Response == T {

        networkService.request(endpoint: endpoint) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let data):
                let result: Result<T, DataTransferError> = self.decode(
                    data: data,
                    decoder: endpoint.responseDecoder
                )
                queue.asyncExecute { completion(result) }
            case .failure(let error):
                self.errorLogger.log(error: error)
                
                // Handle 401 Unauthorized - token expired, try auto-refresh
                if case .networkFailure(let networkError) = self.resolve(networkError: error),
                   case .error(let statusCode, _) = networkError,
                   statusCode == 401 {
                    
                    print("🔄 [DataTransferService] Received 401 Unauthorized, attempting auto-refresh token...")
                    
                    // QUAN TRỌNG: Kiểm tra user có đang logged in không trước khi refresh
                    // Nếu user đã logout, không nên refresh token
                    let utilities = Utilities()
                    guard utilities.isLoggedIn() else {
                        print("⚠️ [DataTransferService] User is not logged in, skipping token refresh")
                        let error = self.resolve(networkError: error)
                        queue.asyncExecute { completion(.failure(error)) }
                        return
                    }
                    
                    // Try to refresh token
                    let refreshResult = TokenRefreshService.shared.refreshTokenIfNeeded { refreshResult in
                        switch refreshResult {
                        case .success(let newSession):
                            print("✅ [DataTransferService] Token refreshed successfully, retrying original request...")
                            // Retry original request with new token
                            self.networkService.request(endpoint: endpoint) { retryResult in
                                switch retryResult {
                                case .success(let data):
                                    let result: Result<T, DataTransferError> = self.decode(
                                        data: data,
                                        decoder: endpoint.responseDecoder
                                    )
                                    queue.asyncExecute { completion(result) }
                                case .failure(let retryError):
                                    self.errorLogger.log(error: retryError)
                                    let error = self.resolve(networkError: retryError)
                                    queue.asyncExecute { completion(.failure(error)) }
                                }
                            }
                            
                        case .failure(let refreshError):
                            print("❌ [DataTransferService] Token refresh failed: \(refreshError.localizedDescription)")
                            let error = self.resolve(networkError: error)
                            queue.asyncExecute { completion(.failure(error)) }
                        }
                    }
                    
                    // If refresh was not needed (token still valid but 401 received), return original error
                    if !refreshResult {
                        let error = self.resolve(networkError: error)
                        queue.asyncExecute { completion(.failure(error)) }
                    }
                    
                    return
                }
                
                // Other errors - return as is
                let error = self.resolve(networkError: error)
                queue.asyncExecute { completion(.failure(error)) }
            }
        }
    }
    
    func request<T: Decodable, E: ResponseRequestable>(
        with endpoint: E,
        completion: @escaping CompletionHandler<T>
    ) -> NetworkCancellable? where E.Response == T {
        request(with: endpoint, on: DispatchQueue.main, completion: completion)
    }

    func request<E>(
        with endpoint: E,
        on queue: DataTransferDispatchQueue,
        completion: @escaping CompletionHandler<Void>
    ) -> NetworkCancellable? where E : ResponseRequestable, E.Response == Void {
        networkService.request(endpoint: endpoint) { result in
            switch result {
            case .success:
                queue.asyncExecute { completion(.success(())) }
            case .failure(let error):
                self.errorLogger.log(error: error)
                let error = self.resolve(networkError: error)
                queue.asyncExecute { completion(.failure(error)) }
            }
        }
    }

    func request<E>(
        with endpoint: E,
        completion: @escaping CompletionHandler<Void>
    ) -> NetworkCancellable? where E : ResponseRequestable, E.Response == Void {
        request(with: endpoint, on: DispatchQueue.main, completion: completion)
    }

    // MARK: - Private
    private func decode<T: Decodable>(
        data: Data?,
        decoder: ResponseDecoder
    ) -> Result<T, DataTransferError> {
        do {
            guard let data = data else { return .failure(.noResponse) }
            
            // ✅ Xử lý trường hợp data rỗng (0 bytes) - API có thể trả về empty response với status 200
            if data.isEmpty {
                print("⚠️ [DataTransferService] Received empty response (0 bytes) - Cannot decode JSON")
                let underlyingError = NSError(
                    domain: NSCocoaErrorDomain,
                    code: 3840, // JSON parsing error code
                    userInfo: [NSLocalizedDescriptionKey: "Unexpected end of file"]
                )
                let error = DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: [],
                        debugDescription: "Empty response data received from server. Expected JSON but got 0 bytes.",
                        underlyingError: underlyingError
                    )
                )
                self.errorLogger.log(error: error)
                return .failure(.parsing(error))
            }
            
            // Validate data là JSON hợp lệ trước khi decode
            let jsonString = String(data: data, encoding: .utf8) ?? ""
            let trimmedString = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if trimmedString.isEmpty {
                print("⚠️ [DataTransferService] Response contains only whitespace")
                let underlyingError = NSError(
                    domain: NSCocoaErrorDomain,
                    code: 3840,
                    userInfo: [NSLocalizedDescriptionKey: "Unexpected end of file"]
                )
                let error = DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: [],
                        debugDescription: "Response contains only whitespace. Expected JSON but got empty string.",
                        underlyingError: underlyingError
                    )
                )
                self.errorLogger.log(error: error)
                return .failure(.parsing(error))
            }
            
            // Thử parse JSON để validate trước khi decode
            do {
                _ = try JSONSerialization.jsonObject(with: data, options: [])
            } catch {
                print("⚠️ [DataTransferService] Invalid JSON format: \(error.localizedDescription)")
                print("   Response string (first 200 chars): \(String(trimmedString.prefix(200)))")
                let decodingError = DecodingError.dataCorrupted(
                    DecodingError.Context(
                        codingPath: [],
                        debugDescription: "Invalid JSON format: \(error.localizedDescription)",
                        underlyingError: error
                    )
                )
                self.errorLogger.log(error: decodingError)
                return .failure(.parsing(decodingError))
            }
            
            let result: T = try decoder.decode(data)
            return .success(result)
        } catch {
            self.errorLogger.log(error: error)
            return .failure(.parsing(error))
        }
    }
    
    private func resolve(networkError error: NetworkError) -> DataTransferError {
        let resolvedError = self.errorResolver.resolve(error: error)
        return resolvedError is NetworkError
        ? .networkFailure(error)
        : .resolvedNetworkFailure(resolvedError)
    }
}

// MARK: - Logger
final class DefaultDataTransferErrorLogger: DataTransferErrorLogger {
    init() { }
    
    func log(error: Error) {
        print("-------------")
        print("❌ [DataTransferService] Error occurred:")
        print("   Error: \(error)")
        print("   Localized Description: \(error.localizedDescription)")
        
        // Log chi tiết cho DataTransferError
        if let dataTransferError = error as? DataTransferError {
            switch dataTransferError {
            case .noResponse:
                print("   Type: No Response")
            case .parsing(let parsingError):
                print("   Type: Parsing Error")
                print("   Parsing Error: \(parsingError.localizedDescription)")
                if let decodingError = parsingError as? DecodingError {
                    print("   Decoding Error Details: \(decodingError)")
                }
            case .networkFailure(let networkError):
                print("   Type: Network Failure")
                switch networkError {
                case .error(let statusCode, let data):
                    print("   HTTP Status Code: \(statusCode)")
                    if let data = data, let errorDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                        print("   Error Response: \(errorDict)")
                    } else if let data = data, let errorString = String(data: data, encoding: .utf8) {
                        print("   Error Response: \(errorString)")
                    }
                case .notConnected:
                    print("   Type: Not Connected to Internet")
                case .cancelled:
                    print("   Type: Request Cancelled")
                case .generic(let genericError):
                    print("   Type: Generic Network Error")
                    print("   Generic Error: \(genericError.localizedDescription)")
                    if let nsError = genericError as? NSError {
                        print("   NSError Code: \(nsError.code)")
                        print("   NSError Domain: \(nsError.domain)")
                    }
                case .urlGeneration:
                    print("   Type: URL Generation Error")
                }
            case .resolvedNetworkFailure(let resolvedError):
                print("   Type: Resolved Network Failure")
                print("   Resolved Error: \(resolvedError.localizedDescription)")
                if let nsError = resolvedError as? NSError {
                    print("   NSError Code: \(nsError.code)")
                    print("   NSError Domain: \(nsError.domain)")
                }
            }
        } else if let nsError = error as? NSError {
            print("   NSError Code: \(nsError.code)")
            print("   NSError Domain: \(nsError.domain)")
            print("   User Info: \(nsError.userInfo)")
        }
        print("-------------")
    }
}

// MARK: - Error Resolver
class DefaultDataTransferErrorResolver: DataTransferErrorResolver {
    init() { }
    func resolve(error: NetworkError) -> Error {
        return error
    }
}

// MARK: - Response Decoders
class JSONResponseDecoder: ResponseDecoder {
    private let jsonDecoder = JSONDecoder()
    init() { }
    func decode<T: Decodable>(_ data: Data) throws -> T {
        return try jsonDecoder.decode(T.self, from: data)
    }
}

class RawDataResponseDecoder: ResponseDecoder {
    init() { }
    
    enum CodingKeys: String, CodingKey {
        case `default` = ""
    }
    func decode<T: Decodable>(_ data: Data) throws -> T {
        if T.self is Data.Type, let data = data as? T {
            return data
        } else {
            let context = DecodingError.Context(
                codingPath: [CodingKeys.default],
                debugDescription: "Expected Data type"
            )
            throw Swift.DecodingError.typeMismatch(T.self, context)
        }
    }
}
