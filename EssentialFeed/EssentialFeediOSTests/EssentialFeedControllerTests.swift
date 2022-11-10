import XCTest
import EssentialFeed
@testable import EssentialFeediOS

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
    
    func test_loadFeedCompletion_renderSuccessfullyLoadedFeed() {
        let image0 = makeImage(description: "any_description", localtion: "any_location")
        let image1 = makeImage(description: "any_other_01_description", localtion: "any_other_01_location")
        let image2 = makeImage(description: "any_other_02_description", localtion: "any_other_02_location")
        let image3 = makeImage(description: "any_other_03_description", localtion: "any_other_03_location")
        let (sut, loader) = makeEnviroment()
        var rendeded = [FeedImage]()
        
        sut.loadViewIfNeeded()
        assertThat(sut, isRendering: rendeded)
        
        rendeded = [image0]
        loader.completes(with: rendeded, at: 0)
        assertThat(sut, isRendering: rendeded)
        
        rendeded = [image0, image1, image2, image3]
        loader.completes(with: rendeded, at: 0)
        assertThat(sut, isRendering: rendeded)
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
    
    func makeImage(description: String? = nil, localtion: String? = nil, url: URL = URL(string: "http://any-url.com")!) -> FeedImage {
        return FeedImage(id: .init(), description: description, location: localtion, url: url)
    }
    
    func assertThat(_ sut: EssentialFeedController, isRendering feed: [FeedImage], file: StaticString = #file, line: UInt = #line) {
        guard sut.numberOfRenderedFeedImageView() == feed.count else {
            return XCTFail("Expected \(feed.count) images, got \(sut.numberOfRenderedFeedImageView()) instead", file: file, line: line)
        }
        
        feed.enumerated().forEach { index, image in
            assertThat(sut, hasViewConfiguredFor: image, at: index)
        }
    }
    
    func assertThat(_ sut: EssentialFeedController, hasViewConfiguredFor image: FeedImage, at index: Int, file: StaticString = #file, line: UInt = #line) {
        let view = sut.feedImageView(at: index)
        
        guard let cell = view as? FeedImageCell else {
            return XCTFail("Expected \(FeedImageCell.self) instance, got \(String(describing: view)) instead", file: file, line: line)
        }
        
        let shouldLocaltionBeVisible = image.location != nil
        XCTAssertEqual(cell.isShowingLocation, shouldLocaltionBeVisible, "Expeceted `isShowingLocaltion` to be \(shouldLocaltionBeVisible) for image view at index (\(index))", file: file, line: line)
        
        XCTAssertEqual(cell.localtionText, image.location, "Expeceted localtion text to be \(String(describing: image.location)) for image view at index (\(index))", file: file, line: line)
        
        XCTAssertEqual(cell.descriptionText, image.description, "Expeceted image description to be \(String(describing: image.description)) for image view at index (\(index))", file: file, line: line)
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
        
        func completes(with model: [FeedImage] = [], at index: Int = 0) {
            completions[index](.success(model))
        }
    }
}

//MARK: - DSL
private extension EssentialFeedController {
    func userInitiateLoadFeed() {
        refreshControl?.simulatePullToRefresh()
    }
    
    var indicatorIsVisible: Bool { refreshControl?.isRefreshing == true }
    
    func numberOfRenderedFeedImageView() -> Int {
        return tableView.dataSource!.tableView(tableView, numberOfRowsInSection: feedImagesSection)
    }
    
    func feedImageView(at row: Int) -> UITableViewCell? {
        let dataSource = tableView.dataSource
        let index = IndexPath(row: row, section: feedImagesSection)
        return dataSource?.tableView(tableView, cellForRowAt: index)
    }
    
    private var feedImagesSection: Int {
        return 0
    }
}

private extension FeedImageCell {
    var isShowingLocation: Bool {
        return !localtionContainer.isHidden
    }
    
    var localtionText: String? {
        return localtionLabel.text
    }
    
    var descriptionText: String? {
        return descriptionLabel.text
    }
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
