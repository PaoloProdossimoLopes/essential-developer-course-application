import XCTest

final class LocalFeedLoader {
    let store: FeedStore
    
    init(store: FeedStore) {
        self.store = store
    }
}

final class CacheFeedUseCaseTest: XCTestCase {
    
    func test_init_doesNotDeleteCache_uponSUTCreation() {
        let store = FeedStore()
        _ = LocalFeedLoader(store: store)
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }
}

final class FeedStore {
    private(set) var deleteCachedFeedCallCount = 0
}
