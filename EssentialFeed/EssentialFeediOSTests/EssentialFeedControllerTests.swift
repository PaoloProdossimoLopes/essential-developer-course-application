import XCTest
import EssentialFeed
@testable import EssentialFeediOS

final class EssentialFeedControllerTests: XCTestCase {
    
    func test_feedView_hasTitle() {
        let (sut, _) = makeEnviroment()
        
        sut.loadViewIfNeeded()
        
        XCTAssertEqual(sut.title, localized("FEED_VIEW_TITLE"))
    }
    
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
        
        loader.completeFeedLoadingWithError(at: 1)
        XCTAssertFalse(sut.indicatorIsVisible, "Expected no loading indicator once loading is completed with error")
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
    
    func test_loadFeedCompletion_doesNotAlterCurrentRendeingStateOnError() {
        let image = makeImage()
        let (sut, loader) = makeEnviroment()
        
        sut.loadViewIfNeeded()
        loader.completes(with: [image])
        assertThat(sut, hasViewConfiguredFor: image, at: 0)
        
        sut.userInitiateLoadFeed()
        loader.completeFeedLoadingWithError(at: 1)
        assertThat(sut, isRendering: [image])
    }
    
    func test_feedImageView_loadsImageURLWhenVisible() {
        let image0 = makeImage(url: URL(string:"http://url-0.com")!)
        let image1 = makeImage(url: URL(string:"http://url-1.com")!)
        let (sut, feedLoader, imageLoader) = makeEnviroment()
        
        sut.loadViewIfNeeded()
        feedLoader.completes(with: [image0, image1])
        
        XCTAssertEqual(imageLoader.recievedLoadURLs, [], "Expected no images URL requests until view became visible")
        
        sut.simulateFeedImageViewVisible(at: 0)
        XCTAssertEqual(imageLoader.recievedLoadURLs, [image0.image], "Expeceted first iamge URL request once first view becames visible")
        
        sut.simulateFeedImageViewVisible(at: 1)
        XCTAssertEqual(imageLoader.recievedLoadURLs, [image0.image, image1.image], "Expeceted second iamge URL request once first view becames visible")
    }
    
    func test_feedImageView_cancelsImage_loadingWhenNotVisibleAnymore() {
        let image0 = makeImage(url: URL(string:"http://url-0.com")!)
        let image1 = makeImage(url: URL(string:"http://url-1.com")!)
        let (sut, feedLoader, imageLoader) = makeEnviroment()
        
        sut.loadViewIfNeeded()
        feedLoader.completes(with: [image0, image1])
        XCTAssertEqual(imageLoader.recievedCancelURLs, [], "Expected no images URL requests until view became visible")
        
        sut.simulateFeedImageViewNotVisible(at: 0)
        XCTAssertEqual(imageLoader.recievedCancelURLs, [image0.image], "Expeceted first iamge URL request once first view becames visible")
        
        sut.simulateFeedImageViewNotVisible(at: 1)
        XCTAssertEqual(imageLoader.recievedCancelURLs, [image0.image, image1.image], "Expeceted second iamge URL request once first view becames visible")
    }
    
    func test_feedImageViewLoadingIndicator_isVisibleWhileLoadingImage() {
        let (sut, feedLoader, imageLoader) = makeEnviroment()
        
        sut.loadViewIfNeeded()
        feedLoader.completes(with: [makeImage(), makeImage()])
        
        let view0 = sut.simulateFeedImageViewVisible(at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)
        XCTAssertEqual(view0?.isShowingImageLoadingIndicator, true, "Expected loading indicator for first view while loading first iamge")
        XCTAssertEqual(view1?.isShowingImageLoadingIndicator, true, "Expected laoding indicator for second view while loading second image")
        
        imageLoader.completeImageLoading(at: 0)
        XCTAssertEqual(view0?.isShowingImageLoadingIndicator, false, "Expected no loading indicator for frist view once first image loading completes successfully")
        XCTAssertEqual(view1?.isShowingImageLoadingIndicator, true, "Expected loading indicator for second view while loading second image")
        
        imageLoader.completeImageLoadingWithError(at: 1)
        XCTAssertEqual(view0?.isShowingImageLoadingIndicator, false, "Expected Loading indicator state change for first view once first image loading completes with error")
        XCTAssertEqual(view1?.isShowingImageLoadingIndicator, false, "Expected Loading indicator state change for second view once second image loading completes with error")
    }
    
