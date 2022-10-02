import XCTest
import EssentialFeed

final class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession) {
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
    
    func test_get_passAnyURL_createsDataTaskWithURL() {
        let url = URL(string: "http://any-url.com")!
        let (sut, session) = makeSUT()
        
        sut.get(from: url) { _ in }
        
        XCTAssertEqual(session.recievedURL, [url])
    }
    
    func test_get_passAnyURL_resumesDataTaskWithURL() {
        let url = URL(string: "http://any-url.com")!
        let task = URLSessionDataTaskSpy()
        let (sut, session) = makeSUT()
        session.stub(from: url, task: task)
        
        sut.get(from: url) { _ in }
        
        XCTAssertEqual(task.resumeCallCount, 1)
    }
    
    func test_getFromURLMethod_passURL_failsOnRequestError() {
        let url = URL(string: "http://any-url.com")!
        let (sut, session) = makeSUT()
        let error = NSError(domain: "any-error", code: -1)
        session.stub(from: url, error: error)
        
        let expect = expectation(description: "wait")
        sut.get(from: url) { result in
            switch result {
            case let .failure(recievedError as NSError):
                XCTAssertEqual(recievedError, error)
            default:
                XCTFail("Expected fails but result as success")
            }
            
            expect.fulfill()
        }
        
        wait(for: [expect], timeout: 1.0)
    }
    
    //MARK: - Helpers
    private func makeSUT() -> (sut: URLSessionHTTPClient, session: URLSessionSpy) {
        let session = URLSessionSpy()
        let sut = URLSessionHTTPClient(session: session)
        return (sut, session)
    }
    
    private class URLSessionSpy: URLSession {
        
        private(set) var recievedURL: [URL] = []
        private var stubs: Stub?
        
        private struct Stub {
            let url: URL
            let task: URLSessionDataTask
            let error: Error?
        }
        
        func stub(
            from url: URL,
            task: URLSessionDataTask = FakeURLSessionDataTask(),
            error: Error? = nil
        ) {
            stubs = .init(url: url, task: task, error: error)
        }
        
        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            recievedURL.append(url)
            if let stub = stubs {
                completionHandler(nil, nil, stub.error)
                return stub.task
            }
            return FakeURLSessionDataTask()
        }
    }
    
    private class FakeURLSessionDataTask: URLSessionDataTask {
        override func resume() {
            //Do Nothing
        }
    }
    
    private class URLSessionDataTaskSpy: URLSessionDataTask {
        var resumeCallCount = 0
        
        override func resume() {
            resumeCallCount += 1
        }
    }
}
