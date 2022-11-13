import UIKit

typealias Observer<T> = (T) -> Void

protocol FeedImageCellControllerDelegate {
    func didRequestImage()
    func didCancelImageRequest()
}


final class FeedImageCellController: FeedImageCellLoadViewProtocol {
    
    //MARK: - Properties
    private let delegate: FeedImageCellControllerDelegate
    private let cell = FeedImageCell()
    
    //MARK: - Initializers
    init(delegate: FeedImageCellControllerDelegate) {
        self.delegate = delegate
    }
    
    //MARK: - Methods
    func makeCell() -> FeedImageCell {
        delegate.didRequestImage()
        return cell
    }
    
    func preload() {
        delegate.didRequestImage()
    }
    
    func cancelLoad() {
        delegate.didCancelImageRequest()
    }
    
    //MARK: - Helpers
    func display(model: FeedImagePresentableModel) {
        cell.descriptionLabel.text = model.description
        cell.localtionLabel.text = model.location
        cell.localtionContainer.isHidden = !model.hasLocation
        
        cell.feedImageView.image = UIImage(data: model.data ?? Data())
        cell.imageContainer.isShimerring = model.isLoading
        cell.feedImageRetryButton.isHidden = !model.shouldRetry
        cell.onRetry = delegate.didRequestImage
    }
}
