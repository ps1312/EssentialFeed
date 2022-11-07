import XCTest
import EssentialFeed
import EssentialFeediOS

class ImageCommentsSnapshotTests: XCTestCase {

    func test_nonEmptyComments() {
        let sut = makeSUT()

        sut.cellControllers = nonEmptyComments()

        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "IMAGE_COMMENTS_WITH_CONTENT_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "IMAGE_COMMENTS_WITH_CONTENT_dark")
    }

    private func makeSUT() -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyboard = UIStoryboard(name: "ImageComments", bundle: bundle)
        let viewController = storyboard.instantiateInitialViewController() as! ListViewController
        viewController.tableView.showsVerticalScrollIndicator = false
        viewController.tableView.showsHorizontalScrollIndicator = false
        viewController.loadViewIfNeeded()
        return viewController
    }

    private func nonEmptyComments() -> [CellController] {
        [
            makeImageCommentCellController(
                message: "Lorem",
                username: "a username",
                date: "1 day ago"
            ),
        ].map { CellController($0) }
    }

    private func makeImageCommentCellController(message: String, username: String, date: String) -> ImageCommentCellController {
        let viewModel = ImageCommentViewModel(message: message, username: username, date: date)
        return ImageCommentCellController(viewModel: viewModel)
    }
}
