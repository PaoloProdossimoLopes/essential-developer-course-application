import XCTest
import EssentialFeed

final class LocalFeedLoader {
    let store: FeedStore
    
    init(store: FeedStore) {
        self.store = store
    }
    
    func save(_ items: [FeedItem]) {
        store.deleteCache()
    }
}

final class CacheFeedUseCaseTest: XCTestCase {
    
    func test_init_doesNotDeleteCache_uponSUTCreation() {
        let store = FeedStore()
        _ = LocalFeedLoader(store: store)
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }
    
    func test_save_requestsCacheDeletion() {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store)
        
        let items = uniqueItem().asList
        sut.save(items)
        
        XCTAssertEqual(store.deleteCachedFeedCallCount, 1)
    }
}

private extension CacheFeedUseCaseTest {
    func uniqueItem() -> FeedItem {
        .init(
            id: .init(), description: "any-description",
            location: "any-location", imageURL: URL(string: "https://any-url.com")!
        )
    }
}

extension FeedItem {
    var asList: [FeedItem] {
        [self]
    }
}

final class FeedStore {
    private(set) var deleteCachedFeedCallCount = 0
    
    func deleteCache() {
        deleteCachedFeedCallCount += 1
    }
}
