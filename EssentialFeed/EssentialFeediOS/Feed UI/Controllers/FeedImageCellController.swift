import UIKit

typealias Observer<T> = (T) -> Void

final class FeedImageCellController {
    
    //MARK: - Properties
    private let viewModel: FeedImageCellViewModel
    
    //MARK: - Initializers
    init(viewModel: FeedImageCellViewModel) {
        self.viewModel = viewModel
    }
    
    //MARK: - Methods
    func preload() {
        viewModel.loadImageData()
    }
    
    func makeCell() -> UITableViewCell {
        let cell = binded(FeedImageCell())
        cell.onRetry?()
        return cell
    }
    
    func cancelLoad() {
        viewModel.cancel()
    }
    
    //MARK: - Helpers
    private func binded(_ cell: FeedImageCell) -> FeedImageCell {
        cell.descriptionLabel.text = viewModel.description
        cell.localtionLabel.text = viewModel.location
        cell.localtionContainer.isHidden = !viewModel.hasLocaltion
        cell.onRetry = viewModel.loadImageData
        
        viewModel.onLoadChange = { [weak cell] data in
            let image = data.map(UIImage.init) ?? nil
            cell?.feedImageView.image = image
        }
        
        viewModel.onImageLoadingStateChange = { [weak cell] isLoading in
            cell?.imageContainer.isShimerring = isLoading
        }
        
        viewModel.onShouldRetryImageLoadStateChange = { [weak cell] shouldRetry in
            cell?.feedImageRetryButton.isHidden = !shouldRetry
        }
        
        return cell
    }
}
