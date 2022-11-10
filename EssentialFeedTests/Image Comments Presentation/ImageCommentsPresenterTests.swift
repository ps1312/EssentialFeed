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
        let testLocale = Locale(identifier: "en_US_POSIX")
        let testCalendar = Calendar(identifier: .gregorian)

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

        let viewModel = ImageCommentsPresenter.map(
            models,
            locale: testLocale,
            calendar: testCalendar
        )

        XCTAssertEqual(viewModel, ImageCommentsViewModel(comments: [
            ImageCommentViewModel(
                id: models[0].id,
                message: models[0].message,
                username: models[0].author,
                date: "5 minutes ago"
            ),
            ImageCommentViewModel(
                id: models[1].id,
                message: models[1].message,
                username: models[1].author,
                date: "1 day ago"
            )
        ]))
    }

}
