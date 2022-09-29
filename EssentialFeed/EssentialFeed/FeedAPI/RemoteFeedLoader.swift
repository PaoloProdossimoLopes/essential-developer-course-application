public final class RemoteFeedLoader {
    
    private let client: HTTPClient
    private let url: URL
    
    public enum Error: Swift.Error {
        case noConectivity
        case invalidData
    }
    
    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping ((Result) -> Void)) {
        client.get(from: url) { result in
            switch result {
            case let .success(data, response):
                completion(self.map(data, response))
            case .failure:
                completion(.failure(.noConectivity))
            }
        }
    }
    
    private func map(_ data: Data, _ response: HTTPURLResponse) -> Result {
        if let feedItems = try? FeedItemsMapper.map(data, response) {
            return .success(feedItems)
        } else {
            return .failure(.invalidData)
        }
    }
}
