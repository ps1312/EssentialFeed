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

        expect(sut, toRender: [])

        sut.simulatePullToRefresh()
        loader.completeFeedLoad(at: 1, with: [firstImage, lastImage])

        expect(sut, toRender: [firstImage, lastImage])

        sut.simulatePullToRefresh()
        loader.completeFeedLoad(at: 1, with: makeNSError())

        expect(sut, toRender: [firstImage, lastImage])
    }

    func test_feedLoadFailure_stopsLoadingAnimation() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0, with: makeNSError())

        XCTAssertFalse(sut.isShowingLoadingIndicator)
    }

    func test_feedImage_requestsImageDataFromURL() {
        let firstImageURL = URL(string: "https://url-1.com")!
        let firstFeedImage = uniqueImage(url: firstImageURL)

        let lastImageURL = URL(string: "https://url-2.com")!
        let secondFeedImage = uniqueImage(url: lastImageURL)

        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0, with: [firstFeedImage, secondFeedImage])
        XCTAssertEqual(loader.imageLoadedURLs, [], "Expected no loaded images until a cell is displayed")

        sut.displayFeedImageCell(at: 0)
        XCTAssertEqual(loader.imageLoadedURLs, [firstImageURL], "Expected first image to start loading after the cell is displayed")

        sut.displayFeedImageCell(at: 1)
        XCTAssertEqual(loader.imageLoadedURLs, [firstImageURL, lastImageURL], "Expected images to start loading after cells are displayed")
    }

    func test_feedImageLoading_cancelsRequestWhenFeedImageCellGoesOffScreen() {
        let firstImageURL = URL(string: "https://url-1.com")!
        let firstFeedImage = uniqueImage(url: firstImageURL)

        let lastImageURL = URL(string: "https://url-2.com")!
        let lastFeedImage = uniqueImage(url: lastImageURL)

        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0, with: [firstFeedImage, lastFeedImage])
        XCTAssertEqual(loader.canceledLoadRequests, [], "Expected no canceled downloads until a cell ends displaying")

        sut.endFeedImageCellDiplay(at: 0)
        XCTAssertEqual(loader.canceledLoadRequests, [firstImageURL], "Expected first image to cancel loading after the cell ends displaying")

        sut.endFeedImageCellDiplay(at: 1)
        XCTAssertEqual(loader.canceledLoadRequests, [firstImageURL, lastImageURL], "Expected images to cancel loading after cells ends displaying")
    }

    func test_feedImage_displaysAnIndicatorWhileLoadingData() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0, with: [uniqueImage(), uniqueImage()])

        let firstCell = sut.displayFeedImageCell(at: 0)
        let lastCell = sut.displayFeedImageCell(at: 1)

        XCTAssertEqual(firstCell?.isShowingLoadingIndicator, true, "Expected an indicator while waiting for image load completion")
        XCTAssertEqual(lastCell?.isShowingLoadingIndicator, true, "Expected an indicator while waiting for image load completion")

        loader.finishImageLoading(at: 0)
        XCTAssertEqual(firstCell?.isShowingLoadingIndicator, false, "Expected no indicators after first image load completes")
        XCTAssertEqual(lastCell?.isShowingLoadingIndicator, true, "Expected an indicator while waiting for image load completion even after first image loads")

        loader.finishImageLoading(at: 1)
        XCTAssertEqual(firstCell?.isShowingLoadingIndicator, false, "Expected no indicators because image is already loaded")
        XCTAssertEqual(lastCell?.isShowingLoadingIndicator, false, "Expected no indicators after second image load completes")

        firstCell?.simulateImageLoadRetry()
        lastCell?.simulateImageLoadRetry()
        XCTAssertEqual(firstCell?.isShowingLoadingIndicator, true, "Expected a indicator when image is retrying to load")
        XCTAssertEqual(lastCell?.isShowingLoadingIndicator, true, "Expected a indicator when image is retrying to load")

        loader.finishImageLoadingSuccessfully(at: 2)
        loader.finishImageLoadingSuccessfully(at: 3)
        XCTAssertEqual(firstCell?.isShowingLoadingIndicator, false, "Expected no indicators because image loaded successfully")
        XCTAssertEqual(lastCell?.isShowingLoadingIndicator, false, "Expected no indicators because image loaded successfully")

    }

    func test_feedImage_displaysARetryButtonWhenLoadingFails() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0, with: [uniqueImage(), uniqueImage()])

        let firstCell = sut.displayFeedImageCell(at: 0)
        let lastCell = sut.displayFeedImageCell(at: 1)

        loader.finishImageLoading(at: 0)
        loader.finishImageLoadingSuccessfully(at: 1)

        XCTAssertEqual(firstCell?.isShowingRetryButton, true, "Expected retry button to be displayed after loading failure")
        XCTAssertEqual(lastCell?.isShowingRetryButton, false, "Expected retry button to remain invisible after successfully load")

        firstCell?.simulateImageLoadRetry()
        loader.finishImageLoadingSuccessfully(at: 2)

        XCTAssertEqual(firstCell?.isShowingRetryButton, false, "Expected retry button to be invisible after reloading successfully")
    }

    func test_feedImage_shouldDisplayImageOnLoadSccess() {
        let firstImageData = UIImage.make(withColor: .green).pngData()!
        let lastImageData = UIImage.make(withColor: .blue).pngData()!

        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0, with: [uniqueImage(), uniqueImage()])

        let firstCell = sut.displayFeedImageCell(at: 0)
        let lastCell = sut.displayFeedImageCell(at: 0)
        loader.finishImageLoadingSuccessfully(at: 0, with: firstImageData)
        loader.finishImageLoadingSuccessfully(at: 1, with: lastImageData)

        XCTAssertEqual(firstCell?.feedImageView.image?.pngData(), firstImageData)
        XCTAssertEqual(lastCell?.feedImageView.image?.pngData(), lastImageData)
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: FeedViewController, loader: FeedLoaderSpy) {
        let loader = FeedLoaderSpy()
        let sut = FeedViewController(feedLoader: loader, imageLoader: loader)

        testMemoryLeak(loader, file: file, line: line)
        testMemoryLeak(sut, file: file, line: line)

        return (sut, loader)
    }

    private func expect(_ sut: FeedViewController, toRender expectedImages: [FeedImage]) {
        expectedImages.enumerated().forEach { index, image in expect(sut, toLoadFeedImage: image, inPosition: index) }
        XCTAssertEqual(sut.numberOfFeedImages, expectedImages.count)
    }

    private func expect(_ sut: FeedViewController, toLoadFeedImage image: FeedImage, inPosition index: Int) {
        let cell = sut.feedImage(at: index) as? FeedImageCell
        XCTAssertNotNil(cell)

        let shouldDescriptionBeHidden = image.description == nil
        XCTAssertEqual(cell?.isDescriptionHidden, shouldDescriptionBeHidden, "Expected cell to have a description when model has one")
        XCTAssertEqual(cell?.descriptionText, image.description, "Expected cell description to match model")

        let shouldLocationBeHidden = image.location == nil
        XCTAssertEqual(cell?.isLocationHidden, shouldLocationBeHidden, "Expected cell to have a location when model has one")
        XCTAssertEqual(cell?.locationText, image.location, "Expected cell location to match model")
    }

    private func uniqueImage(description: String? = nil, location: String? = nil, url: URL = makeURL()) -> FeedImage {
        return FeedImage(id: UUID(), description: description, location: location, url: url)
    }

    class FeedLoaderSpy: FeedLoader, FeedImageLoader {
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

        // MARK: - FeedImageLoaderSpy

        var imageLoadRequests = [(url: URL, completion: (FeedImageLoader.Result) -> Void)]()
        var imageLoadedURLs: [URL] { return imageLoadRequests.map { $0.url } }
        var canceledLoadRequests = [URL]()

        private struct TaskSpy: FeedImageLoaderTask {
            let cancelCallback: () -> Void

            func cancel() {
                cancelCallback()
            }
        }

        func load(from url: URL, completion: @escaping (FeedImageLoader.Result) -> Void) -> FeedImageLoaderTask {
            imageLoadRequests.append((url, completion))

            let task = TaskSpy(cancelCallback: { [weak self] in
                self?.canceledLoadRequests.append(url)
            })

            return task
        }

        func finishImageLoading(at index: Int) {
            imageLoadRequests[index].completion(.failure(makeNSError()))
        }

        func finishImageLoadingSuccessfully(at index: Int, with data: Data = Data()) {
            imageLoadRequests[index].completion(.success(data))
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

    @discardableResult
    func displayFeedImageCell(at row: Int) -> FeedImageCell? {
        return feedImage(at: row) as? FeedImageCell
    }

    func endFeedImageCellDiplay(at row: Int) {
        let indexPath = IndexPath(row: row, section: feedImagesSection)
        let currentCell = displayFeedImageCell(at: row)!
        tableView(tableView, didEndDisplaying: currentCell, forRowAt: indexPath)
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

    var isShowingLoadingIndicator: Bool {
        return imageContainer.isShimmering
    }

    var isShowingRetryButton: Bool {
        return !retryButton.isHidden
    }

    func simulateImageLoadRetry() {
        retryButton.allTargets.forEach { target in
            retryButton.actions(forTarget: target, forControlEvent: .touchUpInside)?.forEach {
                (target as NSObject).perform(Selector($0))
            }
        }
    }
}

private extension UIImage {
    static func make(withColor color: UIColor) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: 1, height: 1)
        UIGraphicsBeginImageContext(rect.size)
        let context = UIGraphicsGetCurrentContext()!
        context.setFillColor(color.cgColor)
        context.fill(rect)
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img!
    }
}
