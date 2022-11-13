import Foundation
import EssentialFeed

struct PresentableLoadingModel {
    let isLoading: Bool
}

struct PresentableDataModel {
    let feed: [FeedImage]
}

protocol IFeedLoadingView {
    func display(_ model: PresentableLoadingModel)
}

protocol IFeedPresentationView {
    func display(_ model: PresentableDataModel)
}

protocol IFeedRefreshPresenter {
    func load()
}

final class FeedPresenter {
    
    //MARK: - Propeties
    
    var viewLoading: IFeedLoadingView?
    var viewPresent: IFeedPresentationView?
    
    static var title: String {
        return NSLocalizedString(
            "FEED_VIEW_TITLE",
            tableName: "Feed",
            bundle: .init(for: FeedPresenter.self),
            comment: "Title for the FeedView"
        )
    }
    
    //MARK: - Methods
    
    func didStartLoadingFeed() {
        viewLoading?.display(PresentableLoadingModel(isLoading: true))
    }
    
    func didFinishLoadingFeed(with feed: [FeedImage]) {
        viewPresent?.display(PresentableDataModel(feed: feed))
        viewLoading?.display(PresentableLoadingModel(isLoading: false))
    }
    
    func didFinishLoadingFailure() {
        viewLoading?.display(PresentableLoadingModel(isLoading: false))
    }
}

//MARK: - FeedViewModel+State
private extension FeedViewModel {
    enum State {
        case pending
        case loading
    }
}
