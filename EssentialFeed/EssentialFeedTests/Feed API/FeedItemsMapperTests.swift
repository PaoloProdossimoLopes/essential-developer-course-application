import XCTest
import EssentialFeed

class FeedItemsMapperTests: XCTestCase {
    
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
