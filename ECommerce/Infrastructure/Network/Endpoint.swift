import Foundation

enum HTTPMethodType: String {
    case get     = "GET"
    case head    = "HEAD"
    case post    = "POST"
    case put     = "PUT"
    case patch   = "PATCH"
    case delete  = "DELETE"
}

class Endpoint<R>: ResponseRequestable {
    
    typealias Response = R
    
    let path: String
    let isFullPath: Bool
    let method: HTTPMethodType
    let headerParameters: [String: String]
    let queryParametersEncodable: Encodable?
    let queryParameters: [String: Any]
    let bodyParametersEncodable: Encodable?
    let bodyParameters: [String: Any]
    let bodyEncoder: BodyEncoder
    let responseDecoder: ResponseDecoder
    
    init(path: String,
         isFullPath: Bool = false,
         method: HTTPMethodType,
         headerParameters: [String: String] = [:],
         queryParametersEncodable: Encodable? = nil,
         queryParameters: [String: Any] = [:],
         bodyParametersEncodable: Encodable? = nil,
         bodyParameters: [String: Any] = [:],
         bodyEncoder: BodyEncoder = JSONBodyEncoder(),
         responseDecoder: ResponseDecoder = JSONResponseDecoder()) {
        self.path = path
        self.isFullPath = isFullPath
        self.method = method
        self.headerParameters = headerParameters
        self.queryParametersEncodable = queryParametersEncodable
        self.queryParameters = queryParameters
        self.bodyParametersEncodable = bodyParametersEncodable
        self.bodyParameters = bodyParameters
        self.bodyEncoder = bodyEncoder
        self.responseDecoder = responseDecoder
    }
}

protocol BodyEncoder {
    func encode(_ parameters: [String: Any]) -> Data?
}

struct JSONBodyEncoder: BodyEncoder {
    func encode(_ parameters: [String: Any]) -> Data? {
        return try? JSONSerialization.data(withJSONObject: parameters)
    }
}

struct AsciiBodyEncoder: BodyEncoder {
    func encode(_ parameters: [String: Any]) -> Data? {
        return parameters.queryString.data(using: String.Encoding.ascii, allowLossyConversion: true)
    }
}

protocol Requestable {
    var path: String { get }
    var isFullPath: Bool { get }
    var method: HTTPMethodType { get }
    var headerParameters: [String: String] { get }
    var queryParametersEncodable: Encodable? { get }
    var queryParameters: [String: Any] { get }
    var bodyParametersEncodable: Encodable? { get }
    var bodyParameters: [String: Any] { get }
    var bodyEncoder: BodyEncoder { get }
    
    func urlRequest(with networkConfig: NetworkConfigurable) throws -> URLRequest
}

protocol ResponseRequestable: Requestable {
    associatedtype Response
    
    var responseDecoder: ResponseDecoder { get }
}

enum RequestGenerationError: Error {
    case components
}

extension Requestable {
    
    func url(with config: NetworkConfigurable) throws -> URL {

        let baseURL = config.baseURL.absoluteString.last != "/"
        ? config.baseURL.absoluteString + "/"
        : config.baseURL.absoluteString
        let endpoint = isFullPath ? path : baseURL.appending(path)
        
        guard var urlComponents = URLComponents(
            string: endpoint
        ) else { throw RequestGenerationError.components }
        var urlQueryItems = [URLQueryItem]()

        let queryParameters = try queryParametersEncodable?.toDictionary() ?? self.queryParameters
        queryParameters.forEach {
            urlQueryItems.append(URLQueryItem(name: $0.key, value: "\($0.value)"))
        }
        config.queryParameters.forEach {
            urlQueryItems.append(URLQueryItem(name: $0.key, value: $0.value))
        }
        urlComponents.queryItems = !urlQueryItems.isEmpty ? urlQueryItems : nil
        guard let url = urlComponents.url else { throw RequestGenerationError.components }
        return url
    }
    
    func urlRequest(with config: NetworkConfigurable) throws -> URLRequest {
        
        let url = try self.url(with: config)
        var urlRequest = URLRequest(url: url)
        var allHeaders: [String: String] = config.headers
        headerParameters.forEach { allHeaders.updateValue($1, forKey: $0) }
        
        // Check if this is a public endpoint (login, signup, register) - these should NOT have Bearer token
        let isPublicEndpoint = isPublicAuthEndpoint(path: path)
        
        // Add Bearer token from access_token if available (for authenticated requests)
        // Only add if not already present (to allow override) AND not a public endpoint
        if allHeaders["Authorization"] == nil && !isPublicEndpoint {
            let utilities = Utilities()
            
            // Check if token is expired before using it
            // Note: Auto-refresh will be handled in DataTransferService if 401 is returned
            if utilities.isSessionExpired() {
                print("⚠️ [Endpoint] Access token is expired, will attempt refresh if 401 is returned")
            }
            
            if let accessToken = utilities.getAccessToken(), !accessToken.isEmpty {
                allHeaders["Authorization"] = "Bearer \(accessToken)"
                print("🔐 [Endpoint] Added Bearer token to Authorization header")
                print("   - Token prefix: \(accessToken.prefix(20))...")
                if utilities.isSessionExpired() {
                    print("   - ⚠️ Token is expired, request may fail with 401")
                }
            } else {
                print("⚠️ [Endpoint] No access token found, request will be unauthenticated")
            }
        } else if isPublicEndpoint {
            print("🔓 [Endpoint] Public auth endpoint detected - skipping Bearer token")
        }

        // Handle body parameters
        if let encodable = bodyParametersEncodable {
            // Encode Encodable directly to JSON Data
            let encoder = JSONEncoder()
            encoder.keyEncodingStrategy = .useDefaultKeys
            urlRequest.httpBody = try encoder.encode(encodable)
            // Set Content-Type header if not already set
            if allHeaders["Content-Type"] == nil {
                allHeaders["Content-Type"] = "application/json"
            }
        } else if !bodyParameters.isEmpty {
            urlRequest.httpBody = bodyEncoder.encode(bodyParameters)
            // Set Content-Type header if not already set
            if allHeaders["Content-Type"] == nil {
                allHeaders["Content-Type"] = "application/json"
            }
        }
        
        urlRequest.httpMethod = method.rawValue
        urlRequest.allHTTPHeaderFields = allHeaders
        return urlRequest
    }
}

private extension Dictionary {
    var queryString: String {
        return self.map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed) ?? ""
    }
}

private extension Encodable {
    func toDictionary() throws -> [String: Any]? {
        let data = try JSONEncoder().encode(self)
        let jsonData = try JSONSerialization.jsonObject(with: data)
        return jsonData as? [String : Any]
    }
}

/// Helper to check if an endpoint path is a public auth endpoint (login, signup, register)
/// These endpoints should NOT have Bearer token in Authorization header
private func isPublicAuthEndpoint(path: String) -> Bool {
    let publicAuthPaths = [
        "api/v1/auth/login",
        "api/v1/auth/register",
        "api/v1/auth/signup"
    ]
    
    return publicAuthPaths.contains { publicPath in
        path.contains(publicPath)
    }
}
