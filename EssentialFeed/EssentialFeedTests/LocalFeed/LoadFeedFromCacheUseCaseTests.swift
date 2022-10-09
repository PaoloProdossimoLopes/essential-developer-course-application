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
        
        expect(sut, loadCompletesWithTo: .failure(retrieveError), when: {
            store.retrieveCompleteion(with: retrieveError)
        })    
    }
    
    func test_load_deleversNoImagesONEmptyChache() {
        let (sut, store) = makeSUT()
        expect(sut, loadCompletesWithTo: .success([]), when: {
            store.retrieveCompleteionWithEmptyCache()
        })
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
    
    func expect(_ sut: LocalFeedLoader, loadCompletesWithTo expectedResult: LocalFeedLoader.LoadResult, when action: (() -> Void), file: StaticString = #filePath, line: UInt = #line) {
        let expect = expectation(description: "waiting for load completion")
        
        sut.load { recievedResult in
            switch (recievedResult, expectedResult) {
            case let (.success(recievedImages), .success(expectedImages)):
                XCTAssertEqual(recievedImages, expectedImages, file: file, line: line)
                
            case let (.failure(recievedError), .failure(expectedError)):
                XCTAssertEqual(recievedError as NSError?, expectedError as NSError?, file: file, line: line)
            default:
                XCTFail("Expectec \(expectedResult) but got \(recievedResult) intead", file: file, line: line)
            }
            expect.fulfill()
        }

        action()
        wait(for: [expect], timeout: 1.0)
    }
}
