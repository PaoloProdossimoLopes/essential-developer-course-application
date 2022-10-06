import XCTest
import EssentialFeed

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
        XCTAssertNotNil(resultFailure())
    }
    
    func test_getFromURLMethod_passNonHTTPURL_completesWithFailure() {
        XCTAssertNotNil(resultFailure(urlRequest: makeNonHTTPURLResponse()))
    }
    
    func test_getFromURL_passOnlyAnyData_completesWithFailure() {
        XCTAssertNotNil(resultFailure(data: makeAnyData()))
    }
    
    func test_getFromURL_passAnyDataAndError_completesWithFailure() {
        XCTAssertNotNil(resultFailure(data: makeAnyData(), error: makeAnyNSError()))
    }
    
    func test_getFromURL_passAnyErrorAndNonHTTPURLResponse_completesWithFailure() {
        XCTAssertNotNil(resultFailure(urlRequest: makeNonHTTPURLResponse(), error: makeAnyNSError()))
    }
    
    func test_getFromURL_passAnyHTTPURLResponseAndError_completesWithFailure() {
        XCTAssertNotNil(resultFailure(urlRequest: makeAnyHTTPURLResponse(), error: makeAnyNSError()))
    }
    
    func test_getFromURL_passAnyDataWithNonHTTPURLResponseAndError_completesWithFailure() {
        XCTAssertNotNil(resultFailure(data: makeAnyData(), urlRequest: makeNonHTTPURLResponse(), error: makeAnyNSError()))
    }
    
    func test_getFromURL_passAnyDataWithAnyHTTPURLResponseAndError_completesWithFailure() {
        XCTAssertNotNil(resultFailure(data: makeAnyData(), urlRequest: makeAnyHTTPURLResponse(), error: makeAnyNSError()))
    }
    
    func test_getFromURL_passAnyDataAndNonHTTPURLResponse_completesWithFailure() {
        XCTAssertNotNil(resultFailure(data: makeAnyData(), urlRequest: makeNonHTTPURLResponse(), error: nil))
    }
    
    func test_getFromURLMethod_successOnHTTPURLResponseWithData() {
        let data = makeAnyData()
        let response = makeAnyHTTPURLResponse()
        let recieved = resultSuccess(data: data, urlRequest: response)
        XCTAssertEqual(recieved?.data, data)
        XCTAssertEqual(recieved?.response.url, response.url)
        XCTAssertEqual(recieved?.response.statusCode, response.statusCode)
    }
    
    func test_getFromURLMethod_passOnlyHTTPURLResponse_completesWithSuccessButEmptyData() {
        let response = makeAnyHTTPURLResponse()
        let recieved = resultSuccess(data: nil, urlRequest: response)
        XCTAssertEqual(recieved?.data, Data())
        XCTAssertEqual(recieved?.response.url, response.url)
        XCTAssertEqual(recieved?.response.statusCode, response.statusCode)
    }
    
    //MARK: - Helpers
    
    private func resultSuccess(
        data: Data? = nil, urlRequest: URLResponse? = nil,
        error: Error? = nil, file: StaticString = #filePath,
        line: UInt = #line
    ) -> (data: Data, response: HTTPURLResponse)? {
        let result = resultHelper(data: data, urlRequest: urlRequest, error: error, file: file, line: line)
        
        var recievedError: (data: Data, response: HTTPURLResponse)?
        switch result {
        case let .success(data, response):
            recievedError = (data, response)
            
        default:
            XCTFail("Expected fails but result as success: \(result)", file: file, line: line)
        }
        return recievedError
    }
    
    private func resultFailure(
        data: Data? = nil, urlRequest: URLResponse? = nil,
        error: Error? = nil, file: StaticString = #filePath,
        line: UInt = #line
    ) -> Error? {
        let result = resultHelper(data: data, urlRequest: urlRequest, error: error, file: file, line: line)
        var recievedError: Error?
        switch result {
        case let .failure(error):
            recievedError = error
            
        default:
            XCTFail("Expected fails but result as success: \(result)", file: file, line: line)
        }
        return recievedError
    }
    
    private func resultHelper(
        data: Data? = nil, urlRequest: URLResponse? = nil,
        error: Error? = nil, file: StaticString = #filePath,
        line: UInt = #line
    ) -> HTTPClientResult {
        URLProtocolStub.stub(data: data, response: urlRequest, error: error)
        let expect = expectation(description: "wait")
        var recievedError: HTTPClientResult!
        makeSUT(file: file, line: line).get(from: makeAnyURL()) { result in
            recievedError = result
            expect.fulfill()
        }
        
        wait(for: [expect], timeout: 1.0)
        return recievedError
    }
    
    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> HTTPClient {
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
    
    private func makeNonHTTPURLResponse() -> URLResponse {
        return URLResponse(url: makeAnyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    private func makeAnyHTTPURLResponse() -> HTTPURLResponse {
        return HTTPURLResponse(url: makeAnyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    private func makeAnyData() -> Data {
        return Data("any_data".utf8)
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
        
        static func stub(data: Data? = nil, response: URLResponse? = nil, error: Error? = nil) {
            stub = .init(data: data, response: response, error: error)
        }
        
        override class func canInit(with request: URLRequest) -> Bool {
//            observeRequest?(request)
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
            if let requestObserver = URLProtocolStub.observeRequest {
                client?.urlProtocolDidFinishLoading(self)
                return requestObserver(request)
            }
            
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
