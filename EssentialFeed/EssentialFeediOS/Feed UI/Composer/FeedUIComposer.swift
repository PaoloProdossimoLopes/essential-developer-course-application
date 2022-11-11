import Foundation
import EssentialFeed

public enum FeedUIComposer {
    static func composeWith(
        feedLoader: IFeedLoader,
        imageLoader: FeedImageDataLoader
    ) -> EssentialFeedController {
        let refreshController = FeedRefreshViewController(feedLoader: feedLoader)
        let essentialFeedController = EssentialFeedController(refreshController: refreshController)
        
        refreshController.onRefresh = adaptFeedToCellControllers(
            forwardingTo: essentialFeedController, loader: imageLoader)
        
        return essentialFeedController
    }
    
    private static func adaptFeedToCellControllers(forwardingTo controller: EssentialFeedController, loader: FeedImageDataLoader) -> (([FeedImage]) -> Void) {
        return { [weak controller] models in
            let controllers = models.map { model in
                FeedImageCellController(model: model, imageLoader: loader)
            }
            controller?.update(controllers)
        }
    }
}
