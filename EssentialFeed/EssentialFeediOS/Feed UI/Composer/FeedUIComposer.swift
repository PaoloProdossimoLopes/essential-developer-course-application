import UIKit
import EssentialFeed

public enum FeedUIComposer {
    static func composeWith(
        feedLoader: IFeedLoader,
        imageLoader: FeedImageDataLoader
    ) -> EssentialFeedController {
        let feedPresenter = FeedPresenter()
        let presenterLoaderAdapter = FeedLoaderPresentationAdapter(
            feedLoader: MainThreadDecorator(feedLoader),
            feedPresenter: feedPresenter
        )
        let refreshController = FeedRefreshViewController(presenter: presenterLoaderAdapter)
        let essentialFeedController = EssentialFeedController(refreshController: refreshController)
        essentialFeedController.title = FeedPresenter.title
        
        feedPresenter.viewLoading = WeakRefVirtualProxy(refreshController)
        feedPresenter.viewPresent = FeedViewAdapter(
            controller: essentialFeedController,
            loader: MainThreadDecorator(imageLoader)
        )
        
        return essentialFeedController
    }
}

private final class MainThreadDecorator<T> {
    
    private let decoratee: T
    
    init(_ decoratee: T) {
        self.decoratee = decoratee
    }
    
    func onMainIfNeeded(_ completion: @escaping () -> Void) {
        
        guard Thread.isMainThread else {
            return DispatchQueue.main.async(execute: completion)
        }
        
        return completion()
    }
}

extension MainThreadDecorator: IFeedLoader where T == IFeedLoader {
    func load(completion: @escaping ((EssentialFeed.FeedResult) -> Void)) {
        decoratee.load { [weak self] result in
            self?.onMainIfNeeded { completion(result) }
        }
    }
}

extension MainThreadDecorator: FeedImageDataLoader where T == FeedImageDataLoader {
    func loadImageData(from url: URL, completion: @escaping ((FeedImageDataLoader.Result) -> Void)) -> FeedImageDataLoaderTask {
        decoratee.loadImageData(from: url) { [weak self] result in
            self?.onMainIfNeeded { completion(result) }
        }
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
            let adapter = FeedCellPresenterAdapter(model: model, imageLoader: loader)
            let controller = FeedImageCellController(delegate: adapter)
            let presenter = FeedImageCellPresenter(dataValidator: { UIImage(data: $0) != nil })
            adapter.presenter = presenter
            presenter.presentView = WeakRefVirtualProxy(controller)
            return controller
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

extension WeakRefVirtualProxy: FeedImageCellLoadViewProtocol where T: FeedImageCellLoadViewProtocol {
    func display(model: FeedImagePresentableModel) {
        object?.display(model: model)
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

private final class FeedCellPresenterAdapter: FeedImageCellControllerDelegate {
    private let model: FeedImage
    private let imageLoader: FeedImageDataLoader
    private var task: FeedImageDataLoaderTask?
    
    var presenter: FeedImageCellPresenter?
    
    init(model: FeedImage, imageLoader: FeedImageDataLoader) {
        self.model = model
        self.imageLoader = imageLoader
    }
    
    func didRequestImage() {
        presenter?.didStartLoadingImageData(for: model)
        
        let model = self.model
        task = imageLoader.loadImageData(from: model.image) { [weak self] result in
            switch result {
            case let .success(data):
                self?.presenter?.didFinishLoadingImageData(with: data, for: model)
                
            case let .failure(error):
                self?.presenter?.didFinishLoadingImageData(with: error, for: model)
            }
        }
    }
    
    func didCancelImageRequest() {
        task?.cancel()
    }
}