    func test_feedImageView_rendersImageLoadedFromURL() {
        let (sut, feedLoader, imageLoader) = makeEnviroment()
        sut.loadViewIfNeeded()
        feedLoader.completes(with: [makeImage(), makeImage()])
        
        let view0 = sut.simulateFeedImageViewVisible(at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)
        XCTAssertEqual(view0?.renderedImage, .none, "Expeceted no image for first view while loading first image")
        XCTAssertEqual(view1?.renderedImage, .none, "Expeceted no image for second view while loading second image")
        
        let imageData0 = UIImage.make(withColor: .red).pngData()!
        imageLoader.completeImageLoading(with: imageData0)
        XCTAssertEqual(view0?.renderedImage, imageData0, "Expeceted image for first view once first image loading complete successfully")
        XCTAssertEqual(view1?.renderedImage, .none, "Expeceted no image state change for sencond view once first image loading completes successfully")
        
        let imageData1 = UIImage.make(withColor: .red).pngData()!
        imageLoader.completeImageLoading(with: imageData1, at: 1)
        XCTAssertEqual(view0?.renderedImage, imageData0, "Expected no image state change for first view once sencond image loading completes successfully")
        XCTAssertEqual(view1?.renderedImage, imageData1, "Expected no image state change for first view once sencond image loading completes successfully")
    }
    
    func test_feedImageViewRetryButton_isVisibleOnImageURLLoadError() {
        let (sut, feedLoader, imageLoader) = makeEnviroment()
        
        sut.loadViewIfNeeded()
        feedLoader.completes(with: [makeImage(), makeImage()])
        
        let view0 = sut.simulateFeedImageViewVisible(at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)
        XCTAssertEqual(view0?.isShowingRetryAction, false, "Expected no retry action for first view while loading first image")
        XCTAssertEqual(view1?.isShowingRetryAction, false, "Expected no retry action for second view while loading second image")
        
        let imageData = UIImage.make(withColor: .red).pngData()!
        imageLoader.completeImageLoading(with: imageData, at: 0)
        XCTAssertEqual(view0?.isShowingRetryAction, false, "Expected no retry action for first view once first image loading completes successfully")
        XCTAssertEqual(view1?.isShowingRetryAction, false, "Expected no retry action state change for second view once first image loading completes successfully")
        
        imageLoader.completeImageLoadingWithError(at: 1)
        XCTAssertEqual(view0?.isShowingRetryAction, false, "Expected no retry action state change for first view once second image loading completes with error")
        XCTAssertEqual(view1?.isShowingRetryAction, true, "Expected retry action for second view once second image loading completes with error")
    }
    
    func test_feedImageViewRetryButton_isVisibleOnValidImageData() {
        let (sut, feedLoader, imageLoader) = makeEnviroment()
        
        sut.loadViewIfNeeded()
        feedLoader.completes(with: [makeImage()])
        
        let view = sut.simulateFeedImageViewVisible(at: 0)
        XCTAssertEqual(view?.isShowingRetryAction, false, "Expeceted no retry action while loading image")
        
        let invalidImageData = Data("invalid_image_data".utf8)
        imageLoader.completeImageLoading(with: invalidImageData, at: 0)
        XCTAssertEqual(view?.isShowingRetryAction, true, "Expected retry action onde image loading completes with invalid image data")
    }
    
    func test_feedImageViewRetryAction_retriesImageLoad() {
        let image0 = makeImage(url: URL(string: "http://url-0.com")!)
        let image1 = makeImage(url: URL(string: "http://url-1.com")!)
        let (sut, feedLoader, imageLoader) = makeEnviroment()
        
        sut.loadViewIfNeeded()
        feedLoader.completes(with: [image0, image1])
        
        let view0 = sut.simulateFeedImageViewVisible(at: 0)
        let view1 = sut.simulateFeedImageViewVisible(at: 1)
        XCTAssertEqual(imageLoader.recievedLoadURLs, [image0.image, image1.image], "Expected two image URL request for the two visible views")
        
        imageLoader.completeImageLoadingWithError(at: 0)
        imageLoader.completeImageLoadingWithError(at: 1)
        XCTAssertEqual(imageLoader.recievedLoadURLs, [image0.image, image1.image], "Expected only two image URL requests before retry action")
        
        view0?.simulateRetryAction()
        XCTAssertEqual(imageLoader.recievedLoadURLs, [image0.image, image1.image, image0.image], "Expected third imageURL request after first view retry action")
        
        view1?.simulateRetryAction()
        XCTAssertEqual(imageLoader.recievedLoadURLs, [image0.image, image1.image, image0.image, image1.image], "Expected fourth imageURL request after second view retry action")
        }

