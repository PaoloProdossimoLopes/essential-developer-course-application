import XCTest
import EssentialFeed

final class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let tuple = makeSUT()
        XCTAssertTrue(tuple.client.requestURLs.isEmpty)
    }
    
    func test_load_requestDateFromURL() {
        let (sut, client) = makeSUT()
        sut.load { _ in }
        XCTAssertFalse(client.requestURLs.isEmpty)
    }
    
    func test_load_requestDateFromURL_asExpected() {
        let url = URL(string: "https://www.any-mock-url.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load { _ in }
        XCTAssertEqual(client.requestURLs, [url])
    }
    
    func test_loadTwice_shouldRequestDataFromURLTwiceToo() {
        let url = URL(string: "https://www.any-mock-url.com")!
        let (sut, client) = makeSUT(url: url)
        sut.load { _ in }
        sut.load { _ in }
        XCTAssertEqual(client.requestURLs, [url, url])
    }
    
    func test_load_delieversErrorWhenClientFails() {
        let (sut, client) = makeSUT()
        
        expect(sut, completeWith: .failure(.noConectivity)) {
            let clientError = makeError("test")
            client.complete(with: clientError)
        }
    }
    
    func test_load_deliversErrorsOn200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 404, 500].enumerated()
        samples.forEach { (index, statusCode) in
            
            expect(sut, completeWith: .failure(.invalidData)) {
                client.complete(with: statusCode, at: index)
            }
        }
    }
    
    func test_load_delieversErrorOn200HTTPReponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        
            expect(sut, completeWith: .failure(.invalidData), when: {
            let invalidJSON = Data("any-invalid-json".utf8)
            client.complete(with: 200, data: invalidJSON)
        })
    }
    
    func test_load_delieversNoItemOn200HTTPResponseWithEmptyList() {
        let (sut, client) = makeSUT()
        
        expect(sut, completeWith: .success([])) {
            let emptyListJSON = Data("{\"items\": []}".utf8)
            client.complete(with: 200, data: emptyListJSON)
        }
    }
    
    //MARK: - Helpers
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
    
    private func expect(
        _ sut: RemoteFeedLoader,
        completeWith result: RemoteFeedLoader.Result,
        when action: (() -> Void),
        file: StaticString = #filePath, line: UInt = #line
    ) {
        var results = [RemoteFeedLoader.Result]()
        sut.load { results.append($0) }
        
        action()
        
        XCTAssertEqual(results, [result], file: file, line: line)
    }
    
    func makeError(_ domain: String) -> NSError {
        NSError(domain: domain, code: .zero)
    }
}

final class HTTPClientSpy: HTTPClient {
    
    private(set) var messages: [(url: URL, completion: ((HTTPClientResult) -> Void))] = []
    var requestURLs: [URL] { messages.map(\.url) }
    
    func get(from url: URL, completion: @escaping ((HTTPClientResult) -> Void)) {
        messages.append((url, completion))
    }
    
    func complete(with error: Error, at index: Int = 0) {
        messages[index].completion(.failure(error))
    }
    
    func complete(with statusCode: Int, data: Data = Data(), at index: Int = 0) {
        let url = requestURLs[index]
        let response = HTTPURLResponse(
            url: url, statusCode: statusCode,
            httpVersion: nil, headerFields: nil
        )!
        messages[index].completion(.success(data, response))
    }
}
