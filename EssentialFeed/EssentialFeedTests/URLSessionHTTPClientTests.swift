import XCTest
import Foundation

final class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func get(from url: URL) {
        session.dataTask(with: url) { (_, _, _) in }.resume()
    }
}

final class URLSessionHTTPClientTests: XCTestCase {
    
    //FORMAT: test_method_when_then()
    
    func test_get_passAnyURL_createsDataTaskWithURL() {
        let url = URL(string: "http://any-url.com")!
        let (sut, session) = makeSUT()
        
        sut.get(from: url)
        
        XCTAssertEqual(session.recievedURL, [url])
    }
    
    func test_get_passAnyURL_resumesDataTaskWithURL() {
        let url = URL(string: "http://any-url.com")!
        let task = URLSessionDataTaskSpy()
        let (sut, session) = makeSUT()
        session.stub(from: url, task: task)
        
        sut.get(from: url)
        
        XCTAssertEqual(task.resumeCallCount, 1)
    }
    
    //MARK: - Helpers
    private func makeSUT() -> (sut: URLSessionHTTPClient, session: URLSessionSpy) {
        let session = URLSessionSpy()
        let sut = URLSessionHTTPClient(session: session)
        return (sut, session)
    }
    
    private class URLSessionSpy: URLSession {
        
        private(set) var recievedURL: [URL] = []
        private(set) var stubs = [URL: URLSessionDataTask]()
        
        func stub(from url: URL, task: URLSessionDataTask) {
            stubs[url] = task
        }
        
        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            recievedURL.append(url)
            return stubs[url] ?? FakeURLSessionDataTask()
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
