import XCTest

final class RemoteFeedLoader {
    
    let client: HTTPClient
    let url: URL
    
    init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }
    
    func load() {
        client.get(from: url)
    }
}

protocol HTTPClient {
    func get(from url: URL)
}

final class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let tuple = makeSUT()
        XCTAssertNil(tuple.client.requestURL)
    }
    
    func test_load_requestDateFromURL() {
        let (sut, client) = makeSUT()
        sut.load()
        XCTAssertNotNil(client.requestURL)
    }
    
    func test_load_requestDateFromURL_asExpected() {
        let url = URL(string: "https://www.any-mock-url.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load()
        XCTAssertEqual(client.requestURL, url)
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
    var requestURL: URL?
    
    func get(from url: URL) {
        requestURL = url
    }
}
