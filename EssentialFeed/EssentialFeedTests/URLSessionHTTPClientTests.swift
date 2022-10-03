import XCTest
import EssentialFeed

final class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession = .shared) {
        self.session = session
    }
    
    func get(from url: URL, completion: @escaping ((HTTPClientResult) -> Void)) {
        session.dataTask(with: url) { (_, _, error) in
            if let error {
                completion(.failure(error))
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
        let url = makeAnyURL()
        let error = makeAnyNSError()
        URLProtocolStub.stub(error: error)
        
        let expect = expectation(description: "wait")
        makeSUT().get(from: url) { result in
            switch result {
            case let .failure(recievedError as NSError):
                XCTAssertEqual(recievedError.code, error.code)
                XCTAssertEqual(recievedError.domain, error.domain)
            default:
                XCTFail("Expected fails but result as success")
            }
            
            expect.fulfill()
        }
        
        wait(for: [expect], timeout: 1.0)
    }
    
    //MARK: - Helpers
    
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
