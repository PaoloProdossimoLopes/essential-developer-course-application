import XCTest
import EssentialFeed

final class LoadFeedImageDataFromCacheUseCaseTests: XCTestCase {
 
    // MARK: - Helpers
      
      private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedImageDataLoader, store: FeedImageDataStoreSpy) {
          let store = FeedImageDataStoreSpy()
          let sut = LocalFeedImageDataLoader(store: store)
          checkMemoryLeak(store, file: file, line: line)
          checkMemoryLeak(sut, file: file, line: line)
          return (sut, store)
      }
      
      private func failed() -> Result<Data, Error> {
          return .failure(LocalFeedImageDataLoader.LoadError.failed)
      }
      
      private func notFound() -> Result<Data, Error> {
          return .failure(LocalFeedImageDataLoader.LoadError.notFound)
      }
      
      private func expect(_ sut: LocalFeedImageDataLoader, toCompleteWith expectedResult: Result<Data, Error>, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
          action()
          
          let receivedResult = Result { try sut.loadImageData(from: anyURL()) }

          switch (receivedResult, expectedResult) {
          case let (.success(receivedData), .success(expectedData)):
              XCTAssertEqual(receivedData, expectedData, file: file, line: line)
              
          case (.failure(let receivedError as LocalFeedImageDataLoader.LoadError),
                .failure(let expectedError as LocalFeedImageDataLoader.LoadError)):
              XCTAssertEqual(receivedError, expectedError, file: file, line: line)
              
          default:
              XCTFail("Expected result \(expectedResult), got \(receivedResult) instead", file: file, line: line)
          }
      }

}
