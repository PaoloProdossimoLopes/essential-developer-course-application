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
        store.deleteCache { [weak self] error in
            guard let self = self else { return }
            if error == nil {
                self.store.insertCache(items, timestamp: self.currentDate()) { [weak self] error in
                    guard self != nil else { return }
                    completion(error)
                }
            } else {
                completion(error)
            }
        }
    }
}

protocol FeedStore {
    typealias DeletionCompletion = ((Error?) -> Void)
    typealias InsertionCompletion = ((Error?) -> Void)
    
    func deleteCache(completion: @escaping DeletionCompletion)
    func insertCache(_ items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletion)
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
        let deletionError = makeAnyNSError()
        
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
        let deletionError = makeAnyNSError()
        expect(sut, toCompleteWithError: deletionError, when: {
            store.completeDeletion(with: deletionError)
        })
    }
    
    func test_save_failsOnInsertionError() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let insertionError = makeAnyNSError()
        expect(sut, toCompleteWithError: insertionError, when: {
            store.completeDeletionSuccessfull()
            store.completeInsertion(with: insertionError)
        })
    }
    
    func test_save_succeedsOnSuccessfullInsertion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        let insertionError = makeAnyNSError()
        expect(sut, toCompleteWithError: insertionError, when: {
            store.completeDeletionSuccessfull()
            store.completeInsertion(with: insertionError)
        })
    }
    
    func test_save_doesNotDeleverDeletionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var recievedResults = [Error?]()
        sut?.save([uniqueItem()], completion: { recievedResults.append($0) })
        sut = nil
        store.completeDeletion(with: makeAnyNSError())
        
        XCTAssertTrue(recievedResults.isEmpty)
    }
    
    func test_save_doesNotDeleverInsertionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var recievedResults = [Error?]()
        sut?.save([uniqueItem()], completion: { recievedResults.append($0) })
        store.completeDeletionSuccessfull()
        sut = nil
        store.completeInsertion(with: makeAnyNSError())
        
        XCTAssertTrue(recievedResults.isEmpty)
    }
}

private extension CacheFeedUseCaseTest {
    func makeSUT(
        currentDate: @escaping (() -> Date) = Date.init,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (
        sut: LocalFeedLoader,
        store: FeedStoreSpy
    ) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        
        checkMemoryLeak(sut, file: file, line: line)
        checkMemoryLeak(store, file: file, line: line)
        
        return (sut, store)
    }
    
    func expect(
        _ sut: LocalFeedLoader,
        toCompleteWithError expectedError: NSError?,
        when action: (() -> Void),
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let expect = expectation(description: "waiting for save completion")
        var recievedError: Error?
        sut.save(uniqueItem().asList) { error in
            recievedError = error
            expect.fulfill()
        }
        
        action()
        
        wait(for: [expect], timeout: 1.0)
        
        XCTAssertEqual(recievedError as? NSError, expectedError, file: file, line: line)
    }
    
    func uniqueItem() -> FeedItem {
        .init(
            id: .init(), description: "any-description",
            location: "any-location", imageURL: URL(string: "https://any-url.com")!
        )
    }
    
    final class FeedStoreSpy: FeedStore {
        
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
}

extension FeedItem {
    var asList: [FeedItem] { [self] }
}
