import XCTest
import EssentialFeed
import EssentialFeediOS

class ImageCommentsSnapshotTests: XCTestCase {

    func test_emptyFeed() {
        let sut = makeSUT()

        sut.display(emptyFeed())

        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "EMPTY_FEED_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "EMPTY_FEED_dark")
    }

    func test_nonEmptyFeed() {
        let sut = makeSUT()

        sut.display(nonEmptyFeed())

        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "FEED_WITH_CONTENT_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "FEED_WITH_CONTENT_dark")
    }

    func test_feedWithError() {
        let sut = makeSUT()

        sut.display(.error(message: "An error message\nmultiline\ntriple line"))

        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "FEED_WITH_ERROR_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "FEED_WITH_ERROR_dark")
    }

    func test_feedLoadFail_displaysRetryButton() {
        let sut = makeSUT()

        sut.display(failedImageLoadFeed())

        assert(snapshot: sut.snapshot(for: .iPhone8(style: .light)), named: "FEED_WITH_IMAGE_RETRY_light")
        assert(snapshot: sut.snapshot(for: .iPhone8(style: .dark)), named: "FEED_WITH_IMAGE_RETRY_dark")
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

    private func emptyFeed() -> [FeedImageCellController] {
        return []
    }

    private func nonEmptyFeed() -> [FeedImageCellController] {
        let cellController1 = makeImageCellController(
            image: UIImage.make(withColor: .orange),
            description: "Mount Everest 🏔 is Earth's highest mountain above sea level, located in the Mahalangur Himal sub-range of the Himalayas. The China–Nepal border runs across its summit point. Its elevation of 8,848.86 m was most recently established in 2020 by the Chinese and Nepali authorities.",
            location: "Solukhumbu District, Province No. 1\nNepal"
        )

        let cellController2 = makeImageCellController(
            image: UIImage.make(withColor: .magenta),
            description: nil,
            location: nil
        )
        return [cellController1, cellController2]
    }

    private func failedImageLoadFeed() -> [FeedImageCellController] {
        return [makeImageCellController(image: nil, description: nil, location: "Na Chom Thian, Thailand")]
    }

    private func makeImageCellController(image: UIImage?, description: String?, location: String?) -> FeedImageCellController {
        let delegate = FeedImageCellControllerDelegateStub(image: image)
        let controller = FeedImageCellController(
            viewModel: FeedImageViewModel(description: description, location: location),
            delegate: delegate
        )
        delegate.controller = controller

        return controller
    }

    func assert(snapshot: UIImage, named: String, file: StaticString = #file, line: UInt = #line) {
        let snapshotData = makeSnapshotData(snapshot: snapshot)
        let snapshotURL = makeSnapshotURL(file: String(describing: file), name: named)

        guard let storedSnapshotData = try? Data(contentsOf: snapshotURL) else {
            XCTFail("Failed to load stored snapshot at URL: \(snapshotURL). Use the `record` method to store a snapshot before asserting.", file: file, line: line)
            return
        }

        if snapshotData != storedSnapshotData {
            let temporarySnapshotURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                .appendingPathComponent(snapshotURL.lastPathComponent)

            try? snapshotData?.write(to: temporarySnapshotURL)

            XCTFail("New snapshot does not match stored snapshot. New snapshot URL: \(temporarySnapshotURL), Stored snapshot URL: \(snapshotURL)", file: file, line: line)
        }
    }

    private func record(snapshot: UIImage, named: String, file: StaticString = #file, line: UInt = #line) {
        let snapshotData = makeSnapshotData(snapshot: snapshot)
        let snapshotURL = makeSnapshotURL(file: String(describing: file), name: named)

        do {
            try FileManager.default.createDirectory(at: snapshotURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try snapshotData?.write(to: snapshotURL)
        } catch {
            XCTFail("Failed to record snapshot image PNG", file: file, line: line)
        }
    }

    private func makeSnapshotData(snapshot: UIImage, file: StaticString = #file, line: UInt = #line) -> Data? {
        guard let snapshotData = snapshot.pngData() else {
            XCTFail("Failed to generate SUT snapshot data", file: file, line: line)
            return nil
        }
        return snapshotData
    }

    private func makeSnapshotURL(file: String, name: String) -> URL {
        return URL(filePath: "\(file)").deletingLastPathComponent().appending(component: "snapshots").appending(component: "\(name).png")
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
