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
    
    func test_init_doesNotMessageCache_uponSUTCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.recievedMessages, [])
    }
    
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        
        let items = uniqueItem().asList
        sut.save(items)
        
        XCTAssertEqual(store.recievedMessages, [.deleteCache])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = NSError(domain: "any-deletion-error", code: 0)
        
        let items = uniqueItem().asList
        sut.save(items)
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.recievedMessages, [.deleteCache])
    }
    
    func test_save_requestNewCacheInsertionWithTimestampOnSuccessfullDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        
        let items = uniqueItem().asList
        sut.save(items)
        store.completeDeletionSuccessfull()
        
        XCTAssertEqual(store.recievedMessages, [.deleteCache, .insert(items, timestamp)])
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
    
    enum RecievedMessages: Equatable {
        case deleteCache
        case insert([FeedItem], Date)
    }
    
    private(set) var recievedMessages = [RecievedMessages]()
    private var deletionsCompletion = [DeletionCompletion]()
    
    //MARK: - Methods
    func deleteCache(completion: @escaping DeletionCompletion) {
        deletionsCompletion.append(completion)
        recievedMessages.append(.deleteCache)
    }
    
    func insertCache(_ items: [FeedItem], timestamp: Date) {
        recievedMessages.append(.insert(items, timestamp))
    }
    
    //MARK: - Spies
    func completeDeletion(with error: Error?, at index: Int = 0) {
        deletionsCompletion[index](error)
    }
    
    func completeDeletionSuccessfull(at index: Int = 0) {
        deletionsCompletion[index](nil)
    }
}
