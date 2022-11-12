import UIKit
import EssentialFeed

public enum FeedUIComposer {
    static func composeWith(
        feedLoader: IFeedLoader,
        imageLoader: FeedImageDataLoader
    ) -> EssentialFeedController {
        let presenter = FeedPresenter(feedLoader: feedLoader)
        let refreshController = FeedRefreshViewController(presenter: presenter)
        let essentialFeedController = EssentialFeedController(refreshController: refreshController)
        
        presenter.viewLoading = WeakRefVirtualProxy(refreshController)
        presenter.viewPresent = FeedViewAdapter(
            controller: essentialFeedController,
            loader: imageLoader
        )
        
        return essentialFeedController
    }
}

private final class FeedViewAdapter: IFeedPresentationView {
    
    private weak var controller: EssentialFeedController?
    private let loader: FeedImageDataLoader
    
    init(controller: EssentialFeedController, loader: FeedImageDataLoader) {
        self.controller = controller
        self.loader = loader
    }
    
    func display(_ feed: [FeedImage]) {
        let controllers = feed.map { model in
            let viewModel = FeedImageCellViewModel(
                imageLoader: loader, model: model,
                dataValidator: { UIImage(data: $0) != nil }
            )
            return FeedImageCellController(viewModel: viewModel)
        }
        
        controller?.update(controllers)
    }
}


private final class WeakRefVirtualProxy<T: AnyObject> {
    private weak var object: T?
    
    init(_ object: T) {
        self.object = object
    }
}

extension WeakRefVirtualProxy: IFeedLoadingView where T: IFeedLoadingView {
    func display(_ isLoading: Bool) {
        object?.display(isLoading)
    }
}
