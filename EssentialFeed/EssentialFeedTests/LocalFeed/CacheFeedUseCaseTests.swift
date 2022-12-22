import XCTest
import EssentialFeed

final class CacheFeedUseCaseTests: XCTestCase {
    
    
    
    // MARK: - Helpers
    
    private func makeSUT(currentDate: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (sut: LocalFeedLoader, store: FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, currentDate: currentDate)
        checkMemoryLeak(store, file: file, line: line)
        checkMemoryLeak(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func expect(_ sut: LocalFeedLoader, toCompleteWithError expectedError: NSError?, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        action()
        
        do {
            try sut.save(uniqueImageFeed().models)
        } catch {
            XCTAssertEqual(error as NSError?, expectedError, file: file, line: line)
        }
    }
}
