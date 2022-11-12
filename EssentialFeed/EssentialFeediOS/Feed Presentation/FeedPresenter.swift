import Foundation
import EssentialFeed

struct PresentableLoadingModel {
    let isLoading: Bool
}

struct PresentableDataModel {
    let feed: [FeedImage]
}

protocol IFeedLoadingView {
    func display(_ model: PresentableLoadingModel)
}

protocol IFeedPresentationView {
    func display(_ model: PresentableDataModel)
}

protocol IFeedRefreshPresenter {
    func load()
}

final class FeedPresenter: IFeedRefreshPresenter {
    
    //MARK: - Propeties
    private let feedLoader: IFeedLoader
    
    var viewLoading: IFeedLoadingView?
    var viewPresent: IFeedPresentationView?
    
    //MARK: - Initializer
    init(feedLoader: IFeedLoader) {
        self.feedLoader = feedLoader
    }
    
    //MARK: - Methods
    func load() {
        loadFeed()
    }
    
    //MARK: - Helpers
    private func loadFeed() {
        viewLoading?.display(PresentableLoadingModel(isLoading: true))
        feedLoader.load { [weak self] result in
            
            if case let .success(model) = result {
                self?.viewPresent?.display(PresentableDataModel(feed: model))
            }
            
            self?.viewLoading?.display(PresentableLoadingModel(isLoading: false))
        }
    }
}

//MARK: - FeedViewModel+State
private extension FeedViewModel {
    enum State {
        case pending
        case loading
    }
}