        func test_feedImageView_preloadsImageURLWhenNearVisible() {
            let image0 = makeImage(url: URL(string: "http://url-0.com")!)
            let image1 = makeImage(url: URL(string: "http://url-1.com")!)
            let (sut, feedLoader, imageLoader) = makeEnviroment()

            sut.loadViewIfNeeded()
            feedLoader.completes(with: [image0, image1])
            XCTAssertEqual(imageLoader.recievedLoadURLs, [], "Expected no image URL requests until image is near visible")

            sut.simulateFeedImageViewNearVisible(at: 0)
            XCTAssertEqual(imageLoader.recievedLoadURLs, [image0.image], "Expected first image URL request once first image is near visible")

            sut.simulateFeedImageViewNearVisible(at: 1)
            XCTAssertEqual(imageLoader.recievedLoadURLs, [image0.image, image1.image], "Expected second image URL request once second image is near visible")
        }

        func test_feedImageView_cancelsImageURLPreloadingWhenNotNearVisibleAnymore() {
            let image0 = makeImage(url: URL(string: "http://url-0.com")!)
            let image1 = makeImage(url: URL(string: "http://url-1.com")!)
            let (sut, feedLoader, imageLoader) = makeEnviroment()

            sut.loadViewIfNeeded()
            feedLoader.completes(with: [image0, image1])
            XCTAssertEqual(imageLoader.recievedCancelURLs, [], "Expected no cancelled image URL requests until image is not near visible")

            sut.simulateFeedImageViewNotNearVisible(at: 0)
            XCTAssertEqual(imageLoader.recievedCancelURLs, [image0.image], "Expected first cancelled image URL request once first image is not near visible anymore")

            sut.simulateFeedImageViewNotNearVisible(at: 1)
            XCTAssertEqual(imageLoader.recievedCancelURLs, [image0.image, image1.image], "Expected second cancelled image URL request once second image is not near visible anymore")
        }
    
    func test_feedImageView_does_not_render_loaded_image_when_not_visible_anymore() {
        let (sut, feedLoader, imageLoader) = makeEnviroment()
        sut.loadViewIfNeeded()
        feedLoader.completes(with: [makeImage()])
        
        let view = sut.simulateFeedImageViewNotVisible(at: 0)
        imageLoader.completeImageLoading(with: UIImage.make(withColor: .red).pngData()!)
        XCTAssertNil(view?.renderedImage, "Expeceted no rendered image when an image load finished after the view is not visible anymore")
    }
}

//MARK: - Helpers
private extension EssentialFeedControllerTests {
    
    func localized(_ key: String, file: StaticString = #file, line: UInt = #line) -> String {
        let table = "Feed"
        let bundle = Bundle(for: EssentialFeedController.self)
        let value = bundle.localizedString(forKey: key, value: nil, table: table)
        
        if value == key {
            XCTFail("Missing localized string for key: \(key) in table: \(table)", file: file, line: line)
        }
        
        return value
    }
    
    func makeEnviroment(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: EssentialFeedController, loader: FeedLoaderSpy) {
        let feedLoader = FeedLoaderSpy()
        let feedImageLoader = FeedImageDataLoaderSpy()
        let sut = FeedUIComposer.composeWith(feedLoader: feedLoader, imageLoader: feedImageLoader)
        
        checkMemoryLeak(sut, file: file, line: line)
        checkMemoryLeak(feedLoader, file: file, line: line)
        
        return (sut, feedLoader)
    }
    
