import XCTest
import EssentialFeed

final class URLSessionHTTPClient {
    private let session: URLSession
    
    
    struct UnexpectedRepresentationError: Error { }
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func get(from url: URL, completion: @escaping ((HTTPClientResult) -> Void)) {
        session.dataTask(with: url) { (_, _, error) in
            if let error {
                completion(.failure(error))
            } else {
                completion(.failure(UnexpectedRepresentationError()))
            }
        }.resume()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        URLProtocolStub.startInterceptingRequests()
    }
    
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.stopInterceptingRequests()
    }
    
    func test_getFromURL_performsGETRequestWithURL() {
        let url = makeAnyURL()
        let expect = expectation(description: "wait to complete")
        URLProtocolStub.observeRequest { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            expect.fulfill()
        }
        
        makeSUT().get(from: url) { _ in }
        
        wait(for: [expect], timeout: 1.0)
    }
    
    func test_getFromURLMethod_passURL_failsOnRequestError() {
        let error = makeAnyNSError()
        
        let resultFail = resultFailure(error: error) as NSError?
        
        XCTAssertEqual(resultFail?.domain, error.domain)
        XCTAssertEqual(resultFail?.code, error.code)
    }
    
    func test_getFromURLMethod_passURL_failsOnAllNillValues() {
        let nonHTTPURLResponse = URLResponse(url: makeAnyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        let anyHTTPURLResponse = HTTPURLResponse(url: makeAnyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)
        let anyData = Data("any_data".utf8)
        
        XCTAssertNotNil(resultFailure())
        XCTAssertNotNil(resultFailure(urlRequest: nonHTTPURLResponse))
        XCTAssertNotNil(resultFailure(urlRequest: anyHTTPURLResponse))
        XCTAssertNotNil(resultFailure(data: anyData))
        XCTAssertNotNil(resultFailure(data: anyData, error: makeAnyNSError()))
        XCTAssertNotNil(resultFailure(urlRequest: nonHTTPURLResponse, error: makeAnyNSError()))
        XCTAssertNotNil(resultFailure(urlRequest: anyHTTPURLResponse, error: makeAnyNSError()))
        XCTAssertNotNil(resultFailure(data: anyData, urlRequest: nonHTTPURLResponse, error: makeAnyNSError()))
        XCTAssertNotNil(resultFailure(data: anyData, urlRequest: anyHTTPURLResponse, error: makeAnyNSError()))
        XCTAssertNotNil(resultFailure(data: anyData, urlRequest: nonHTTPURLResponse, error: nil))
    }
    
    //MARK: - Helpers
    
    private func resultFailure(
        data: Data? = nil, urlRequest: URLResponse? = nil,
        error: Error? = nil, file: StaticString = #filePath,
        line: UInt = #line
    ) -> Error? {
        URLProtocolStub.stub(data: data, urlRequest: urlRequest, error: error)
        let expect = expectation(description: "wait")
        var recievedError: Error?
        makeSUT(file: file, line: line).get(from: makeAnyURL()) { result in
            switch result {
            case let .failure(error):
                recievedError = error
                
            default:
                XCTFail("Expected fails but result as success")
            }
            
            expect.fulfill()
        }
        
        wait(for: [expect], timeout: 1.0)
        return recievedError
    }
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        checkMemoryLeak(sut, file: file, line: line)
        return sut
    }
    
    private func makeAnyURL() -> URL {
        return URL(string: "http://any-url.com")!
    }
    
    private func makeAnyNSError() -> NSError {
        return NSError(domain: "any-error", code: -1)
    }
    
    //MARK: - Test Doubles
    
    private class URLProtocolStub: URLProtocol {
        
        private static var observeRequest: ((URLRequest) -> Void)?
        
        private static var stub: Stub?
        
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func observeRequest(observer: @escaping ((URLRequest) -> Void)) {
            observeRequest = observer
        }
        
        static func stub(data: Data? = nil, urlRequest: URLResponse? = nil, error: Error? = nil) {
            stub = .init(data: data, response: urlRequest, error: error)
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            observeRequest?(request)
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        static func startInterceptingRequests() {
            super.registerClass(self)
        }
        
        static func stopInterceptingRequests() {
            super.unregisterClass(self)
            stub = nil
            observeRequest = nil
        }
        
        override func startLoading() {
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(
                    self, didReceive: response,
                    cacheStoragePolicy: .notAllowed
                )
            }
            
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {
            //Do nothing
        }
    }
}
