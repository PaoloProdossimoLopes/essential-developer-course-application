import UIKit

final class FeedRefreshViewController: NSObject, IFeedLoadingView {
    func display(_ isLoading: Bool) {
        isLoading ? refreshView.beginRefreshing() : refreshView.endRefreshing()
    }
    
    //MARK: - Properties
    private var presenter: FeedPresenter
    
    //MARK: - UI Component
    private(set) lazy var refreshView = loadView(UIRefreshControl())
    
    //MARK: - Initializer
    init(presenter: FeedPresenter) {
        self.presenter = presenter
    }
    
    //MARK: - Methods
    func loadFeed() {
        presenter.load()
    }
    
    //MARK: - Helpers
    private func loadView(_ view: UIRefreshControl) -> UIRefreshControl {
        view.addTarget(self, action: #selector(load), for: .valueChanged)
        return view
    }
    
    //MARK: - Selectors
    @objc private func load() {
        loadFeed()
    }
}
