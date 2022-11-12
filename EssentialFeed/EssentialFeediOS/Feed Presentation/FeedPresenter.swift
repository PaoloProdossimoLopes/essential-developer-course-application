import Foundation
import EssentialFeed

protocol IFeedLoadingView {
    func display(_ isLoading: Bool)
}

protocol IFeedPresentationView {
    func display(_ feed: [FeedImage])
}

final class FeedPresenter {
    
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
        viewLoading?.display(true)
        feedLoader.load { [weak self] result in
            
            if case let .success(model) = result {
                self?.viewPresent?.display(model)
            }
            
            self?.viewLoading?.display(false)
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
