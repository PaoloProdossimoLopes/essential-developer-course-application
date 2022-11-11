import UIKit
import EssentialFeed

final class FeedImageCellController {
    
    //MARK: - Properties
    private var task: FeedImageDataLoaderTask?
    private let model: FeedImage
    private let imageLoader: FeedImageDataLoader
    
    //MARK: - Initializers
    init(model: FeedImage, imageLoader: FeedImageDataLoader) {
        self.model = model
        self.imageLoader = imageLoader
    }
    
    //MARK: - Methods
    func preload() {
        task = imageLoader.loadImageData(from: model.image) { _ in }
    }
    
    func makeCell() -> UITableViewCell {
        let cell = FeedImageCell()
        cell.descriptionLabel.text = model.description
        cell.localtionLabel.text = model.location
        cell.localtionContainer.isHidden = (model.location == nil)
        cell.feedImageRetryButton.isHidden = true
        cell.feedImageView.image = nil
        cell.imageContainer.startShimmer()
        
        let loadImage = { [weak self, weak cell] in
            guard let self = self else { return }
            self.task = self.imageLoader.loadImageData(from: self.model.image) { [weak cell] result in
                let data = try? result.get()
                let image = data.map(UIImage.init) ?? nil
                cell?.feedImageView.image = image
                cell?.feedImageRetryButton.isHidden = (image != nil)
                cell?.imageContainer.stopShimmering()
            }
        }
        
        cell.onRetry = loadImage
        loadImage()
        return cell
    }
    
    //MARK: - Deinit
    deinit { task?.cancel() }
}
