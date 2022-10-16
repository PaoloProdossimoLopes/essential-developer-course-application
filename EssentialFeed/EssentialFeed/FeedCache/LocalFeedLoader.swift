import Foundation

public final class LocalFeedLoader {
    
    let store: FeedStore
    let currentDate: (() -> Date)
    
    public typealias SaveResult = Swift.Error?
    public typealias LoadResult = FeedResult?
    
    public init(store: FeedStore, currentDate: @escaping (() -> Date)) {
        self.store = store
        self.currentDate = currentDate
    }
}
 
extension LocalFeedLoader {
    public func load(completion: @escaping ((LoadResult) -> Void)) {
        store.retrieve { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case let .failure(error):
                completion(.failure(error))
                
            case let .found(feed, timestamp) where self.validate(timestamp):
                completion(.success(feed.toModel()))
                
            case .found, .empty:
                completion(.success([]))
            }
        }
    }
}

extension LocalFeedLoader {
    
    public func save(_ items: [FeedImage], completion: @escaping ((SaveResult) -> Void)) {
        store.deleteCache { [weak self] error in
            guard let self = self else { return }
            self.onDeleteCache(items: items, recieved: error, with: completion)
        }
    }
    
}

extension LocalFeedLoader {
    
    public func validate() {
        store.retrieve { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .failure:
                self.store.deleteCache { _ in }
                
            case let .found(_, timestamp) where !self.validate(timestamp):
                self.store.deleteCache { _ in }
                
            case .empty, .found: break
            }
        }
        
    }
}

//MARK: - Helpers
private extension LocalFeedLoader {
    
    func validate(_ timestamp: Date) -> Bool {
        let calendar = Calendar(identifier: .gregorian)
        if let maxRangeCached = calendar.date(byAdding: .day, value: 7, to: timestamp) {
            return currentDate() < maxRangeCached
        }
        
        return false
    }
    
    func onDeleteCache(
        items: [FeedImage],
        recieved error: Error?,
        with completion: @escaping ((SaveResult) -> Void)) {
            
        if let deletionError = error {
            completion(deletionError)
        } else {
            self.insertCache(items, with: completion)
        }
    }
    
    func insertCache(_ items: [FeedImage], with completion: @escaping ((SaveResult) -> Void)) {
        store.insertCache(items.toLocal(), timestamp: currentDate()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}

private extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        map { LocalFeedImage(
            id: $0.id, description: $0.description,
            location: $0.location, url: $0.image
        )}
    }
}

private extension Array where Element == LocalFeedImage {
    func toModel() -> [FeedImage] {
        map { FeedImage(
            id: $0.id, description: $0.description,
            location: $0.location, url: $0.url
        )}
    }
}
