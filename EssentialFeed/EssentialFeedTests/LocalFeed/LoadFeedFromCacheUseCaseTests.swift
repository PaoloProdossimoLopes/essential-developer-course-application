import XCTest
import EssentialFeed

final class LoadFeedFromCacheUseCaseTests: XCTestCase {
    
    func test_init_doesNotMessageCache_uponSUTCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.recievedMessages, [])
    }
    
    func test_load_requestChacheRetreval() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        
        XCTAssertEqual(store.recievedMessages, [.retrieve])
    }
    
    func test_load_failsOnRetrievelError() {
        let (sut, store) = makeSUT()
        let retrieveError = makeAnyNSError()
        
        let expect = expectation(description: "waiting for load completion")
        var recievedError: Error?
        sut.load { error in
            recievedError = error
            expect.fulfill()
        }
        
        store.retrieveCompleteion(with: retrieveError)
        wait(for: [expect], timeout: 1.0)
        
        XCTAssertEqual(recievedError as? NSError, retrieveError)
    }
}

//MARK: - Heleper
private extension LoadFeedFromCacheUseCaseTests {
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
}
