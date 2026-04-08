//
//  RelativeTimeFormatter.swift
//  ECommerce
//
//  Created by wizard.os25 on 20/1/26.
//

import Foundation

struct RelativeTimeFormatter {
    /**
     * Format timestamp thành relative time tiếng Việt
     * 
     * @param timestamp: ISO8601 string từ backend (ví dụ: "2026-01-20T10:30:00Z" hoặc "2026-01-20T00:26:35+07:00")
     * @return: String như "vừa xong", "2 phút trước", "1 giờ trước"
     */
    static func format(_ timestamp: String) -> String {
        // Try ISO8601 format first (with timezone and fractional seconds)
        let iso8601Formatter = ISO8601DateFormatter()
        iso8601Formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = iso8601Formatter.date(from: timestamp) {
            return format(from: date)
        }
        
        // Try ISO8601 without fractional seconds
        let iso8601SimpleFormatter = ISO8601DateFormatter()
        iso8601SimpleFormatter.formatOptions = [.withInternetDateTime]
        
        if let date = iso8601SimpleFormatter.date(from: timestamp) {
            return format(from: date)
        }
        
        // Try standard date format "yyyy-MM-dd HH:mm:ss" (common in backend)
        let standardFormatter = DateFormatter()
        standardFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        standardFormatter.locale = Locale(identifier: "en_US_POSIX")
        standardFormatter.timeZone = TimeZone(identifier: "UTC")
        
        if let date = standardFormatter.date(from: timestamp) {
            return format(from: date)
        }
        
        // Try ISO8601 with timezone offset "yyyy-MM-dd'T'HH:mm:ss+HH:mm" or "yyyy-MM-dd'T'HH:mm:ssZ"
        let iso8601WithTZFormatter = DateFormatter()
        iso8601WithTZFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        iso8601WithTZFormatter.locale = Locale(identifier: "en_US_POSIX")
        
        if let date = iso8601WithTZFormatter.date(from: timestamp) {
            return format(from: date)
        }
        
        // Try ISO8601 without timezone "yyyy-MM-dd'T'HH:mm:ss"
        let iso8601NoTZFormatter = DateFormatter()
        iso8601NoTZFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        iso8601NoTZFormatter.locale = Locale(identifier: "en_US_POSIX")
        iso8601NoTZFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = iso8601NoTZFormatter.date(from: timestamp) {
            return format(from: date)
        }
        
        // Try format with Z suffix
        let zFormatter = DateFormatter()
        zFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        zFormatter.locale = Locale(identifier: "en_US_POSIX")
        zFormatter.timeZone = TimeZone(abbreviation: "UTC")
        
        if let date = zFormatter.date(from: timestamp) {
            return format(from: date)
        }
        
        // If all parsing fails, try one more time with flexible parsing
        // Remove any extra whitespace
        let cleanedTimestamp = timestamp.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Try to detect and parse format dynamically
        if cleanedTimestamp.contains("T") {
            // ISO8601-like format
            if let date = parseISO8601Flexible(cleanedTimestamp) {
                return format(from: date)
            }
        } else if cleanedTimestamp.contains(" ") {
            // Standard date format "yyyy-MM-dd HH:mm:ss"
            if let date = parseStandardDate(cleanedTimestamp) {
                return format(from: date)
            }
        }
        
        // If all parsing fails, return error message with original timestamp for debugging
        print("⚠️ [RelativeTimeFormatter] Unable to parse timestamp: '\(timestamp)' (length: \(timestamp.count))")
        // Return original timestamp for debugging (remove this in production if needed)
        return timestamp.count > 20 ? String(timestamp.prefix(20)) : timestamp
    }
    
    private static func parseISO8601Flexible(_ timestamp: String) -> Date? {
        let patterns = [
            "yyyy-MM-dd'T'HH:mm:ss.SSSZ",
            "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'",
            "yyyy-MM-dd'T'HH:mm:ssZ",
            "yyyy-MM-dd'T'HH:mm:ss'Z'",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd'T'HH:mmZ",
            "yyyy-MM-dd'T'HH:mm'Z'"
        ]
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        
        for pattern in patterns {
            formatter.dateFormat = pattern
            if pattern.contains("Z") && !pattern.contains("'Z'") {
                // Timezone offset
                if let date = formatter.date(from: timestamp) {
                    return date
                }
            } else if pattern.contains("'Z'") {
                // UTC timezone
                formatter.timeZone = TimeZone(abbreviation: "UTC")
                if let date = formatter.date(from: timestamp) {
                    return date
                }
            } else {
                // No timezone, assume UTC
                formatter.timeZone = TimeZone(abbreviation: "UTC")
                if let date = formatter.date(from: timestamp) {
                    return date
                }
            }
        }
        
        return nil
    }
    
    private static func parseStandardDate(_ timestamp: String) -> Date? {
        let patterns = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd HH:mm",
            "yyyy/MM/dd HH:mm:ss",
            "yyyy/MM/dd HH:mm"
        ]
        
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        
        for pattern in patterns {
            formatter.dateFormat = pattern
            if let date = formatter.date(from: timestamp) {
                return date
            }
        }
        
        return nil
    }
    
    /**
     * Format Date thành relative time
     */
    private static func format(from date: Date) -> String {
        let now = Date()
        let timeInterval = now.timeIntervalSince(date)
        
        // Convert seconds to appropriate unit
        if timeInterval < 60 {
            return "vừa xong"
        } else if timeInterval < 3600 {
            // Less than 1 hour
            let minutes = Int(timeInterval / 60)
            return "\(minutes) phút trước"
        } else if timeInterval < 86400 {
            // Less than 1 day
            let hours = Int(timeInterval / 3600)
            return "\(hours) giờ trước"
        } else if timeInterval < 604800 {
            // Less than 1 week
            let days = Int(timeInterval / 86400)
            return "\(days) ngày trước"
        } else if timeInterval < 2592000 {
            // Less than 1 month (~30 days)
            let weeks = Int(timeInterval / 604800)
            return "\(weeks) tuần trước"
        } else if timeInterval < 31536000 {
            // Less than 1 year
            let months = Int(timeInterval / 2592000)
            return "\(months) tháng trước"
        } else {
            // 1 year or more
            let years = Int(timeInterval / 31536000)
            return "\(years) năm trước"
        }
    }
}