    func makeEnviroment(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: EssentialFeedController, loader: FeedLoaderSpy, imageLoader: FeedImageDataLoaderSpy) {
        let feedLoader = FeedLoaderSpy()
        let feedImageLoader = FeedImageDataLoaderSpy()
        let sut = FeedUIComposer.composeWith(feedLoader: feedLoader, imageLoader: feedImageLoader)
        
        checkMemoryLeak(sut, file: file, line: line)
        checkMemoryLeak(feedLoader, file: file, line: line)
        
        return (sut, feedLoader, feedImageLoader)
    }
    
    func makeImage(description: String? = nil, localtion: String? = nil, url: URL = URL(string: "http://any-url.com")!) -> FeedImage {
        return FeedImage(id: .init(), description: description, location: localtion, url: url)
    }
    
    func assertThat(_ sut: EssentialFeedController, isRendering feed: [FeedImage], file: StaticString = #file, line: UInt = #line) {
        guard sut.numberOfRenderedFeedImageView() == feed.count else {
            return XCTFail("Expected \(feed.count) images, got \(sut.numberOfRenderedFeedImageView()) instead", file: file, line: line)
        }
        
        feed.enumerated().forEach { index, image in
            assertThat(sut, hasViewConfiguredFor: image, at: index, file: file, line: line)
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
    
    final class FeedImageDataLoaderSpy: FeedImageDataLoader {
        
        struct TaskSpy: FeedImageDataLoaderTask {
            let cancelCallback: (() -> Void)
            func cancel() {
                cancelCallback()
            }
        }
        
        var recievedLoadURLs: [URL] {
            return imageRequests.map { $0.url }
        }
        
        private(set) var recievedCancelURLs = [URL]()
        
        private var imageRequests = [(url: URL, completion: ((FeedImageDataLoader.Result) -> Void))]()
        
        func loadImageData(from url: URL, completion: @escaping (FeedImageDataLoader.Result) -> Void) -> FeedImageDataLoaderTask {
            imageRequests.append((url, completion))
            return TaskSpy { [weak self] in self?.recievedCancelURLs.append(url) }
        }
        
        func completeImageLoading(with imageData: Data = .init(), at index: Int = 0) {
            imageRequests[index].completion(.success(imageData))
        }
        
        func completeImageLoadingWithError(at index: Int = 0) {
            let erro = NSError(domain: "any_domain", code: 0)
            imageRequests[index].completion(.failure(erro))
        }
    }
    
    final class FeedLoaderSpy: IFeedLoader {
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
        
        func completeFeedLoadingWithError(at index: Int = 0) {
            let error = NSError(domain: "any_domain", code: 0)
            completions[index](.failure(error))
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
    
    @discardableResult
    func simulateFeedImageViewVisible(at index: Int) -> FeedImageCell? {
        return feedImageView(at: index) as? FeedImageCell
    }
    
    @discardableResult
    func simulateFeedImageViewNotVisible(at row: Int) -> FeedImageCell? {
        let view = simulateFeedImageViewVisible(at: row)
        
        let delegate = tableView.delegate
        let index = IndexPath(row: row, section: feedImagesSection)
        delegate?.tableView?(tableView, didEndDisplaying: view!, forRowAt: index)
        
        return view
    }
    
    private var feedImagesSection: Int {
        return 0
    }
    
    func simulateFeedImageViewNearVisible(at row: Int) {
        let preFetchDataSource = tableView.prefetchDataSource
        let index = IndexPath(row: row, section: feedImagesSection)
        preFetchDataSource?.tableView(tableView, prefetchRowsAt: [index])
    }
    
    func simulateFeedImageViewNotNearVisible(at row: Int) {
        simulateFeedImageViewNearVisible(at: row)
        
        let prefetchDataSource = tableView.prefetchDataSource
        let index = IndexPath(row: row, section: feedImagesSection)
        prefetchDataSource?.tableView?(tableView, cancelPrefetchingForRowsAt: [index])
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
    
    var isShowingImageLoadingIndicator: Bool {
        return imageContainer.isShimerring
    }
    
    var renderedImage: Data? {
        return feedImageView.image?.pngData()
    }
    
    var isShowingRetryAction: Bool {
        return !feedImageRetryButton.isHidden
    }
    
    func simulateRetryAction() {
        feedImageRetryButton.simulateTap()
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

private extension UIButton {
    func simulateTap() {
        simulate(.touchUpInside)
    }
}

private extension UIImage {
    static func make(withColor color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(color.cgColor)
        context.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}
