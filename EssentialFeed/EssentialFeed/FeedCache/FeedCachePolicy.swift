import Foundation

enum FeedCachePolicy {
    
    static func validate(_ timestamp: Date, against date: Date) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        let maxExpiredDays = 7
        if let maxRangeCached = calendar.date(byAdding: .day, value: maxExpiredDays, to: timestamp) {
            return date < maxRangeCached
        }
        
        return false
    }
}
