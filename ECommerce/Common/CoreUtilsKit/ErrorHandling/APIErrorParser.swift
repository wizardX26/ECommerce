//
//  APIErrorParser.swift
//  ECommerce
//
//  Created by wizard.os25 on 9/1/26.
//

import Foundation

/// Helper to parse error messages from API error responses
struct APIErrorParser {
    
    /// Parse error message from DataTransferError
    static func parseErrorMessage(from error: Error) -> String {
        // Check if it's a DataTransferError
        if let dataTransferError = error as? DataTransferError {
            return parseErrorMessage(from: dataTransferError)
        }
        
        // Check if it's a NetworkError
        if let networkError = error as? NetworkError {
            return parseErrorMessage(from: networkError)
        }
        
        // Fallback: sử dụng parseGenericError để có message thân thiện hơn
        return parseGenericError(error)
    }
    
    /// Parse error message from DataTransferError
    static func parseErrorMessage(from error: DataTransferError) -> String {
        switch error {
        case .networkFailure(let networkError):
            return parseErrorMessage(from: networkError)
        case .parsing(let parsingError):
            // Try to parse API error response from parsing error
            if let decodingError = parsingError as? DecodingError {
                return parseDecodingError(decodingError)
            }
            return parsingError.localizedDescription
        case .resolvedNetworkFailure(let resolvedError):
            if let networkError = resolvedError as? NetworkError {
                return parseErrorMessage(from: networkError)
            }
            // Sử dụng parseGenericError để có message thân thiện hơn
            return parseGenericError(resolvedError)
        case .noResponse:
            return "Không nhận được phản hồi từ máy chủ. Vui lòng thử lại."
        }
    }
    
    /// Parse error message from NetworkError
    static func parseErrorMessage(from error: NetworkError) -> String {
        switch error {
        case .error(let statusCode, let data):
            // Try to parse error message from response data
            if let errorMessage = parseAPIErrorResponse(data: data) {
                return errorMessage
            }
            
            // Fallback to status code based message
            return getDefaultErrorMessage(for: statusCode)
        case .notConnected:
            return "Không có kết nối internet. Vui lòng kiểm tra mạng và thử lại."
        case .cancelled:
            return "Yêu cầu đã bị hủy."
        case .generic(let genericError):
            return parseGenericError(genericError)
        case .urlGeneration:
            return "Yêu cầu không hợp lệ. Vui lòng thử lại."
        }
    }
    
    /// Parse generic error to get user-friendly message
    private static func parseGenericError(_ error: Error) -> String {
        if let nsError = error as? NSError {
            let errorCode = nsError.code
            let errorDomain = nsError.domain
            
            // Xử lý các lỗi network phổ biến
            if errorDomain == NSURLErrorDomain {
                switch errorCode {
                case NSURLErrorTimedOut:
                    return "Kết nối quá thời gian. Vui lòng kiểm tra mạng và thử lại."
                case NSURLErrorCannotConnectToHost:
                    return "Không thể kết nối đến máy chủ. Vui lòng thử lại sau."
                case NSURLErrorNetworkConnectionLost:
                    return "Kết nối mạng bị mất. Vui lòng kiểm tra mạng và thử lại."
                case NSURLErrorCannotFindHost:
                    return "Không tìm thấy máy chủ. Vui lòng kiểm tra kết nối mạng."
                case NSURLErrorDNSLookupFailed:
                    return "Lỗi kết nối mạng. Vui lòng kiểm tra kết nối và thử lại."
                case NSURLErrorNotConnectedToInternet:
                    return "Không có kết nối internet. Vui lòng kiểm tra mạng và thử lại."
                case NSURLErrorInternationalRoamingOff:
                    return "Roaming quốc tế đã tắt. Vui lòng bật roaming hoặc sử dụng Wi-Fi."
                case NSURLErrorCallIsActive:
                    return "Cuộc gọi đang diễn ra. Vui lòng kết thúc cuộc gọi và thử lại."
                case NSURLErrorDataNotAllowed:
                    return "Dữ liệu di động không được phép. Vui lòng kiểm tra cài đặt mạng."
                case NSURLErrorRequestBodyStreamExhausted:
                    return "Lỗi khi gửi dữ liệu. Vui lòng thử lại."
                default:
                    // Nếu là error code 1 hoặc các lỗi khác
                    if errorCode == 1 {
                        return "Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng và thử lại."
                    }
                    return "Lỗi kết nối mạng. Vui lòng thử lại sau. (Mã lỗi: \(errorCode))"
                }
            }
            
            // Xử lý các domain khác
            if errorDomain == "ECommerce.DataTransferError" {
                if errorCode == 1 {
                    return "Không thể kết nối đến máy chủ. Vui lòng kiểm tra kết nối mạng và thử lại."
                }
            }
            
            // Fallback: sử dụng localized description nếu có, nếu không thì message mặc định
            let localizedDesc = nsError.localizedDescription
            if !localizedDesc.isEmpty && localizedDesc != "The operation could not be completed." {
                return localizedDesc
            }
            
            return "Đã xảy ra lỗi. Vui lòng thử lại sau."
        }
        
        // Fallback cho các error types khác
        let localizedDesc = error.localizedDescription
        if !localizedDesc.isEmpty && !localizedDesc.contains("error 1") && !localizedDesc.contains("DataTransferError") {
            return localizedDesc
        }
        
        return "Đã xảy ra lỗi. Vui lòng thử lại sau."
    }
    
