import Foundation

struct FeedItemsMapper {
    
    private struct Root: Decodable {
        let items: [RemoteFeedItem]
    }
    
    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        guard response.statusCode == 200 else {
            throw RemoteFeedLoader.Error.invalidData
        }
        
        let decoder = JSONDecoder()
        let rootDecoded = try decoder.decode(Root.self, from: data)
        let feedItemsMapped = rootDecoded.items
        return feedItemsMapped
    }
}

struct RemoteFeedItem: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: URL
}
