import Foundation

struct RemoteFeedImage: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let url: URL
    
    enum CodingKeys: String, CodingKey {
        case id, description, location
        case url = "image"
    }
}
