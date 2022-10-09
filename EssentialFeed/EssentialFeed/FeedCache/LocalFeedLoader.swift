import Foundation

public final class LocalFeedLoader {
    
    let store: FeedStore
    let currentDate: (() -> Date)
    
    public typealias SaveResult = Swift.Error?
    
    public init(store: FeedStore, currentDate: @escaping (() -> Date)) {
        self.store = store
        self.currentDate = currentDate
    }
    
    public func save(_ items: [FeedImage], completion: @escaping ((SaveResult) -> Void)) {
        store.deleteCache { [weak self] error in
            guard let self = self else { return }
            self.onDeleteCache(items: items, recieved: error, with: completion)
        }
    }
}

//MARK: - Helpers
private extension LocalFeedLoader {
    
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

extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        map { LocalFeedImage(
            id: $0.id, description: $0.description,
            location: $0.location, url: $0.image
        )}
    }
}
