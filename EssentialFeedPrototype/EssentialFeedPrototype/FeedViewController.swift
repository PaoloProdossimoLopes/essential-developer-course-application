import UIKit

final class FeedViewController: UITableViewController {
    
    private let feed = FeedImageViewModel.prototypeFeed
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feed.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeedImageCell", for: indexPath) as! FeedImageCell
        let model = feed[indexPath.row]
        cell.configure(with: model)
        return cell
    }
}

struct FeedImageViewModel {
    let description: String?
    let location: String?
    let imageName: String
}

extension FeedImageViewModel {
    static var prototypeFeed: [FeedImageViewModel] {
        return [
            FeedImageViewModel(
                description: "The East Side Gallery is an open-air gallery in Berlin. It consists of a series of murals painted directly on a 1,316 m long remnant of the Berlin Wall, located near the centre of Berlin, on Mühlenstraße in Friedrichshain-Kreuzberg. The gallery has official status as a Denkmal, or heritage-protected landmark.",
                location: "East Side Gallery\nMemorial in Berlin, Germany",
                imageName: "image-0"
            ),
            FeedImageViewModel(
                description: nil,
                location: "Cannon Street, London",
                imageName: "image-1"
            ),
            FeedImageViewModel(
                description: "The Desert Island in Faro is beautiful!! ☀️",
                location: nil,
                imageName: "image-2"
            ),
            FeedImageViewModel(
                description: nil,
                location: nil,
                imageName: "image-3"
            ),
            FeedImageViewModel(
                description: "Garth Pier is a Grade II listed structure in Bangor, Gwynedd, North Wales. At 1,500 feet in length, it is the second-longest pier in Wales, and the ninth longest in the British Isles.",
                location: "Garth Pier\nNorth Wales",
                imageName: "image-4"
            ),
            FeedImageViewModel(
                description: "Glorious day in Brighton!! 🎢",
                location: "Brighton Seafront",
                imageName: "image-5"
            )
        ]
    }
}

final class FeedImageCell: UITableViewCell {
    @IBOutlet private(set) var locationContainer: UIView!
    @IBOutlet private(set) var locationLabel: UILabel!
    @IBOutlet private(set) var feedImageView: UIImageView!
    @IBOutlet private(set) var descriptionLabel: UILabel!
    
    func configure(with model: FeedImageViewModel) {
        locationLabel.text = model.location
        locationContainer.isHidden = model.location == nil
        
        descriptionLabel.text = model.description
        descriptionLabel.isHidden = model.description == nil
        
        feedImageView.image = UIImage(named: model.imageName)
    }
}
