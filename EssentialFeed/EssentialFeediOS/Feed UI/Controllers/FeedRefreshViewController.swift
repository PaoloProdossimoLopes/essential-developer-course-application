import UIKit
import EssentialFeed

final class FeedRefreshViewController: NSObject {
    
    //MARK: - Properties
    private var feedLoader: IFeedLoader?
    
    var onRefresh: (([FeedImage]) -> Void)?
    
    //MARK: - UI Component
    private(set) lazy var refreshView: UIRefreshControl = {
        let component = UIRefreshControl()
        component.addTarget(self, action: #selector(load), for: .valueChanged)
        return component
    }()
    
    //MARK: - Initializer
    init(feedLoader: IFeedLoader?) {
        self.feedLoader = feedLoader
    }
    
    //MARK: - Methods
    func loadFeed() {
        refreshView.beginRefreshing()
        feedLoader?.load { [weak self] result in
            
            if case let .success(model) = result {
                self?.onRefresh?(model)
            }
            
            self?.refreshView.endRefreshing()
        }
    }
    
    //MARK: - Selectors
    @objc private func load() {
        loadFeed()
    }
}
