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
        sut.load { result in
            switch result {
            case let .failure(error):
                recievedError = error
            default:
                XCTFail("Expected failure but got \(result) instead")
            }
            expect.fulfill()
        }
        
        store.retrieveCompleteion(with: retrieveError)
        wait(for: [expect], timeout: 1.0)
        
        XCTAssertEqual(recievedError as? NSError, retrieveError)
    }
    
    func test_load_deleversNoImagesONEmptyChache() {
        let (sut, store) = makeSUT()

        let expect = expectation(description: "waiting for load completion")
        var recievedImages: [FeedImage]?
        sut.load { result in
            switch result {
            case let .success(feedImages):
                recievedImages = feedImages
            default:
                XCTFail("Expected success but got \(result) instead")
            }
            expect.fulfill()
        }

        store.retrieveCompleteionWithEmptyCache()
        wait(for: [expect], timeout: 1.0)

        XCTAssertEqual(recievedImages, [])
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
