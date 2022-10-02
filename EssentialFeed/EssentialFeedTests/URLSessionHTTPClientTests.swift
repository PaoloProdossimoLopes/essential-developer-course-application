import XCTest
import EssentialFeed

protocol IHTTSession {
    func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> IURLSessionDataTask
}

protocol IURLSessionDataTask {
    func resume()
}

final class URLSessionHTTPClient {
    private let session: IHTTSession
    
    init(session: IHTTSession) {
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
    
    private class URLSessionSpy: IHTTSession {
        
        private(set) var recievedURL: [URL] = []
        private var stubs: Stub?
        
        private struct Stub {
            let url: URL
            let task: IURLSessionDataTask
            let error: Error?
        }
        
        func stub(
            from url: URL,
            task: IURLSessionDataTask = FakeURLSessionDataTask(),
            error: Error? = nil
        ) {
            stubs = .init(url: url, task: task, error: error)
        }
        
        func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> IURLSessionDataTask {
            recievedURL.append(url)
            if let stub = stubs {
                completionHandler(nil, nil, stub.error)
                return stub.task
            }
            return FakeURLSessionDataTask()
        }
    }
    
    private class FakeURLSessionDataTask: IURLSessionDataTask {
        func resume() { /*Do Nothing*/ }
    }
    
    private class URLSessionDataTaskSpy: IURLSessionDataTask {
        var resumeCallCount = 0
        
        func resume() {
            resumeCallCount += 1
        }
    }
}
