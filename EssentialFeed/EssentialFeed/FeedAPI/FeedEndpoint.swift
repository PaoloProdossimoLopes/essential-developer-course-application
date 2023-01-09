import Foundation

public enum FeedEndpoint {
    case get(after: FeedImage? = nil)
    
    public func url(baseURL: URL) -> URL {
        switch self {
        case let .get(image):
            var components = URLComponents()
            components.scheme = baseURL.scheme
            components.host = baseURL.host
            components.path = baseURL.path + Constant.FINAL_FEED_PATH
            components.queryItems = [
                URLQueryItem(name: Constant.LIMIT_QUERY, value: Constant.QUANTITY_OF_ITEMS_QUERED),
                image.map { URLQueryItem(name: Constant.ID_KEY_QUERY, value: $0.id.uuidString) },
            ].compactMap { $0 }
            return components.url!
        }
    }
    
    private enum Constant {
        static let FINAL_FEED_PATH = "/v1/feed"
        static let LIMIT_QUERY = "limit"
        static let QUANTITY_OF_ITEMS_QUERED = "10"
        static let ID_KEY_QUERY = "after_id"
    }
}
