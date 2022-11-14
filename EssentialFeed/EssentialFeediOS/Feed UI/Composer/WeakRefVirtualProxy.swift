import Foundation

final class WeakRefVirtualProxy<T: AnyObject> {
    private weak var object: T?
    
    init(_ object: T) {
        self.object = object
    }
}

extension WeakRefVirtualProxy: IFeedLoadingView where T: IFeedLoadingView {
    func display(_ model: PresentableLoadingModel) {
        object?.display(model)
    }
}

extension WeakRefVirtualProxy: FeedImageCellLoadViewProtocol where T: FeedImageCellLoadViewProtocol {
    func display(model: FeedImagePresentableModel) {
        object?.display(model: model)
    }
}
