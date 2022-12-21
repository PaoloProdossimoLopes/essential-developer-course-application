import XCTest
import EssentialFeed

class URLSessionHTTPClientTests: XCTestCase {
    override func tearDown() {
            super.tearDown()
            
            URLProtocolStub.removeStub()
        }
    
    // MARK: - Helpers
        
        private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> HTTPClient {
            let configuration = URLSessionConfiguration.ephemeral
            configuration.protocolClasses = [URLProtocolStub.self]
            let session = URLSession(configuration: configuration)
            
            let sut = URLSessionHTTPClient(session: session)
            checkMemoryLeak(sut, file: file, line: line)
            return sut
        }
        
        private func resultValuesFor(_ values: (data: Data?, response: URLResponse?, error: Error?), file: StaticString = #filePath, line: UInt = #line) -> (data: Data, response: HTTPURLResponse)? {
            let result = resultFor(values, file: file, line: line)
            
            switch result {
            case let .success(values):
                return values
            default:
                XCTFail("Expected success, got \(result) instead", file: file, line: line)
                return nil
            }
        }
        
        private func resultErrorFor(_ values: (data: Data?, response: URLResponse?, error: Error?)? = nil, taskHandler: (HTTPClientTask) -> Void = { _ in }, file: StaticString = #filePath, line: UInt = #line) -> Error? {
            let result = resultFor(values, taskHandler: taskHandler, file: file, line: line)
            
            switch result {
            case let .failure(error):
                return error
            default:
                XCTFail("Expected failure, got \(result) instead", file: file, line: line)
                return nil
            }
        }
        
        private func resultFor(_ values: (data: Data?, response: URLResponse?, error: Error?)?, taskHandler: (HTTPClientTask) -> Void = { _ in },  file: StaticString = #filePath, line: UInt = #line) -> HTTPClient.Result {
            values.map { URLProtocolStub.stub(data: $0, response: $1, error: $2) }
            
            let sut = makeSUT(file: file, line: line)
            let exp = expectation(description: "Wait for completion")
            
            var receivedResult: HTTPClient.Result!
            taskHandler(sut.get(from: anyURL()) { result in
                receivedResult = result
                exp.fulfill()
            })
            
            wait(for: [exp], timeout: 1.0)
            return receivedResult
        }
        
        private func anyHTTPURLResponse() -> HTTPURLResponse {
            return HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
        }
        
        private func nonHTTPURLResponse() -> URLResponse {
            return URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        }
}
