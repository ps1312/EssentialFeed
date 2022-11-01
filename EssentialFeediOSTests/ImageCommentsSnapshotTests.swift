import XCTest
import EssentialFeed
import EssentialFeediOS

class ImageCommentsSnapshotTests: XCTestCase {

    func test_emptyComments() {
        let sut = makeSUT()

        sut.display(emptyComments())

        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "EMPTY_IMAGE_COMMENTS_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "EMPTY_IMAGE_COMMENTS_dark")
    }

    func test_nonEmptyComments() {
        let sut = makeSUT()

        sut.display(nonEmptyComments())

        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "IMAGE_COMMENTS_WITH_CONTENT_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "IMAGE_COMMENTS_WITH_CONTENT_dark")
    }

    func test_withError() {
        let sut = makeSUT()

        sut.display(.error(message: "An error message\nmultiline\ntriple line"))

        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "IMAGE_COMMENTS_WITH_ERROR_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "IMAGE_COMMENTS_WITH_ERROR_dark")
    }

    private func makeSUT() -> ImageCommentsViewController {
        let bundle = Bundle(for: ImageCommentsViewController.self)
        let storyboard = UIStoryboard(name: "ImageComments", bundle: bundle)
        let viewController = storyboard.instantiateInitialViewController() as! ImageCommentsViewController
        viewController.tableView.showsVerticalScrollIndicator = false
        viewController.tableView.showsHorizontalScrollIndicator = false
        viewController.loadViewIfNeeded()
        return viewController
    }

    private func emptyComments() -> [ImageCommentCellController] {
        return []
    }

    private func nonEmptyComments() -> [ImageCommentCellController] {
        let cellController1 = makeImageCommentCellController(
            message: "Lorem Ipsum is simply dummy text of the printing and typesetting industry. Lorem Ipsum has been the industry's standard dummy text ever since the 1500s. 🔥",
            username: "a username",
            date: "1 day ago"
        )

        let cellController2 = makeImageCommentCellController(
            message: """
            It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker including versions of Lorem Ipsum. 🗿
            .
            .
            .
            .
            loremipsum Letraset desktop ✅
            """,
            username: "another username",
            date: "2 weeks ago"
        )
        return [cellController1, cellController2]
    }

    private func makeImageCommentCellController(message: String, username: String, date: String) -> ImageCommentCellController {
        let viewModel = ImageCommentViewModel(message: message, username: username, date: date)
        return ImageCommentCellController(viewModel: viewModel)
    }
}