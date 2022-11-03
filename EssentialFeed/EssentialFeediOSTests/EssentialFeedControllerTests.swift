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
        
        loadFeed()
    }
    
    @objc private func load() {
        loadFeed()
    }
    
    //MARK: - Helpers
    private func loadFeed() {
        refreshControl?.beginRefreshing()
        loader?.load { [weak self] _ in
            self?.refreshControl?.endRefreshing()
        }
    }
}

final class EssentialFeedControllerTests: XCTestCase {

    func test_loadFeedActions_requestFeedToLoad() {
        let (sut, loader) = makeEnviroment()
        XCTAssertEqual(loader.loadCallCount, 0, "Expected no loading requests before view is loading")
        
        sut.simulateViewDidLoad()
        XCTAssertEqual(loader.loadCallCount, 1, "Expected a loading request once view is loaded")
        
        sut.userInitiateLoadFeed()
        XCTAssertEqual(loader.loadCallCount, 2, "Expected another loading request once user")
        
        sut.userInitiateLoadFeed()
        XCTAssertEqual(loader.loadCallCount, 3, "Expected a third loading request once user initiates another loader")
        
        sut.userInitiateLoadFeed()
        XCTAssertEqual(loader.loadCallCount, 4, "Expeceted a thir loading request once user initiates another load")
    }
    
    func test_viewDidLoad_showsLoadingIndicator() {
        let (sut, loader) = makeEnviroment()
        
        sut.simulateViewDidLoad()
        XCTAssertTrue(sut.indicatorIsVisible, "Expected loadinf indicator once view is loaded")
        
        sut.userInitiateLoadFeed()
        XCTAssertTrue(sut.indicatorIsVisible, "Expected loading indicator once user initiates a reload")
        
        sut.userInitiateLoadFeed()
        loader.completes(at: 0)
        XCTAssertFalse(sut.indicatorIsVisible, "Expected no loading indicator once loading is completed")
        
        sut.userInitiateLoadFeed()
        XCTAssertTrue(sut.indicatorIsVisible, "Expected loading indicator once user initiates a reload")
        
        sut.userInitiateLoadFeed()
        loader.completes(at: 1)
        XCTAssertFalse(sut.indicatorIsVisible, "Expected no loading indicator once loading is completed")
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
        
        func completes(at index: Int = 0) {
            completions[index](.success([]))
        }
    }
}

//MARK: - DSL
private extension EssentialFeedController {
    func userInitiateLoadFeed() {
        refreshControl?.simulatePullToRefresh()
    }
    
    var indicatorIsVisible: Bool { refreshControl?.isRefreshing == true }
}

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
