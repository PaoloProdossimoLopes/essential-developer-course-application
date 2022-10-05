import Foundation

public final class URLSessionHTTPClient: HTTPClient {
    
    private let session: URLSession
    
    private struct UnexpectedRepresentationError: Error { /*Non Nescessary*/ }
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    public func get(from url: URL, completion: @escaping ((HTTPClientResult) -> Void)) {
        session.dataTask(with: url) { (data, response, error) in
            if let error = error {
                completion(.failure(error))
                
            } else if let data = data, let response = response as? HTTPURLResponse {
                completion(.success(data, response))
            } else {
                completion(.failure(UnexpectedRepresentationError()))
            }
        }.resume()
    }
}
