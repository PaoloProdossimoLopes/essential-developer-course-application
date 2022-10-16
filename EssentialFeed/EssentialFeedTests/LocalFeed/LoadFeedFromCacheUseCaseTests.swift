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
    
    func test_load_deleversChaceImageOnLessThanSevenDaysOldCache() {
        let feed = uniqueItems()
        let currentDate = Date()
        let (sut, store) = makeSUT(currentDate: { currentDate })
        let lessThanSevenDaysOldTimestamp = currentDate.adding(days: -7).adding(seconds: 1)
        expect(sut, loadCompletesWithTo: .success(feed.models), when: {
            store.completeRetrival(with: feed.local, timestamp: lessThanSevenDaysOldTimestamp)
        })
    }
    
    func test_load_deleversNoImagesOnSevenDaysOldCache() {
        let feed = uniqueItems()
        let currentDate = Date()
        let (sut, store) = makeSUT(currentDate: { currentDate })
        let lessThanSevenDaysOldTimestamp = currentDate.adding(days: -7)
        expect(sut, loadCompletesWithTo: .success([]), when: {
            store.completeRetrival(with: feed.local, timestamp: lessThanSevenDaysOldTimestamp)
        })
    }
    
    func test_load_delieversNoImagesOnMoreThanSevenDaysOldCache() {
        let feed = uniqueItems()
        let currentDate = Date()
        let lessThanSevenDaysOldTimestamp = currentDate.adding(days: -7).adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { currentDate })
        expect(sut, loadCompletesWithTo: .success([]), when: {
            store.completeRetrival(with: feed.local, timestamp: lessThanSevenDaysOldTimestamp)
        })
    }
    
    func test_load_hasNoSideEffectCacheOnRetrivelError() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        store.retrieveCompleteion(with: makeAnyNSError())
        
        XCTAssertEqual(store.recievedMessages, [.retrieve])
    }
    
    func test_load_doesNotDeletionCacheOnEmptyCache() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        store.retrieveCompleteionWithEmptyCache()
        
        XCTAssertEqual(store.recievedMessages, [.retrieve])
    }
    
    func test_load_doesNotDeletionCacheOnLessThanSevenDaysOld() {
       let feed = uniqueItems()
        let fixedDate = Date()
        let timestamp = fixedDate.adding(days: -7).adding(seconds: 1)
        let (sut, store) = makeSUT(currentDate: { fixedDate })
        
        sut.load { _ in }
        store.completeRetrival(with: feed.local, timestamp: timestamp)
        
        XCTAssertEqual(store.recievedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectCacheOnSevenDaysOldCache() {
       let feed = uniqueItems()
        let fixedDate = Date()
        let timestamp = fixedDate.adding(days: -7)
        let (sut, store) = makeSUT(currentDate: { fixedDate })
        
        sut.load { _ in }
        store.completeRetrival(with: feed.local, timestamp: timestamp)
        
        XCTAssertEqual(store.recievedMessages, [.retrieve])
    }
    
    func test_load_hasNoSideEffectCacheOnMoteThanSevenDaysOldCache() {
       let feed = uniqueItems()
        let fixedDate = Date()
        let timestamp = fixedDate.adding(days: -7).adding(seconds: -1)
        let (sut, store) = makeSUT(currentDate: { fixedDate })
        
        sut.load { _ in }
        store.completeRetrival(with: feed.local, timestamp: timestamp)
        
        XCTAssertEqual(store.recievedMessages, [.retrieve])
    }
    
    func test_load_doesNotDeleverResultAfterSUTINstacenHasBeenDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = .init(store: store, currentDate: Date.init)
        
        var recievedResult = [LocalFeedLoader.LoadResult]()
        sut?.load { recievedResult.append($0) }
        
        sut = nil
        store.retrieveCompleteionWithEmptyCache()
        
        XCTAssertTrue(recievedResult.isEmpty)
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

extension Date {
    func adding(days: Int) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.date(byAdding: .day, value: days, to: self)!
    }
    
    func adding(seconds: Int) -> Date {
        let calendar = Calendar(identifier: .gregorian)
        return calendar.date(byAdding: .second, value: seconds, to: self)!
    }
}
