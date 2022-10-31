import XCTest
import EssentialFeed

class ImageCommentsPresenterTests: XCTestCase {

    func test_title_isLocalized() {
        let expectedKey = "IMAGE_COMMENTS_VIEW_TITLE"
        let expectedTitle = localized(key: expectedKey, in: "ImageComments")

        XCTAssertNotEqual(ImageCommentsPresenter.title, expectedKey)
        XCTAssertEqual(ImageCommentsPresenter.title, expectedTitle)
    }

    func test_map_createsViewModel() {
        let now = Date()
        let models = [
            ImageComment(
                id: UUID(),
                message: "a message",
                createdAt: now.adding(minutes: -5),
                author: "an author"
            ),
            ImageComment(
                id: UUID(),
                message: "another message",
                createdAt: now.adding(days: -1),
                author: "another author"
            ),
        ]

        let viewModel = ImageCommentsPresenter.map(models)

        XCTAssertEqual(viewModel, ImageCommentsViewModel(comments: [
            ImageCommentViewModel(
                message: "a message",
                username: "an author",
                date: "5 minutes ago"
            ),
            ImageCommentViewModel(
                message: "another message",
                username: "another author",
                date: "1 day ago"
            )
        ]))
    }

}
