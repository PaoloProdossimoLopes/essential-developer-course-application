import Foundation
import EssentialFeed

final class FeedViewModel {
    //MARK: - Propeties
    private let feedLoader: IFeedLoader
    private(set) var isLoading: Bool = false {
        didSet { onChange?(self) }
    }
    
    var onChange: ((FeedViewModel) -> Void)?
    var onRefresh: (([FeedImage]) -> Void)?
    
    
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
        isLoading = true
        feedLoader.load { [weak self] result in
            
            if case let .success(model) = result {
                self?.onRefresh?(model)
            }
            
            self?.isLoading = false
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
