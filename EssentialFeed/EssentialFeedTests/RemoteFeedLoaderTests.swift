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
                let validJSON = makeItemJSON([])
                client.complete(with: statusCode, data: validJSON, at: index)
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
            //let emptyListJSON = Data("{\"items\": []}".utf8)//Hard code method
            let emptyListJSON = makeItemJSON([])
            client.complete(with: 200, data: emptyListJSON)
        }
    }
    
    func test_load_deliversItemOn200HTTPResponseWitjJSONItems() {
        let (sut, client) = makeSUT()
        
        let item1 = makeItem(
            id: .init(), description: nil,
            location: nil, imageURL: URL(string: "https://a-url.com")!)
        
        let item2 = makeItem(
            id: .init(), description: "any-description",
            location: "any-localtion",
            imageURL: URL(string: "https://any-other-url.com")!)
        
        expect(sut, completeWith: .success([item1.model, item2.model])) {
            let json = makeItemJSON([item1.json, item2.json])
            client.complete(with: 200, data: json)
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
    
    private func makeItemJSON(_ items: [[String: Any]]) -> Data {
        let jsonItem = ["items": items]
        return try! JSONSerialization.data(withJSONObject: jsonItem)
    }
    
    private func makeItem(
        id: UUID, description: String? = nil,
        location: String? = nil, imageURL: URL
    ) -> (
        model: FeedItem, json: [String: Any]
    ) {
        let item = FeedItem(
            id: id, description: description,
            location: location, imageURL: imageURL)
        
        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": imageURL.absoluteString
        ].reduce(into: [String: Any](), { (accumulate, element) in
            if let value = element.value {
                accumulate[element.key] = value
            }
        })
        
        return (item, json)
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
    
    private(set) var messages: [
        (url: URL, completion: ((HTTPClientResult) -> Void))
    ] = []
    
    var requestURLs: [URL] { messages.map(\.url) }
    
    func get(from url: URL, completion: @escaping ((HTTPClientResult) -> Void)) {
        messages.append((url, completion))
    }
    
    func complete(with error: Error, at index: Int = 0) {
        messages[index].completion(.failure(error))
    }
    
    func complete(with statusCode: Int, data: Data, at index: Int = 0) {
        let url = requestURLs[index]
        let response = HTTPURLResponse(
            url: url, statusCode: statusCode,
            httpVersion: nil, headerFields: nil
        )!
        messages[index].completion(.success(data, response))
    }
}
