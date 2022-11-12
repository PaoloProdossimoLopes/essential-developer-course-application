import UIKit

final class FeedRefreshViewController: NSObject {
    
    //MARK: - Properties
    private var viewModel: FeedViewModel
    
    //MARK: - UI Component
    private(set) lazy var refreshView = binded(UIRefreshControl())
    
    //MARK: - Initializer
    init(viewModel: FeedViewModel) {
        self.viewModel = viewModel
    }
    
    //MARK: - Methods
    func loadFeed() {
        viewModel.load()
    }
    
    //MARK: - Helpers
    private func binded(_ view: UIRefreshControl) -> UIRefreshControl {
        viewModel.onLoadingStateChange = { [weak view] isLoading in
            isLoading ? view?.beginRefreshing() : view?.endRefreshing()
        }
        view.addTarget(self, action: #selector(load), for: .valueChanged)
        return view
    }
    
    //MARK: - Selectors
    @objc private func load() {
        loadFeed()
    }
}
