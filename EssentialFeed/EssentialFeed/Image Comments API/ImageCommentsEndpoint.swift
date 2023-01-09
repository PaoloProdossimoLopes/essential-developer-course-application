import Foundation

public enum ImageCommentsEndpoint {
    case get(UUID)
    
    public func url(baseURL: URL) -> URL {
        switch self {
        case let .get(id):
            return baseURL.appendingPathComponent(String(format: urlFormat, id.uuidString))
        }
    }
    
    private var urlFormat: String { "/v1/image/%@/comments" }
}
