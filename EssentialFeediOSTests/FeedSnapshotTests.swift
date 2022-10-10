import XCTest
import EssentialFeediOS

class FeedSnapshotTests: XCTestCase {

    func test_emptyFeed() {
        let sut = makeSUT()

        sut.cellControllers = emptyFeed()

        record(snapshot: sut.snapshot(), name: "EMPTY_FEED")
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
}

private extension FeedViewController {

    func snapshot() -> UIImage {
        let renderer = UIGraphicsImageRenderer(bounds: view.bounds)
        return renderer.image { action in view.layer.render(in: action.cgContext) }
    }

}
