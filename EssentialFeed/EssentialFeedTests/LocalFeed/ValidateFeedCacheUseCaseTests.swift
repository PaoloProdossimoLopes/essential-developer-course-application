import XCTest
import EssentialFeed

final class ValidateFeedCacheUseCaseTests: XCTestCase {
    
    func test_init_doesNotMessageCache_uponSUTCreation() {
        let (_, store) = makeSUT()
        XCTAssertEqual(store.recievedMessages, [])
    }
    
    func test_validate_deletionCacheOnRetrivelError() {
        let (sut, store) = makeSUT()
        
        sut.validate()
        store.retrieveCompleteion(with: makeAnyNSError())
        
        XCTAssertEqual(store.recievedMessages, [.retrieve, .deleteCache])
    }
    
    func test_validate_doesNotDeletionCacheOnExpirationDateCache() {
       let feed = uniqueItems()
        let fixedDate = Date()
        let timestamp = fixedDate.minusExpirationDate()
        let (sut, store) = makeSUT(currentDate: { fixedDate })
        
        sut.validate()
        store.completeRetrival(with: feed.local, timestamp: timestamp)
        
        XCTAssertEqual(store.recievedMessages, [.retrieve, .deleteCache])
    }
    
    func test_validate_doesNotDeletionCacheOnMoreThanExperationDateCache() {
       let feed = uniqueItems()
        let fixedDate = Date()
        let timestamp = fixedDate.minusExpirationDate().adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedDate })
        
        sut.validate()
        store.completeRetrival(with: feed.local, timestamp: timestamp)
        
        XCTAssertEqual(store.recievedMessages, [.retrieve, .deleteCache])
    }
    
    func test_validate_doesNotDeleverResultAfterSUTINstacenHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = .init(store: store, currentDate: Date.init)
        
        sut?.validate()
        
        sut = nil
        store.retrieveCompleteionWithEmptyCache()
        
        XCTAssertEqual(store.recievedMessages, [.retrieve])
    }
}

//MARK: - Helpers
private extension ValidateFeedCacheUseCaseTests {
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
