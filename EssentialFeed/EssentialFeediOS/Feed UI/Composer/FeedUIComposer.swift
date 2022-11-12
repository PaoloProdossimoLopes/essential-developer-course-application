import UIKit
import EssentialFeed

public enum FeedUIComposer {
    static func composeWith(
        feedLoader: IFeedLoader,
        imageLoader: FeedImageDataLoader
    ) -> EssentialFeedController {
        let feedViewModel = FeedViewModel(feedLoader: feedLoader)
        let refreshController = FeedRefreshViewController(viewModel: feedViewModel)
        let essentialFeedController = EssentialFeedController(refreshController: refreshController)
        
        feedViewModel.onRefresh = adaptFeedToCellControllers(
            forwardingTo: essentialFeedController, loader: imageLoader)
        
        return essentialFeedController
    }
    
    private static func adaptFeedToCellControllers(forwardingTo controller: EssentialFeedController, loader: FeedImageDataLoader) -> (([FeedImage]) -> Void) {
        return { [weak controller] models in
            let controllers = models.map { model in
                let viewModel = FeedImageCellViewModel(
                    imageLoader: loader, model: model,
                    dataValidator: { UIImage(data: $0) != nil })
                return FeedImageCellController(viewModel: viewModel)
            }
            
            controller?.update(controllers)
        }
    }
}
