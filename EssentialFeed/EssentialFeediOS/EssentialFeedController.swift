import UIKit
import EssentialFeed

final class EssentialFeedController: UITableViewController {
    
    //MARK: - Properites
    private var loader: IFeedLoader?
    private var tableModels = [FeedImage]()
    
    //MARK: - Initializer
    convenience init(loader: IFeedLoader) {
        self.init()
        self.loader = loader
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
        return cell
    }
    
    //MARK: - Helpers
    private func loadFeed() {
        refreshControl?.beginRefreshing()
        loader?.load { [weak self] result in
            self?.tableModels = (try? result.get()) ?? []
            self?.refreshControl?.endRefreshing()
        }
    }
    
    //MARK: - Selectors
    
    @objc private func load() {
        loadFeed()
    }
}
