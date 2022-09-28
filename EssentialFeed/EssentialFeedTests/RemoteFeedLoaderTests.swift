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
    
    func test_load_delieversErrorWhenClientFails() {
        let (sut, client) = makeSUT()
        
        var errors = [RemoteFeedLoader.Error]()
        sut.load { errors.append($0) }
        
        let clientError = makeError("test")
        client.complete(with: clientError)
        
        XCTAssertEqual(errors, [.noConectivity])
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
    
    func makeError(_ domain: String) -> NSError {
        NSError(domain: domain, code: 0)
    }
}

final class HTTPClientSpy: HTTPClient {
    
    private(set) var requestURLs: [URL] = []
    private(set) var completions: [((Error) -> Void)] = []
    
    func get(from url: URL, completion: @escaping ((Error) -> Void) = { _ in }) {
        completions.append(completion)
        requestURLs.append(url)
    }
    
    func complete(with error: Error, at index: Int = 0) {
        completions[index](error)
    }
}
