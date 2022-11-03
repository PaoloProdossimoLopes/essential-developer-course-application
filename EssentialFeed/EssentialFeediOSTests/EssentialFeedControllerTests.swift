import XCTest
import EssentialFeed
//@testable import EssentialFeediOS

import UIKit
final class EssentialFeedController: UIViewController {
    
    private var loader: IFeedLoader?
    
    convenience init(loader: IFeedLoader) {
        self.init()
        self.loader = loader
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
}

private extension EssentialFeedControllerTests {
    func makeEnviroment() -> (sut: EssentialFeedController, loader: LoaderSpy) {
        let loader = LoaderSpy()
        let sut = EssentialFeedController(loader: loader)
        return (sut, loader)
    }
}

private extension EssentialFeedControllerTests {
    
    final class LoaderSpy: IFeedLoader {
        private(set) var loadCallCount = 0
        
        func load(completion: @escaping ((FeedResult) -> Void)) {
            loadCallCount += 1
        }
    }
}
