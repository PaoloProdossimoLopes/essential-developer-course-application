import XCTest
import Foundation

final class URLSessionHTTPClient {
    private let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func get(from url: URL) {
        session.dataTask(with: url, completionHandler: { (_, _, _) in })
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
    
    //MARK: - Helpers
    private func makeSUT() -> (sut: URLSessionHTTPClient, session: URLSessionSpy) {
        let session = URLSessionSpy()
        let sut = URLSessionHTTPClient(session: session)
        return (sut, session)
    }
    
    private class URLSessionSpy: URLSession {
        
        private(set) var recievedURL: [URL] = []
        
        override func dataTask(with url: URL, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            recievedURL.append(url)
            return FakeURLSessionDataTask()
        }
    }
    
    private class FakeURLSessionDataTask: URLSessionDataTask {
        
    }
}
