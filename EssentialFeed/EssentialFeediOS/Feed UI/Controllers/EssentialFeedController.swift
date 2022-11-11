import UIKit
import EssentialFeed

final class EssentialFeedController: UITableViewController {
    
    //MARK: - Properites
    private var refreshController: FeedRefreshViewController?
    private var imageLoader: FeedImageDataLoader?
    
    
    private var tasks = [IndexPath: FeedImageDataLoaderTask]()
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
        let model = tableModels[indexPath.row]
        let cell = FeedImageCell()
        cell.descriptionLabel.text = model.description
        cell.localtionLabel.text = model.location
        cell.localtionContainer.isHidden = (model.location == nil)
        cell.feedImageRetryButton.isHidden = true
        cell.feedImageView.image = nil
        cell.imageContainer.startShimmer()
        
        let loadImage = { [weak self, weak cell] in
            guard let self = self else { return }
            self.tasks[indexPath] = self.imageLoader?.loadImageData(from: model.image) { [weak cell] result in
                let data = try? result.get()
                let image = data.map(UIImage.init) ?? nil
                cell?.feedImageView.image = image
                cell?.feedImageRetryButton.isHidden = (image != nil)
                cell?.imageContainer.stopShimmering()
            }
        }
        
        cell.onRetry = loadImage
        loadImage()
        return cell
    }
    
    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cancelTask(forRowAt: indexPath)
    }
    
    //MARK: - Helpers
    
    private func cancelTask(forRowAt indexPath: IndexPath) {
        tasks[indexPath]?.cancel()
        tasks[indexPath] = nil
    }
}

//MARK: - UITableViewDataSourcePrefetching
extension EssentialFeedController: UITableViewDataSourcePrefetching {
    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            let cellModel = tableModels[indexPath.row]
            tasks[indexPath] = imageLoader?.loadImageData(from: cellModel.image) { _ in }
        }
    }

    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach(cancelTask)
    }
}
