import Foundation

public final class RemoteFeedLoader: IFeedLoader {
    
    private let client: HTTPClient
    private let url: URL
    
    public enum Error: Swift.Error {
        case noConectivity
        case invalidData
    }
    
    public typealias Result = FeedResult
    
    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    public func load(completion: @escaping ((Result) -> Void)) {
        client.get(from: url) { [weak self] result in
            guard let self = self else { return }
            self.onLoadHandler(result: result, completion: completion)
        }
    }
    
    private func onLoadHandler(result: HTTPClientResult, completion: ((Result) -> Void)) {
        switch result {
        case let .success(data, response):
            completion(map(data, response))
            break
        case .failure:
            completion(.failure(RemoteFeedLoader.Error.noConectivity))
            break
        }
    }
    
    private func map(_ data: Data, _ response: HTTPURLResponse) -> Result {
        guard let feedItems = try? FeedItemsMapper.map(data, response) else {
            return .failure(RemoteFeedLoader.Error.invalidData)
        }
        
        return .success(feedItems)
    }
}

