import XCTest
import EssentialFeed

final class CoreDataFeedStoreTests: XCTestCase, FeedStoreSpecs {
   
    // - MARK: Helpers
     
     private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> FeedStore {
         let storeURL = URL(fileURLWithPath: "/dev/null")
         let sut = try! CoreDataFeedStore(storeURL: storeURL)
         checkMemoryLeak(sut, file: file, line: line)
         return sut
     }
}
