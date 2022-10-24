import XCTest
import EssentialFeed

final class CodableFeedStoreTests: XCTestCase {
    
    func test_retrive_delieversEmptyOnEmptyCache() {
        let sut = CodableFeedStore()
        let exp = expectation(description: "wait for cache retrieval")
        sut.retrieve { result in
            switch result {
            case .empty:
                break
            default: XCTFail("Expected empty result, got \(result) instead")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
}

final class CodableFeedStore {
    func retrieve(completion: @escaping FeedStore.RetrieveCompletion) {
        completion(.empty)
    }
}
