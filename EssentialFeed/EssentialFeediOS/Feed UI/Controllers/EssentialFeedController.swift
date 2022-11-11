import UIKit
import EssentialFeed

final class EssentialFeedController: UITableViewController {
    
    //MARK: - Properites
    private var refreshController: FeedRefreshViewController?
    private var imageLoader: FeedImageDataLoader?
    
    private var cellsController = [IndexPath: FeedImageCellController]()
    private var tableModels = [FeedImage]() {
        didSet { tableView.reloadData() }
    }
    
    //MARK: - Initializer
    convenience init(feedLoader: IFeedLoader, imageLoader: FeedImageDataLoader) {
        self.init()
        self.refreshController = .init(feedLoader: feedLoader)
        self.imageLoader = imageLoader
    }
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = refreshController?.refreshView
        refreshController?.onRefresh = { [weak self] model in
            guard let self = self else { return }
            self.tableModels = model
        }
        refreshController?.loadFeed()
        
        tableView.prefetchDataSource = self
    }
    
    //MARK: - TableView methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableModels.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let controller = cellController(forRowAt: indexPath)
        return controller.makeCell()
    }
    
    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cellsController[indexPath] = nil
    }
    
    //MARK: - Helpers
    
    private func removeCellController(forRowAt indexPath: IndexPath) {
        cellsController[indexPath] = nil
    }
    
    private func cellController(forRowAt indexPath: IndexPath) -> FeedImageCellController {
        let model = tableModels[indexPath.row]
        let cellController = FeedImageCellController(model: model, imageLoader: imageLoader!)
        cellsController[indexPath] = cellController
        return cellController
    }
}

//MARK: - UITableViewDataSourcePrefetching
extension EssentialFeedController: UITableViewDataSourcePrefetching {
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            let controller = cellController(forRowAt: indexPath)
            controller.preload()
        }
    }

    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach(removeCellController)
    }
}
