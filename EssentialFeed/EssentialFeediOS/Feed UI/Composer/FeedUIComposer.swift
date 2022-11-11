import Foundation
import EssentialFeed

public enum FeedUIComposer {
    static func composeWith(
        feedLoader: IFeedLoader,
        imageLoader: FeedImageDataLoader
    ) -> EssentialFeedController {
        let refreshController = FeedRefreshViewController(feedLoader: feedLoader)
        let essentialFeedController = EssentialFeedController(refreshController: refreshController)
        
        refreshController.onRefresh = { [weak essentialFeedController] models in
            let controllers = models.map { model in
                FeedImageCellController(model: model, imageLoader: imageLoader)
            }
            essentialFeedController?.update(controllers)
        }
        
        return essentialFeedController
    }
}
