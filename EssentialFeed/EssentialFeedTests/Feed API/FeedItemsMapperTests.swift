import XCTest
import EssentialFeed

class FeedItemsMapperTests: XCTestCase {
    
    func test_map_throwsErrorOnNon200HTTPResponse() throws {
            let json = makeItemsJSON([])
            let samples = [199, 201, 300, 400, 500]
            
            try samples.forEach { code in
                XCTAssertThrowsError(
                    try FeedItemsMapper.map(json, from: HTTPURLResponse(statusCode: code))
                )
            }
        }
        
        
    
    // MARK: - Helpers
        
        private func makeItem(id: UUID, description: String? = nil, location: String? = nil, imageURL: URL) -> (model: FeedImage, json: [String: Any]) {
            let item = FeedImage(id: id, description: description, location: location, url: imageURL)
            
            let json = [
                "id": id.uuidString,
                "description": description,
                "location": location,
                "image": imageURL.absoluteString
            ].compactMapValues { $0 }
            
            return (item, json)
        }
        
}
