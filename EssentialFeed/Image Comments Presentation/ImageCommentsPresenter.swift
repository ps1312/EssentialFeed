import Foundation

public struct ImageCommentsViewModel: Equatable {
    public let comments: [ImageCommentViewModel]

    public init(comments: [ImageCommentViewModel]) {
        self.comments = comments
    }
}

public final class ImageCommentsPresenter {
    public static var title: String {
        NSLocalizedString(
            "IMAGE_COMMENTS_VIEW_TITLE",
            tableName: "ImageComments",
            bundle: Bundle(for: Self.self),
            comment: "The image comments view screen title"
        )
    }

    public static func map(
        _ models: [ImageComment],
        locale: Locale = .current,
        calendar: Calendar = .current
    ) -> ImageCommentsViewModel {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = locale
        formatter.calendar = calendar

        return ImageCommentsViewModel(comments: models.map { comment in
            ImageCommentViewModel(
                id: comment.id,
                message: comment.message,
                username: comment.author,
                date: formatter.localizedString(for: comment.createdAt, relativeTo: Date())
            )

        })
    }
}
