import XCTest
import EssentialFeed
import EssentialFeediOS

class FeedSnapshotTests: XCTestCase {
    func test_nonEmptyFeed() {
        let sut = makeSUT()

        sut.cellControllers = nonEmptyFeed()

        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "FEED_WITH_CONTENT_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "FEED_WITH_CONTENT_dark")
    }

    func test_feedLoadFail_displaysRetryButton() {
        let sut = makeSUT()

        sut.cellControllers = failedImageLoadFeed()

        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "FEED_WITH_IMAGE_RETRY_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "FEED_WITH_IMAGE_RETRY_dark")
    }

    private func makeSUT() -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let viewController = storyboard.instantiateInitialViewController() as! ListViewController
        viewController.tableView.showsVerticalScrollIndicator = false
        viewController.tableView.showsHorizontalScrollIndicator = false
        viewController.loadViewIfNeeded()
        return viewController
    }

    private func nonEmptyFeed() -> [CellController] {
        [
            makeImageCellController(
                image: UIImage.make(withColor: .orange),
                description: "Mount Everest 🏔 is Earth's highest mountain above sea level, located in the Mahalangur Himal sub-range of the Himalayas. The China–Nepal border runs across its summit point. Its elevation of 8,848.86 m was most recently established in 2020 by the Chinese and Nepali authorities.",
                location: "Solukhumbu District, Province No. 1\nNepal"
            ),
            makeImageCellController(
                image: UIImage.make(withColor: .magenta),
                description: nil,
                location: nil
            )
        ].map { CellController(id: UUID(), $0) }
    }

    private func failedImageLoadFeed() -> [CellController] {
        let controller = makeImageCellController(image: nil, description: nil, location: "Na Chom Thian, Thailand")
        return [CellController(id: UUID(), controller)]
    }

    private func makeImageCellController(image: UIImage?, description: String?, location: String?) -> FeedImageCellController {
        let delegate = FeedImageCellControllerDelegateStub(image: image)
        let controller = FeedImageCellController(
            selected: {},
            viewModel: FeedImageViewModel(description: description, location: location),
            delegate: delegate
        )
        delegate.controller = controller

        return controller
    }

    private class FeedImageCellControllerDelegateStub: FeedImageCellControllerDelegate {
        private let image: UIImage?

        weak var controller: FeedImageCellController?

        init (image: UIImage?) {
            self.image = image
        }

        func didRequestImageLoad() {
            controller?.display(ResourceLoadingViewModel(isLoading: true))

            if let image = image {
                controller?.display(image)
                controller?.display(ResourceErrorViewModel(message: .none))
            } else {
                controller?.display(ResourceErrorViewModel(message: "any"))
            }

            controller?.display(ResourceLoadingViewModel(isLoading: false))
        }

        func didCancelImageLoad() {}
    }
}
