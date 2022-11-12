import UIKit
import EssentialFeed

public enum FeedUIComposer {
    static func composeWith(
        feedLoader: IFeedLoader,
        imageLoader: FeedImageDataLoader
    ) -> EssentialFeedController {
        let feedPresenter = FeedPresenter()
        let presenterLoaderAdapter = FeedLoaderPresentationAdapter(
            feedLoader: feedLoader,
            feedPresenter: feedPresenter
        )
        let refreshController = FeedRefreshViewController(presenter: presenterLoaderAdapter)
        let essentialFeedController = EssentialFeedController(refreshController: refreshController)
        
        feedPresenter.viewLoading = WeakRefVirtualProxy(refreshController)
        feedPresenter.viewPresent = FeedViewAdapter(
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
    
    func display(_ model: PresentableDataModel) {
        let controllers = model.feed.map { model in
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
    func display(_ model: PresentableLoadingModel) {
        object?.display(model)
    }
}

private final class FeedLoaderPresentationAdapter: IFeedRefreshPresenter {
    private let loader: IFeedLoader
    private let presenter: FeedPresenter
    
    init(feedLoader: IFeedLoader, feedPresenter: FeedPresenter) {
        self.loader = feedLoader
        self.presenter = feedPresenter
    }
    
    func load() {
        presenter.didStartLoadingFeed()
        
        loader.load { [weak self] result in
            guard let self = self else { return }
            switch result {
            case let .success(model):
                self.presenter.didFinishLoadingFeed(with: model)
            case .failure:
                self.presenter.didFinishLoadingFailure()
            }
        }
    }
}
