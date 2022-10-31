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

    public static func map(_ models: [ImageComment]) -> ImageCommentsViewModel {
        let relativeFormatter = RelativeDateTimeFormatter()

        return ImageCommentsViewModel(comments: models.map { comment in
            ImageCommentViewModel(
                message: comment.message,
                username: comment.author,
                date: relativeFormatter.localizedString(for: comment.createdAt, relativeTo: Date())
            )

        })
    }
}
