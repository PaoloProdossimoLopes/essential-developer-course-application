import XCTest
import EssentialFeed

final class CacheFeedUseCaseTest: XCTestCase {
    
    func test_init_doesNotMessageCache_uponSUTCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.recievedMessages, [])
    }
    
    func test_save_requestsCacheDeletion() {
        let (sut, store) = makeSUT()
        
        sut.save(uniqueItems().models) { _ in }
        
        XCTAssertEqual(store.recievedMessages, [.deleteCache])
    }
    
    func test_save_doesNotRequestCacheInsertionOnDeletionError() {
        let (sut, store) = makeSUT()
        let deletionError = makeAnyNSError()
        
        sut.save(uniqueItems().models) { _ in }
        store.completeDeletion(with: deletionError)
        
        XCTAssertEqual(store.recievedMessages, [.deleteCache])
    }
    
    func test_save_requestNewCacheInsertionWithTimestampOnSuccessfullDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(currentDate: { timestamp })
        
        let items = uniqueItems()
        sut.save(items.models) { _ in }
        store.completeDeletionSuccessfull()
        
        XCTAssertEqual(store.recievedMessages, [.deleteCache, .insert(items.local, timestamp)])
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
        
        var recievedResults = [LocalFeedLoader.SaveResult]()
        sut?.save(uniqueItems().models, completion: { recievedResults.append($0) })
        sut = nil
        store.completeDeletion(with: makeAnyNSError())
        
        XCTAssertTrue(recievedResults.isEmpty)
    }
    
    func test_save_doesNotDeleverInsertionErrorAfterSUTInstanceHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, currentDate: Date.init)
        
        var recievedResults = [Error?]()
        sut?.save(uniqueItems().models, completion: { recievedResults.append($0) })
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
        var recievedError: LocalFeedLoader.SaveResult?
        sut.save(uniqueItem().asList) { error in
            recievedError = error
            expect.fulfill()
        }
        
        action()
        
        wait(for: [expect], timeout: 1.0)
        
        XCTAssertEqual(recievedError as? NSError, expectedError, file: file, line: line)
    }
    
    func uniqueItem() -> FeedImage {
        .init(
            id: .init(), description: "any-description",
            location: "any-location", url: URL(string: "https://any-url.com")!
        )
    }
    
    func uniqueItems() -> (models: [FeedImage], local: [LocalFeedImage]) {
        let model = uniqueItem().asList
        let lcoal = model.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.image) }
        return (model, lcoal)
    }
}

extension FeedImage {
    var asList: [FeedImage] { [self] }
}
