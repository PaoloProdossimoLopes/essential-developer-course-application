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
        loader?.load { _ in }
    }
}

final class EssentialFeedControllerTests: XCTestCase {

    func test_init_doesNotLoadFeed() {
        let (_, loader) = makeEnviroment()
        XCTAssertEqual(loader.loadCallCount, 0)
    }
    
    func test_viewDidLoad_loadsFeed() {
        let (sut, loader) = makeEnviroment()
        sut.loadViewIfNeeded()
        XCTAssertEqual(loader.loadCallCount, 1)
    }
    
    func test_pullToRefresh_loadsFeed() {
        let (sut, loader) = makeEnviroment()
        sut.loadViewIfNeeded()
        
        sut.refreshControl?.simulatePullToRefresh()
        
        XCTAssertEqual(loader.loadCallCount, 2)
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
        private(set) var loadCallCount = 0
        
        func load(completion: @escaping ((FeedResult) -> Void)) {
            loadCallCount += 1
        }
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
