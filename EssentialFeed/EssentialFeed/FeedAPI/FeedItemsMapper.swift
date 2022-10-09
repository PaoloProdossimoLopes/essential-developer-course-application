import Foundation

struct FeedItemsMapper {
    
    private struct Root: Decodable {
        let items: [RemoteFeedImage]
    }
    
    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [RemoteFeedImage] {
        guard response.statusCode == 200 else {
            throw RemoteFeedLoader.Error.invalidData
        }
        
        let decoder = JSONDecoder()
        let rootDecoded = try decoder.decode(Root.self, from: data)
        let feedItemsMapped = rootDecoded.items
        return feedItemsMapped
    }
}
