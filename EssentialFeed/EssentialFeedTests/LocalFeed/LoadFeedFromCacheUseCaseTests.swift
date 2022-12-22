import XCTest
import EssentialFeed

final class LoadFeedFromCacheUseCaseTests: XCTestCase {
    // MARK: - Helpers
       
       private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
           let store = FeedStoreSpy()
           let sut = LocalFeedLoader(store: store, currentDate: currentDate)
           checkMemoryLeak(store, file: file, line: line)
           checkMemoryLeak(sut, file: file, line: line)
           return (sut, store)
       }
       
       private func expect(_ sut: LocalFeedLoader, toCompleteWith expectedResult: Result<[FeedImage], Error>, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
           action()

           let receivedResult = Result { try sut.load() }
           
           switch (receivedResult, expectedResult) {
           case let (.success(receivedImages), .success(expectedImages)):
               XCTAssertEqual(receivedImages, expectedImages, file: file, line: line)
               
           case let (.failure(receivedError as NSError), .failure(expectedError as NSError)):
               XCTAssertEqual(receivedError, expectedError, file: file, line: line)
               
           default:
               XCTFail("Expected result \(expectedResult), got \(receivedResult) instead", file: file, line: line)
           }
       }
       
}
