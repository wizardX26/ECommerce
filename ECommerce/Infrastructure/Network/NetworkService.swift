import Foundation

enum NetworkError: Error {
    case error(statusCode: Int, data: Data?)
    case notConnected
    case cancelled
    case generic(Error)
    case urlGeneration
}

protocol NetworkCancellable {
    func cancel()
}

extension URLSessionTask: NetworkCancellable { }

protocol NetworkService {
    typealias CompletionHandler = (Result<Data?, NetworkError>) -> Void
    
    func request(endpoint: Requestable, completion: @escaping CompletionHandler) -> NetworkCancellable?
}

protocol NetworkSessionManager {
    typealias CompletionHandler = (Data?, URLResponse?, Error?) -> Void
    
    func request(_ request: URLRequest,
                 completion: @escaping CompletionHandler) -> NetworkCancellable
}

protocol NetworkErrorLogger {
    func log(request: URLRequest)
    func log(responseData data: Data?, response: URLResponse?)
    func log(error: Error)
}

// MARK: - Implementation

final class DefaultNetworkService {
    
    private let config: NetworkConfigurable
    private let sessionManager: NetworkSessionManager
    private let logger: NetworkErrorLogger
    
    init(
        config: NetworkConfigurable,
        sessionManager: NetworkSessionManager = DefaultNetworkSessionManager(),
        logger: NetworkErrorLogger = DefaultNetworkErrorLogger()
    ) {
        self.sessionManager = sessionManager
        self.config = config
        self.logger = logger
    }
    
    private func request(
        request: URLRequest,
        completion: @escaping CompletionHandler
    ) -> NetworkCancellable {
        
        let startTime = Date()
        let sessionDataTask = sessionManager.request(request) { data, response, requestError in
            let elapsedTime = Date().timeIntervalSince(startTime)
            printIfDebug("⏱️ Request completed in \(String(format: "%.2f", elapsedTime))s - \(request.url?.absoluteString ?? "unknown")")
            
            // Check for URLSession errors (network errors like no connection, timeout)
            if let requestError = requestError {
                var error: NetworkError
                if let response = response as? HTTPURLResponse {
                    error = .error(statusCode: response.statusCode, data: data)
                } else {
                    error = self.resolve(error: requestError)
                }
                
                self.logger.log(error: error)
                completion(.failure(error))
                return
            }
            
            // IMPORTANT: URLSession does NOT treat HTTP error status codes (4xx, 5xx) as errors
            // It only treats network errors (no connection, timeout) as errors
            // So we need to check HTTP status code manually
            if let httpResponse = response as? HTTPURLResponse {
                let statusCode = httpResponse.statusCode
                
                // Success status codes: 200-299
                if (200...299).contains(statusCode) {
                    self.logger.log(responseData: data, response: response)
                    completion(.success(data))
                } else {
                    // HTTP error status codes (4xx, 5xx) - treat as error
                    let error = NetworkError.error(statusCode: statusCode, data: data)
                    self.logger.log(error: error)
                    completion(.failure(error))
                }
            } else {
                // No HTTP response (for non-HTTP protocols) - treat as success
                self.logger.log(responseData: data, response: response)
                completion(.success(data))
            }
        }
    
        logger.log(request: request)

        return sessionDataTask
    }
    
    private func resolve(error: Error) -> NetworkError {
        let nsError = error as NSError
        let code = URLError.Code(rawValue: nsError.code)
        
        // Enhanced error logging for debugging
        printIfDebug("🔴 Network Error: \(nsError.localizedDescription)")
        printIfDebug("   Error Code: \(nsError.code)")
        printIfDebug("   Error Domain: \(nsError.domain)")
        if let url = nsError.userInfo[NSURLErrorFailingURLErrorKey] as? URL {
            printIfDebug("   Failed URL: \(url.absoluteString)")
        }
        
        switch code {
        case .notConnectedToInternet: 
            printIfDebug("   Error Type: Not Connected to Internet")
            return .notConnected
        case .cancelled: 
            printIfDebug("   Error Type: Request Cancelled")
            return .cancelled
        case .timedOut:
            printIfDebug("   Error Type: Request Timed Out")
            return .generic(error)
        case .cannotConnectToHost:
            printIfDebug("   Error Type: Cannot Connect to Host")
            return .generic(error)
        case .networkConnectionLost:
            printIfDebug("   Error Type: Network Connection Lost")
            return .generic(error)
        case .cannotFindHost:
            printIfDebug("   Error Type: Cannot Find Host")
            return .generic(error)
        default: 
            printIfDebug("   Error Type: Generic Error")
            return .generic(error)
        }
    }
}

extension DefaultNetworkService: NetworkService {
    
    func request(
        endpoint: Requestable,
        completion: @escaping CompletionHandler
    ) -> NetworkCancellable? {
        do {
            let urlRequest = try endpoint.urlRequest(with: config)
            return request(request: urlRequest, completion: completion)
        } catch {
            completion(.failure(.urlGeneration))
            return nil
        }
    }
}

// MARK: - Default Network Session Manager
// Note: If authorization is needed NetworkSessionManager can be implemented by using,
// for example, Alamofire SessionManager with its RequestAdapter and RequestRetrier.
// And it can be injected into NetworkService instead of default one.

