import UIKit

typealias Observer<T> = (T) -> Void

protocol FeedImageCellControllerDelegate {
    func didRequestImage()
    func didCancelImageRequest()
}


final class FeedImageCellController: FeedImageCellLoadViewProtocol {
    
    //MARK: - Properties
    private let delegate: FeedImageCellControllerDelegate
    private var cell: FeedImageCell? = FeedImageCell()
    
    //MARK: - Initializers
    init(delegate: FeedImageCellControllerDelegate) {
        self.delegate = delegate
    }
    
    //MARK: - Methods
    func makeCell() -> FeedImageCell? {
        delegate.didRequestImage()
        return cell
    }
    
    func preload() {
        delegate.didRequestImage()
    }
    
    func cancelLoad() {
        releaseCellForReuse()
        delegate.didCancelImageRequest()
    }
    
    //MARK: - Helpers
    func display(model: FeedImagePresentableModel) {
        cell?.descriptionLabel.text = model.description
        cell?.localtionLabel.text = model.location
        cell?.localtionContainer.isHidden = !model.hasLocation
        
        let image = UIImage(data: model.data ?? Data())
        cell?.feedImageView.setImageAnimated(image)
        
        cell?.imageContainer.isShimerring = model.isLoading
        cell?.feedImageRetryButton.isHidden = !model.shouldRetry
        cell?.onRetry = delegate.didRequestImage
    }
    
    func releaseCellForReuse() {
        cell = nil
    }
}

extension UIImageView {
    func setImageAnimated(_ newImage: UIImage?) {
        image = newImage
        
        if image != nil {
            alpha = 0
            UIView.animate(withDuration: 0.25) {
                self.alpha = 1
            }
        }
    }
}
