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
        
        expect(sut, completeWith: .failure(RemoteFeedLoader.Error.noConectivity)) {
            let clientError = makeError("test")
            client.complete(with: clientError)
        }
    }
    
    func test_load_deliversErrorsOn200HTTPResponse() {
        let (sut, client) = makeSUT()
        
        let samples = [199, 201, 300, 400, 404, 500].enumerated()
        samples.forEach { (index, statusCode) in
            
            expect(sut, completeWith: .failure(RemoteFeedLoader.Error.invalidData)) {
                let validJSON = makeItemJSON([])
                client.complete(with: statusCode, data: validJSON, at: index)
            }
        }
    }
    
    func test_load_delieversErrorOn200HTTPReponseWithInvalidJSON() {
        let (sut, client) = makeSUT()
        
            expect(sut, completeWith: .failure(RemoteFeedLoader.Error.invalidData), when: {
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
            location: nil, image: URL(string: "https://a-url.com")!)
        
        let item2 = makeItem(
            id: .init(), description: "any-description",
            location: "any-localtion",
            image: URL(string: "https://any-other-url.com")!)
        
        expect(sut, completeWith: .success([item1.model, item2.model])) {
            let json = makeItemJSON([item1.json, item2.json])
            client.complete(with: 200, data: json)
        }
    }
    
    func test_load_doesNotDelieverResultAfterSUTInstanceHasBeenDealocatted() {
        let url = URL(string: "http://any-url.com")!
        let client = HTTPClientSpy()
        var sut: RemoteFeedLoader? = .init(url: url, client: client)
        
        var resultCaptured = [RemoteFeedLoader.Result]()
        sut?.load { resultCaptured.append($0) }
        
        sut = nil
        client.complete(with: 200, data: makeItemJSON([]))
        
        XCTAssertTrue(resultCaptured.isEmpty)
    }
    
    //MARK: - Helpers
    private func makeSUT(
        url: URL = URL(string: "https://www.any-mock-url.com")!,
        file: StaticString = #filePath, line: UInt = #line
    ) -> (
        sut: RemoteFeedLoader,
        client: HTTPClientSpy
    ) {
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        
        checkMemoryLeak(sut, file: file, line: line)
        checkMemoryLeak(client, file: file, line: line)
        
        return (sut, client)
    }
    
    private func makeItemJSON(_ items: [[String: Any]]) -> Data {
        let jsonItem = ["items": items]
        return try! JSONSerialization.data(withJSONObject: jsonItem)
    }
    
    private func makeItem(
        id: UUID, description: String? = nil,
        location: String? = nil, image: URL
    ) -> (
        model: FeedImage, json: [String: Any]
    ) {
        let item = FeedImage(
            id: id, description: description,
            location: location, url: image)
        
        let json = [
            "id": id.uuidString,
            "description": description,
            "location": location,
            "image": image.absoluteString
        ].reduce(into: [String: Any](), { (accumulate, element) in
            if let value = element.value {
                accumulate[element.key] = value
            }
        })
        
        return (item, json)
    }
    
    private func expect(
        _ sut: RemoteFeedLoader,
        completeWith expectedResult: RemoteFeedLoader.Result,
        when action: (() -> Void),
        file: StaticString = #filePath, line: UInt = #line
    ) {
        
        let expect = expectation(description: "waiting")
        sut.load { recievedResult in
            switch (recievedResult, expectedResult) {
            case let (.success(recievedValue), .success(expectedValue)):
                XCTAssertEqual(recievedValue, expectedValue, file: file, line: line)
                
            case let (.failure(recievedValue as RemoteFeedLoader.Error), .failure(expectedValue as RemoteFeedLoader.Error)):
                XCTAssertEqual(recievedValue, expectedValue, file: file, line: line)
                
            default:
                XCTFail("Expected Result \(expectedResult) but got \(recievedResult) instead", file: file, line: line)
            }
            
            expect.fulfill()
        }
        
        action()
        wait(for: [expect], timeout: 1.0)
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
    
    func complete(with error: Error, at index: Int = .zero) {
        messages[index].completion(.failure(error))
    }
    
    func complete(with statusCode: Int, data: Data, at index: Int = .zero) {
        let url = requestURLs[index]
        let response = HTTPURLResponse(
            url: url, statusCode: statusCode,
            httpVersion: nil, headerFields: nil
        )!
        messages[index].completion(.success(data, response))
    }
}
