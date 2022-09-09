import XCTest
import EssentialFeed
@testable import EssentialFeediOS

class FeedViewControllerTests: XCTestCase {

    func test_feedLoader_isCalledUponViewActions() {
        let (sut, loader) = makeSUT()

        XCTAssertEqual(loader.loadCallsCount, 0, "Feed loader should not be called on init")

        sut.loadViewIfNeeded()
        XCTAssertEqual(loader.loadCallsCount, 1, "Feed loader should be first called when view appears")

        sut.simulatePullToRefresh()
        XCTAssertEqual(loader.loadCallsCount, 2, "Feed loader should be called again after user pulls to refresh")

        sut.simulatePullToRefresh()
        XCTAssertEqual(loader.loadCallsCount, 3, "Feed loader should be called again after user pulls to refresh")
    }

    func test_loadingIndicator_isDisplayedWhileLoadingFeed() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Loading indicator should be visible when loading feed after view appear")

        loader.completeFeedLoad(at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Loading indicator should be hidden after loading completes")

        sut.simulatePullToRefresh()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Loading indicator should be visible when user executes a pull to refresh")

        loader.completeFeedLoad(at: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Loading indicator should be hidden after refresh completes")
    }

    func test_feedLoad_displaysFeedImageCellsWhenFeedLoadsWithImages() {
        let firstImage = uniqueImage()
        let lastImage = uniqueImage(description: "a description", location: "a location")
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0)

        XCTAssertEqual(sut.numberOfFeedImages, 0)

        sut.simulatePullToRefresh()
        loader.completeFeedLoad(at: 1, with: [firstImage, lastImage])

        expect(sut: sut, toLoadFeedImage: firstImage, inPosition: 0)
        expect(sut: sut, toLoadFeedImage: lastImage, inPosition: 1)
    }

    func test_refreshFailure_doesNotChangePreviouslyLoadedFeedImages() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0, with: [uniqueImage(), uniqueImage()])

        sut.simulatePullToRefresh()
        loader.completeFeedLoad(at: 1, with: makeNSError())

        XCTAssertEqual(sut.numberOfFeedImages, 2)
    }

    func test_feedLoadFailure_stopsLoadingAnimation() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0, with: makeNSError())

        XCTAssertFalse(sut.isShowingLoadingIndicator)
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: FeedViewController, loader: FeedLoaderSpy) {
        let loader = FeedLoaderSpy()
        let sut = FeedViewController(loader: loader)

        testMemoryLeak(loader, file: file, line: line)
        testMemoryLeak(sut, file: file, line: line)

        return (sut, loader)
    }

    private func expect(sut: FeedViewController, toLoadFeedImage image: FeedImage, inPosition index: Int) {
        let lastCell = sut.feedImage(at: index) as? FeedImageCell
        XCTAssertNotNil(lastCell)

        let shouldDescriptionBeHidden = image.description == nil
        XCTAssertEqual(lastCell?.isDescriptionHidden, shouldDescriptionBeHidden, "Expected cell to have a description when model has one")
        XCTAssertEqual(lastCell?.descriptionText, image.description, "Expected cell description to match model")

        let shouldLocationBeHidden = image.location == nil
        XCTAssertEqual(lastCell?.isLocationHidden, shouldLocationBeHidden, "Expected cell to have a location when model has one")
        XCTAssertEqual(lastCell?.locationText, image.location, "Expected cell location to match model")
    }

    private func uniqueImage(description: String? = nil, location: String? = nil) -> FeedImage {
        return FeedImage(id: UUID(), description: description, location: location, url: makeURL())
    }

    class FeedLoaderSpy: FeedLoader {
        var completions = [(LoadFeedResult) -> Void]()
        var loadCallsCount: Int {
            return completions.count
        }

        func load(completion: @escaping (LoadFeedResult) -> Void) {
            completions.append(completion)
        }

        func completeFeedLoad(at index: Int, with images: [FeedImage] = []) {
            completions[index](.success(images))
        }

        func completeFeedLoad(at index: Int, with error: Error) {
            completions[index](.failure(error))
        }
    }

}

private extension FeedViewController {
    var feedImagesSection: Int {
        return 0
    }

    var numberOfFeedImages: Int {
        return tableView(tableView, numberOfRowsInSection: feedImagesSection)
    }

    var isShowingLoadingIndicator: Bool {
        guard let refreshControl = refreshControl else { return false }
        return refreshControl.isRefreshing
    }

    func simulatePullToRefresh() {
        refreshControl?.allTargets.forEach { target in
            refreshControl?.actions(forTarget: target, forControlEvent: .valueChanged)?.forEach {
                (target as NSObject).perform(Selector($0))
            }
        }
    }

    func feedImage(at row: Int) -> UITableViewCell {
        let indexPath = IndexPath(row: row, section: feedImagesSection)
        return tableView(tableView, cellForRowAt: indexPath)
    }
}

private extension FeedImageCell {
    var descriptionText: String? {
        return descriptionLabel.text
    }

    var locationText: String? {
        return locationLabel.text
    }

    var isLocationHidden: Bool {
        return locationContainer.isHidden
    }

    var isDescriptionHidden: Bool {
        return descriptionLabel.isHidden
    }
}