    /// Parse API error response structure: { "statusCode": 400, "success": false, "message": "Error message" }
    private static func parseAPIErrorResponse(data: Data?) -> String? {
        guard let data = data else { return nil }
        
        // Debug: Print raw response data in debug mode
        #if DEBUG
        if let jsonString = String(data: data, encoding: .utf8) {
            print("API Error Response: \(jsonString)")
        }
        #endif
        
        // First try to parse as dictionary to be more flexible
        if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] {
            // Check for "errors" array with objects (format: [{"field":"...","code":"...","message":"..."}])
            if let errorsArray = jsonObject["errors"] as? [[String: Any]], !errorsArray.isEmpty {
                let errorMessages = errorsArray.compactMap { errorObj -> String? in
                    if let message = errorObj["message"] as? String, !message.isEmpty {
                        return message
                    }
                    return nil
                }
                if !errorMessages.isEmpty {
                    return errorMessages.joined(separator: ". ")
                }
            }
            
            // Check for "errors" array of strings (some APIs return errors as array of strings)
            if let errors = jsonObject["errors"] as? [String], !errors.isEmpty {
                return errors.joined(separator: ". ")
            }
            
            // Check for "message" key (most common)
            if let message = jsonObject["message"] as? String, !message.isEmpty {
                return message
            }
            
            // Check for "error" key
            if let errorMessage = jsonObject["error"] as? String, !errorMessage.isEmpty {
                return errorMessage
            }
            
            // Check for nested error message
            if let errorDict = jsonObject["error"] as? [String: Any],
               let message = errorDict["message"] as? String, !message.isEmpty {
                return message
            }
            
            // Check for "detail" key (some APIs use this)
            if let detail = jsonObject["detail"] as? String, !detail.isEmpty {
                return detail
            }
        }
        
        // Try to decode as structured API error response
        do {
            let errorResponse = try JSONDecoder().decode(APIErrorResponse.self, from: data)
            if !errorResponse.message.isEmpty {
                return errorResponse.message
            }
        } catch {
            // Decoding failed, but we already tried dictionary parsing above
            #if DEBUG
            print("Failed to decode API error response: \(error)")
            #endif
        }
        
        return nil
    }
    
    /// Get default error message based on HTTP status code
    private static func getDefaultErrorMessage(for statusCode: Int) -> String {
        switch statusCode {
        case 400:
            return "Yêu cầu không hợp lệ. Vui lòng kiểm tra thông tin và thử lại."
        case 401:
            return "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại."
        case 403:
            return "Không có quyền truy cập. Vui lòng kiểm tra tài khoản hoặc liên hệ hỗ trợ."
        case 404:
            return "Không tìm thấy tài nguyên."
        case 422:
            return "Dữ liệu không hợp lệ. Vui lòng kiểm tra thông tin và thử lại."
        case 500:
            return "Lỗi máy chủ. Vui lòng thử lại sau."
        case 503:
            return "Dịch vụ tạm thời không khả dụng. Vui lòng thử lại sau."
        default:
            return "Đã xảy ra lỗi. Vui lòng thử lại sau. (Mã lỗi: \(statusCode))"
        }
    }
    
    /// Parse DecodingError to get more specific error message
    private static func parseDecodingError(_ error: DecodingError) -> String {
        switch error {
        case .dataCorrupted(let context):
            return "Dữ liệu phản hồi không hợp lệ. Vui lòng thử lại sau."
        case .keyNotFound(let key, let context):
            return "Thiếu trường dữ liệu: \(key.stringValue). Vui lòng thử lại sau."
        case .typeMismatch(let type, let context):
            return "Lỗi định dạng dữ liệu. Vui lòng thử lại sau."
        case .valueNotFound(let type, let context):
            return "Thiếu giá trị dữ liệu. Vui lòng thử lại sau."
        @unknown default:
            return "Không thể xử lý phản hồi từ máy chủ. Vui lòng thử lại."
        }
    }
}

/// API Error Response structure
private struct APIErrorResponse: Decodable {
    let statusCode: Int
    let success: Bool
    let message: String
    let data: String?
    
    enum CodingKeys: String, CodingKey {
        case statusCode
        case success
        case message
        case data
    }
}
