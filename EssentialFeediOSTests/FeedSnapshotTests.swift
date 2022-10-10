import XCTest
import EssentialFeed
import EssentialFeediOS

class FeedSnapshotTests: XCTestCase {

    func test_emptyFeed() {
        let sut = makeSUT()

        sut.cellControllers = emptyFeed()

        record(snapshot: sut.snapshot(), name: "EMPTY_FEED")
    }

    func test_nonEmptyFeed() {
        let sut = makeSUT()

        sut.cellControllers = nonEmptyFeed()

        record(snapshot: sut.snapshot(), name: "FEED_WITH_CONTENT")
    }

    func test_feedWithError() {
        let sut = makeSUT()

        sut.display(.error(message: "An error message\nmultiline\ntriple line"))

        record(snapshot: sut.snapshot(), name: "FEED_WITH_ERROR")
    }

    func test_feedLoadFail_displaysRetryButton() {
        let sut = makeSUT()

        sut.cellControllers = failedImageLoadFeed()

        record(snapshot: sut.snapshot(), name: "FEED_WITH_IMAGE_RETRY")
    }

    private func makeSUT() -> FeedViewController {
        let bundle = Bundle(for: FeedViewController.self)
        let storyboard = UIStoryboard(name: "Feed", bundle: bundle)
        let viewController = storyboard.instantiateInitialViewController() as! FeedViewController
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
        let delegate = FeedImageCellControllerDelegateStub(image: image, description: description, location: location)
        let controller = FeedImageCellController(delegate: delegate)
        delegate.controller = controller

        return controller
    }

    private func record(snapshot: UIImage, name: String, file: StaticString = #file, line: UInt = #line) {
        guard let snapshotData = snapshot.pngData() else {
            XCTFail("Failed to generate SUT snapshot data", file: file, line: line)
            return
        }

        let snapshotURL = URL(filePath: "\(file)").deletingLastPathComponent().appending(component: "snapshots").appending(component: "\(name).png")

        do {
            try FileManager.default.createDirectory(at: snapshotURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try snapshotData.write(to: snapshotURL)
        } catch {
            XCTFail("Failed to record snapshot image PNG", file: file, line: line)
        }
    }

    private class FeedImageCellControllerDelegateStub: FeedImageCellControllerDelegate {
        private let stubbedResult: FeedImageViewModel<UIImage>
        weak var controller: FeedImageCellController?

        init (image: UIImage?, description: String?, location: String?) {
            self.stubbedResult = FeedImageViewModel(isLoading: false, shouldRetry: image == nil, image: image, description: description, location: location)
        }

        func didRequestImageLoad() {
            controller?.display(stubbedResult)
        }

        func didCancelImageLoad() {}
    }
}

private extension FeedViewController {

    func snapshot() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        return renderer.image { action in view.layer.render(in: action.cgContext) }
    }

}
