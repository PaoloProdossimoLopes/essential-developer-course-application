import XCTest
import EssentialFeed

final class LocalFeedLoader {
    let store: FeedStore
    let currentDate: (() -> Date)
    
    init(store: FeedStore, currentDate: @escaping (() -> Date)) {
        self.store = store
        self.currentDate = currentDate
    }
    
    func save(_ items: [FeedItem], completion: @escaping ((Error?) -> Void)) {
        store.deleteCache { [unowned self] error in
            if error == nil {
                self.store.insertCache(items, timestamp: self.currentDate()) { error in
                    completion(error)
                }
            } else {
                completion(error)
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
        sut.save(items) { _ in }
        
        XCTAssertEqual(store.recievedMessages, [.deleteCache])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = NSError(domain: "any-deletion-error", code: 0)
        
        let items = uniqueItem().asList
        sut.save(items) { _ in }
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.recievedMessages, [.deleteCache])
    }
    
    func test_save_requestNewCacheInsertionWithTimestampOnSuccessfullDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        
        let items = uniqueItem().asList
        sut.save(items) { _ in }
        store.completeDeletionSuccessfull()
        
        XCTAssertEqual(store.recievedMessages, [.deleteCache, .insert(items, timestamp)])
    }
    
    func test_save_failsOnDeletionError() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let items = uniqueItem().asList
        let deletionError = NSError(domain: "any-deletion-error", code: 0)
        
        let expect = expectation(description: "waiting for save completion")
        var recievedError: Error?
        sut.save(items) { error in
            recievedError = error
            expect.fulfill()
        }
        store.completeDeletion(with: deletionError)
        wait(for: [expect], timeout: 1.0)
        
        XCTAssertEqual(recievedError as? NSError, deletionError)
    }
    
    func test_save_failsOnInsertionError() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let items = uniqueItem().asList
        let insertionError = NSError(domain: "any-deletion-error", code: 0)
        
        let expect = expectation(description: "waiting for save completion")
        var recievedError: Error?
        sut.save(items) { error in
            recievedError = error
            expect.fulfill()
        }
        store.completeDeletionSuccessfull()
        store.completeInsertion(with: insertionError)
        wait(for: [expect], timeout: 1.0)
        
        XCTAssertEqual(recievedError as? NSError, insertionError)
    }
    
    func test_save_succeedsOnSuccessfullInsertion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let items = uniqueItem().asList
        
        let expect = expectation(description: "waiting for save completion")
        var recievedError: Error?
        sut.save(items) { error in
            recievedError = error
            expect.fulfill()
        }
        store.completeDeletionSuccessfull()
        store.completeInsertionSuccessfull()
        wait(for: [expect], timeout: 1.0)
        
        XCTAssertNil(recievedError)
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
    var asList: [FeedItem] { [self] }
}

final class FeedStore {
    typealias DeletionCompletion = ((Error?) -> Void)
    typealias InsertionCompletion = ((Error?) -> Void)
    
    enum RecievedMessages: Equatable {
        case deleteCache
        case insert([FeedItem], Date)
    }
    
    private(set) var recievedMessages = [RecievedMessages]()
    private var deletionsCompletion = [DeletionCompletion]()
    private var insertionCompletions = [InsertionCompletion]()
    
    //MARK: - Methods
    func deleteCache(completion: @escaping DeletionCompletion) {
        deletionsCompletion.append(completion)
        recievedMessages.append(.deleteCache)
    }
    
    func insertCache(_ items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletion) {
        recievedMessages.append(.insert(items, timestamp))
        insertionCompletions.append(completion)
    }
    
    //MARK: - Spies
    func completeDeletion(with error: Error?, at index: Int = 0) {
        deletionsCompletion[index](error)
    }
    
    func completeDeletionSuccessfull(at index: Int = 0) {
        deletionsCompletion[index](nil)
    }
    
    func completeInsertion(with error: Error?, at index: Int = 0) {
        insertionCompletions[index](error)
    }
    
    func completeInsertionSuccessfull(at index: Int = 0) {
        insertionCompletions[index](nil)
    }
}