final class DefaultNetworkSessionManager: NetworkSessionManager {
    
    private lazy var session: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.allowsCellularAccess = true
        // Bỏ waitsForConnectivity để tránh đợi quá lâu khi mạng không ổn định
        // Nếu set true, app sẽ đợi vài phút khi mạng yếu, làm loading lâu
        configuration.waitsForConnectivity = false
        
        // Timeout tăng lên 60s để xử lý các request chậm hoặc network không ổn định
        // timeoutIntervalForRequest: thời gian đợi response từ server (60s)
        configuration.timeoutIntervalForRequest = 30
        
        // timeoutIntervalForResource: tổng thời gian cho toàn bộ request (120s)
        configuration.timeoutIntervalForResource = 120
        
        // Tăng số kết nối đồng thời để tăng tốc độ
        configuration.httpMaximumConnectionsPerHost = 6
        
        // Cache configuration
        configuration.urlCache = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 50 * 1024 * 1024, diskPath: nil)
        configuration.requestCachePolicy = .useProtocolCachePolicy
        
        // Thêm các header mặc định để đảm bảo compatibility
        configuration.httpAdditionalHeaders = [
            "Accept": "application/json",
            "Accept-Language": NSLocale.preferredLanguages.first ?? "en"
        ]
        
        // Log configuration để debug
        print("🔧 [URLSession] Configuration:")
        print("   Allows Cellular: \(configuration.allowsCellularAccess)")
        print("   Waits For Connectivity: \(configuration.waitsForConnectivity)")
        print("   Request Timeout: \(configuration.timeoutIntervalForRequest)s")
        print("   Resource Timeout: \(configuration.timeoutIntervalForResource)s")
        print("   Max Connections Per Host: \(configuration.httpMaximumConnectionsPerHost)")
        
        return URLSession(configuration: configuration)
    }()
    
    func request(
        _ request: URLRequest,
        completion: @escaping CompletionHandler
    ) -> NetworkCancellable {
        let task = session.dataTask(with: request, completionHandler: completion)
        task.resume()
        return task
    }
}

// MARK: - Logger

final class DefaultNetworkErrorLogger: NetworkErrorLogger {
    init() { }

    func log(request: URLRequest) {
        print("-------------")
        print("🌐 [Network] Starting Request")
        print("   URL: \(request.url?.absoluteString ?? "nil")")
        print("   Method: \(request.httpMethod ?? "UNKNOWN")")
        print("   Headers: \(request.allHTTPHeaderFields ?? [:])")
        if let url = request.url {
            print("   Host: \(url.host ?? "nil")")
            print("   Port: \(url.port?.description ?? "default")")
            print("   Scheme: \(url.scheme ?? "nil")")
        }
        if let httpBody = request.httpBody {
            // Try to parse as JSON first
            if let jsonObject = try? JSONSerialization.jsonObject(with: httpBody, options: []) as? [String: Any] {
                printIfDebug("body: \(jsonObject)")
            } else if let resultString = String(data: httpBody, encoding: .utf8) {
                printIfDebug("body: \(resultString)")
            } else {
                printIfDebug("body: <\(httpBody.count) bytes>")
            }
        }
    }

    func log(responseData data: Data?, response: URLResponse?) {
        guard let _ = data else { return }
        if let httpResponse = response as? HTTPURLResponse {
            print("✅ [Network] Response Success")
            print("   Status Code: \(httpResponse.statusCode)")
            print("   URL: \(httpResponse.url?.absoluteString ?? "nil")")
            if let data = data {
                print("   Data Size: \(data.count) bytes")
            }
        }
//        if let dataDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
//            printIfDebug("responseData: \(String(describing: dataDict))")
//        }
    }

    func log(error: Error) {
        print("❌ [Network] Request Failed")
        print("   Error: \(error.localizedDescription)")
        
        // Log HTTP error details for debugging
        if let networkError = error as? NetworkError,
           case .error(let statusCode, let data) = networkError {
            print("   HTTP Status Code: \(statusCode)")
            if let data = data,
               let errorDict = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
                print("   Error Response Body: \(String(describing: errorDict))")
            }
        } else {
            // Log NSError details
            let nsError = error as NSError
            print("   Error Domain: \(nsError.domain)")
            print("   Error Code: \(nsError.code)")
            if let url = nsError.userInfo[NSURLErrorFailingURLErrorKey] as? URL {
                print("   Failed URL: \(url.absoluteString)")
            }
            if let description = nsError.userInfo[NSLocalizedDescriptionKey] as? String {
                print("   Description: \(description)")
            }
        }
    }
}

// MARK: - NetworkError extension

extension NetworkError {
    var isNotFoundError: Bool { return hasStatusCode(404) }
    
    func hasStatusCode(_ codeError: Int) -> Bool {
        switch self {
        case let .error(code, _):
            return code == codeError
        default: return false
        }
    }
}

extension Dictionary where Key == String {
    func prettyPrint() -> String {
        var string: String = ""
        if let data = try? JSONSerialization.data(withJSONObject: self, options: .prettyPrinted) {
            if let nstr = NSString(data: data, encoding: String.Encoding.utf8.rawValue) {
                string = nstr as String
            }
        }
        return string
    }
}

func printIfDebug(_ string: String) {
    #if DEBUG
    print(string)
    #endif
}
