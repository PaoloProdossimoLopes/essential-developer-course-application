import XCTest
import EssentialFeed
//@testable import EssentialFeediOS

import UIKit
final class EssentialFeedController: UITableViewController {
    
    private var loader: IFeedLoader?
    
    convenience init(loader: IFeedLoader) {
        self.init()
        self.loader = loader
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl = .init()
        refreshControl?.addTarget(self, action: #selector(load), for: .valueChanged)
        refreshControl?.beginRefreshing()
        
        loadFeed()
    }
    
    @objc private func load() {
        loadFeed()
    }
    
    //MARK: - Helpers
    private func loadFeed() {
        loader?.load { [weak self] _ in
            self?.refreshControl?.endRefreshing()
        }
    }
}

final class EssentialFeedControllerTests: XCTestCase {

    func test_init_doesNotLoadFeed() {
        let (_, loader) = makeEnviroment()
        XCTAssertEqual(loader.loadCallCount, 0)
    }
    
    func test_viewDidLoad_loadsFeed() {
        let (sut, loader) = makeEnviroment()
        sut.simulateViewDidLoad()
        XCTAssertEqual(loader.loadCallCount, 1)
    }
    
    func test_pullToRefresh_loadsFeed() {
        let (sut, loader) = makeEnviroment()
        sut.simulateViewDidLoad()
        
        sut.refreshControl?.simulatePullToRefresh()
        XCTAssertEqual(loader.loadCallCount, 2)
        
        sut.refreshControl?.simulatePullToRefresh()
        XCTAssertEqual(loader.loadCallCount, 3)
        
        sut.refreshControl?.simulatePullToRefresh()
        XCTAssertEqual(loader.loadCallCount, 4)
    }
    
    func test_viewDidLoad_showsLoadingIndicator() {
        let (sut, _) = makeEnviroment()
        sut.simulateViewDidLoad()
        
        sut.refreshControl?.simulatePullToRefresh()
        
        XCTAssertTrue(sut.refreshControl!.isRefreshing)
    }
    
    func test_viewDidLoad_hidesIndicatorOnLoaderCompletion() {
        let (sut, loader) = makeEnviroment()
        sut.simulateViewDidLoad()
        
        sut.refreshControl?.simulatePullToRefresh()
        loader.completes()
        
        XCTAssertFalse(sut.refreshControl!.isRefreshing)
    }
}

//MARK: - Helpers
private extension EssentialFeedControllerTests {
    func makeEnviroment(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: EssentialFeedController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = EssentialFeedController(loader: loader)
        
        checkMemoryLeak(sut, file: file, line: line)
        checkMemoryLeak(loader, file: file, line: line)
        
        return (sut, loader)
    }
}

//MARK: - Doubles
private extension EssentialFeedControllerTests {
    
    final class LoaderSpy: IFeedLoader {
        private var completions = [((FeedResult) -> Void)]()
        
        var loadCallCount: Int {
            completions.count
        }
        
        func load(completion: @escaping ((FeedResult) -> Void)) {
            completions.append(completion)
        }
        
        func completes() {
            completions[0](.success([]))
        }
    }
}

//MARK: - SD
private extension UIViewController {
    func simulateViewDidLoad() {
        loadViewIfNeeded()
    }
}

private extension UIRefreshControl {
    func simulatePullToRefresh() {
        simulate(.valueChanged)
    }
}

private extension UIControl {
    func simulate(_ event: UIControl.Event) {
        allTargets.forEach { target in
            actions(forTarget: target, forControlEvent: event)?.forEach {
                let object = (target as NSObject)
                object.perform(Selector($0))
            }
        }
    }
}
