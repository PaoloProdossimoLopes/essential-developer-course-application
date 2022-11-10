import UIKit
import EssentialFeed

public protocol FeedImageDataLoaderTask {
    func cancel()
}

public protocol FeedImageDataLoader {
    func loadImageData(from url: URL) -> FeedImageDataLoaderTask
}

final class EssentialFeedController: UITableViewController {
    
    //MARK: - Properites
    private var feedLoader: IFeedLoader?
    private var imageLoader: FeedImageDataLoader?
    
    private var tableModels = [FeedImage]()
    private var tasks = [IndexPath: FeedImageDataLoaderTask]()
    
    //MARK: - Initializer
    convenience init(feedLoader: IFeedLoader, imageLoader: FeedImageDataLoader) {
        self.init()
        self.feedLoader = feedLoader
        self.imageLoader = imageLoader
    }
    
    //MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = .init()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
        
        loadFeed()
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
        tasks[indexPath] = imageLoader?.loadImageData(from: model.image)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        tasks[indexPath]?.cancel()
        tasks[indexPath] = nil
    }
    
    //MARK: - Helpers
    private func loadFeed() {
        refreshControl?.beginRefreshing()
        feedLoader?.load { [weak self] result in
            
            if case let .success(model) = result {
                self?.tableModels = model
                self?.tableView.reloadData()
            }
            
            self?.refreshControl?.endRefreshing()
        }
    }
    
    //MARK: - Selectors
    
    @objc private func load() {
        loadFeed()
    }
}
