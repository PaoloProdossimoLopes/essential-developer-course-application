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
    
    //FORMAT: test_method_when_then()
    func test_getFromURLMethod_passURL_failsOnRequestError() {
        URLProtocolStub.startInterceptingRequests() //Add the top of test
        let url = URL(string: "http://any-url.com")!
        let sut = URLSessionHTTPClient()
        let error = NSError(domain: "any-error", code: -1)
        URLProtocolStub.stub(from: url, error: error)
        
        let expect = expectation(description: "wait")
        sut.get(from: url) { result in
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
        URLProtocolStub.stopInterceptingRequests() //Add the end of test
    }
    
    //MARK: - Helpers
    
    private class URLProtocolStub: URLProtocol {
        
        private(set) var recievedURL: [URL] = []
        private static var stubs = [URL: Stub]()
        
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func stub(from url: URL, data: Data? = nil, urlRequest: URLResponse? = nil, error: Error? = nil) {
            stubs[url] = .init(data: data, response: urlRequest, error: error)
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
            guard let url = request.url else { return false }
            return stubs[url] != nil
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        static func startInterceptingRequests() {
            super.registerClass(self)
        }
        
        static func stopInterceptingRequests() {
            super.unregisterClass(self)
            stubs = [:]
        }
        
        override func startLoading() {
            guard let url = request.url, let stub = URLProtocolStub.stubs[url] else { return }
            
            if let data = stub.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = stub.response {
                client?.urlProtocol(
                    self, didReceive: response,
                    cacheStoragePolicy: .notAllowed
                )
            }
            
            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {
            //Do nothing
        }
    }
}
