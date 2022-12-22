import Foundation
import EssentialFeed

final class FeedViewModel {
    
    //MARK: - Propeties
    private let feedLoader: IFeedLoader
    
    var onLoadingStateChange: Observer<Bool>?
    var onRefresh: Observer<[FeedImage]>?
    
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
        onLoadingStateChange?(true)
        feedLoader.load { [weak self] result in
            
            if case let .success(model) = result {
                self?.onRefresh?(model)
            }
            
            self?.onLoadingStateChange?(false)
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
