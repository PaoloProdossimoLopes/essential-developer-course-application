import Foundation

public struct ImageCommentViewModel: Hashable {
    public let message: String
    public let date: String
    public let username: String
    
    public init(message: String, date: String, username: String) {
        self.message = message
        self.date = date
        self.username = username
    }
}

public struct ImageCommentsViewModel {
    public let comments: [ImageCommentViewModel]
}

public final class ImageCommentsPresenter {
    public static var title: String {
        NSLocalizedString(Constant.COMMENT_TITLE,
                          tableName: Constant.COMMENT_TABLE_NAME,
                          bundle: Bundle(for: Self.self),
                          comment: Constant.COMMENT_TITLE_DESCRIPTION)
    }
    
    public static func map(
        _ comments: [ImageComment],
        currentDate: Date = Date(),
        calendar: Calendar = .current,
        locale: Locale = .current
    ) -> ImageCommentsViewModel {
        let formatter = RelativeDateTimeFormatter()
        formatter.calendar = calendar
        formatter.locale = locale
        
        return ImageCommentsViewModel(comments: comments.map { comment in
            ImageCommentViewModel(
                message: comment.message,
                date: formatter.localizedString(for: comment.createdAt, relativeTo: currentDate),
                username: comment.username)
        })
    }
    
    private enum Constant {
        static let COMMENT_TITLE = "IMAGE_COMMENTS_VIEW_TITLE"
        static let COMMENT_TABLE_NAME = "ImageComments"
        static let COMMENT_TITLE_DESCRIPTION = "Title for the image comments view"
    }
}
