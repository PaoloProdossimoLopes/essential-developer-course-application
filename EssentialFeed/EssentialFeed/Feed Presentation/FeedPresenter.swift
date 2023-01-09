import Foundation

public final class FeedPresenter {
    public static var title: String {
        NSLocalizedString(
            Constant.TITLE_KEY,
            tableName: Constant.FEED_TABLE_NAME,
            bundle: Bundle(for: FeedPresenter.self),
            comment: Constant.LOCALIZATION_DESCRIPTION)
    }
    
    private enum Constant {
        static let TITLE_KEY = "FEED_VIEW_TITLE"
        static let FEED_TABLE_NAME = "Feed"
        static let LOCALIZATION_DESCRIPTION = "Title for the feed view"
    }
}
