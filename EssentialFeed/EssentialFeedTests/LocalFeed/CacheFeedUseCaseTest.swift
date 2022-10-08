import XCTest
import EssentialFeed

final class LocalFeedLoader {
    let store: FeedStore
    let currentDate: (() -> Date)
    
    init(store: FeedStore, currentDate: @escaping (() -> Date)) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ items: [FeedItem]) {
        store.deleteCache { [unowned self] error in
            if error == nil {
                self.store.insertCache(items, timestamp: self.currentDate())
            }
        }
    }
}

final class CacheFeedUseCaseTest: XCTestCase {
    
    func test_init_doesNotDeleteCache_uponSUTCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }
    
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        
        let items = uniqueItem().asList
        sut.save(items)
        
        XCTAssertEqual(store.deleteCachedFeedCallCount, 1)
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = NSError(domain: "any-deletion-error", code: 0)
        
        let items = uniqueItem().asList
        sut.save(items)
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.insertCallCount, 0)
    }
    
    func test_save_requestNewCacheInsertionOnSuccessfullDeletion() {
        let (sut, store) = makeSUT()
        
        let items = uniqueItem().asList
        sut.save(items)
        store.completeDeletionSuccessfull()
        
        XCTAssertEqual(store.insertCallCount, 1)
    }
    
    func test_save_requestNewCacheInsertionWithTimestampOnSuccessfullDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        
        let items = uniqueItem().asList
        sut.save(items)
        store.completeDeletionSuccessfull()
        
        XCTAssertEqual(store.insertions.count, 1)
        XCTAssertEqual(store.insertions.first?.items, items)
        XCTAssertEqual(store.insertions.first?.timestamp, timestamp)
    }
}

private extension CacheFeedUseCaseTest {
    func makeSUT(
        currentDate: @escaping (() -> Date) = Date.init,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: LocalFeedLoader,
        store: FeedStore
    ) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        
        checkMemoryLeak(sut, file: file, line: line)
        checkMemoryLeak(store, file: file, line: line)
        
        return (sut, store)
    }
    
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
    typealias DeletionCompletion = ((Error?) -> Void)
    
    private(set) var deleteCachedFeedCallCount = 0
    private(set) var insertCallCount = 0
    private(set) var insertions = [(items: [FeedItem], timestamp: Date)]()
    
    private var deletionsCompletion = [DeletionCompletion]()
    
    func deleteCache(completion: @escaping DeletionCompletion) {
        deleteCachedFeedCallCount += 1
        deletionsCompletion.append(completion)
    }
    
    func insertCache(_ items: [FeedItem], timestamp: Date) {
        insertCallCount += 1
        insertions.append((items, timestamp))
    }
    
    func completeDeletion(with error: Error?, at index: Int = 0) {
        deletionsCompletion[index](error)
    }
    
    func completeDeletionSuccessfull(at index: Int = 0) {
        deletionsCompletion[index](nil)
    }
}
