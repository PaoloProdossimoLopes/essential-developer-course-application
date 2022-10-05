import XCTest
import EssentialFeed

final class EssentialFeedEndToEndTests: XCTestCase {
    
    //MARK: This code are comment because API dont are alive so always fails, so comment this test to dont stuck me in project

    func test_endToEndTestServerGETFeedResult_matchesFixedTestAccountData() {
//        let loader = makeSUT()
//        let recievedResult = recievedResult(from: loader)
//
//        switch recievedResult {
//        case let .success(items)?:
//            XCTAssertEqual(items.count, 8, "Expect 8 itens in the test account feed")
//
//            let elementsEnuerated = items.enumerated()
//            elementsEnuerated.forEach { (index, item) in
//                XCTAssertEqual(item, expectedItem(at: index))
//            }
//
//        case let .failure(error)?:
//            XCTFail("Expected successful feed result, got \(error) instead")
//
//        default:
//            XCTFail("Expected successful feed result, got no result (nil)  instead")
//        }
    }
}

//MARK: - Helper
private extension EssentialFeedEndToEndTests {
    
    func makeSUT() -> RemoteFeedLoader {
        let url = URL(string: "https://essentialdeveloper.com/feed-case-study/test-api/fedd")!
        let client = URLSessionHTTPClient()
        let loader = RemoteFeedLoader(url: url, client: client)
        
        checkMemoryLeak(loader)
        checkMemoryLeak(client)
        
        return loader
    }
    
    func recievedResult(from loader: RemoteFeedLoader) -> FeedResult? {
        let expectation = expectation(description: "wait loader complete")
        var recievedResult: FeedResult?
        loader.load {
            recievedResult = $0
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 5.0)
        return recievedResult
    }
    
    func expectedItem(at index: Int) -> FeedItem {
        return .init(
            id: id(at: index), description: description(at: index),
            location: location(at: index), imageURL: imageURL(at: index)
        )
    }
    
    func id(at index: Int) -> UUID {
        return UUID(uuidString: [
            "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6",
            "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6",
            "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6",
            "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6",
            "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6",
            "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6",
            "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6",
            "73A7F70C-75DA-4C2E-B5A3-EED40DC53AA6"
        ][index])!
    }
    
    func description(at index: Int) -> String? {
        return [
            "Description 1",
            nil,
            "Description 3",
            nil,
            "Description 5",
            "Description 6",
            "Description 7",
            "Description 8",
        ][index]
    }
    
    func location(at index: Int) -> String? {
        return [
            "Location 1",
            "Location 2",
            nil,
            nil,
            "Location 5",
            "Location 6",
            "Location 7",
            "Location 8",
        ][index]
    }
    
    func imageURL(at index: Int) -> URL {
        let position = index + 1
        return URL(string: "https://url-\(position).com")!
    }
}
