import XCTest
import EssentialFeed

final class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let tuple = makeSUT()
        XCTAssertTrue(tuple.client.requestURLs.isEmpty)
    }
    
    func test_load_requestDateFromURL() {
        let (sut, client) = makeSUT()
        sut.load()
        XCTAssertFalse(client.requestURLs.isEmpty)
    }
    
    func test_load_requestDateFromURL_asExpected() {
        let url = URL(string: "https://www.any-mock-url.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load()
        XCTAssertEqual(client.requestURLs, [url])
    }
    
    func test_loadTwice_shouldRequestDataFromURLTwiceToo() {
        let url = URL(string: "https://www.any-mock-url.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load()
        sut.load()
        XCTAssertEqual(client.requestURLs, [url, url])
    }
    
    private func makeSUT(
        url: URL = URL(string: "https://www.any-mock-url.com")!
    ) -> (
        sut: RemoteFeedLoader,
        client: HTTPClientSpy
    ) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (sut, client)
    }
}

final class HTTPClientSpy: HTTPClient {
    private(set) var requestURLs: [URL] = []
    
    func get(from url: URL) {
        requestURLs.append(url)
    }
}
