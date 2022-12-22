import XCTest
import EssentialFeed

final class CoreDataFeedStoreTests: XCTestCase, FeedStoreSpecs {
    
    func test_retrieve_deliversEmptyOnEmptyCache() {
            let sut = makeSUT()
            
            assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
        }
        
    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()
        
        assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        
        assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()
        
        assertThatRetrieveHasNoSideEffectsOnNonEmptyCache(on: sut)
    }
    
   
    // - MARK: Helpers
     
     private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> FeedStore {
         let storeURL = URL(fileURLWithPath: "/dev/null")
         let sut = try! CoreDataFeedStore(storeURL: storeURL)
         checkMemoryLeak(sut, file: file, line: line)
         return sut
     }
}
