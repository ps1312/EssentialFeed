import XCTest
import EssentialFeed
@testable import EssentialFeediOS

class FeedViewControllerTests: XCTestCase {

    func test_feedView_hasTitle() {
        let (sut,_) = makeSUT()

        sut.loadViewIfNeeded()

        XCTAssertEqual(sut.title, "Feed")
    }

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

        loader.completeFeedLoad(at: 0, with: makeNSError())
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Loading indicator should disappear after loading completes with an error")

        sut.simulatePullToRefresh()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Loading indicator should be visible when user executes a pull to refresh")

        loader.completeFeedLoad(at: 0, with: [])
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Loading indicator should disappear after refresh completes with a success")
    }

    func test_feedLoad_displaysFeedImageCellsWhenFeedLoadsWithImages() {
        let firstImage = uniqueImage(description: nil, location: nil)
        let secondImage = uniqueImage(description: "a description", location: nil)
        let thirdImage = uniqueImage(description: nil, location: "a location")
        let lastImage = uniqueImage(description: "a description", location: "a location")

        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0, with: [])

        expect(sut, toRender: [])

        sut.simulatePullToRefresh()
        loader.completeFeedLoad(at: 1, with: [firstImage, secondImage, thirdImage, lastImage])

        expect(sut, toRender: [firstImage, secondImage, thirdImage, lastImage])

        sut.simulatePullToRefresh()
        loader.completeFeedLoad(at: 1, with: makeNSError())

        expect(sut, toRender: [firstImage, secondImage, thirdImage, lastImage])
    }

    func test_feedLoadFailure_stopsLoadingAnimation() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0, with: makeNSError())

        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected loading indicator to not be visible after loading finishes with an error")
    }

    func test_feedImageCell_requestsImageDataLoadFromURL() {
        let firstImageURL = URL(string: "https://url-1.com")!
        let firstFeedImage = uniqueImage(url: firstImageURL)

        let lastImageURL = URL(string: "https://url-2.com")!
        let secondFeedImage = uniqueImage(url: lastImageURL)

        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0, with: [firstFeedImage, secondFeedImage])
        XCTAssertEqual(loader.imageLoadedURLs, [], "Expected no loaded images until a cell is displayed")

        sut.simulateFeedImageCellIsDisplayed(at: 0)
        XCTAssertEqual(loader.imageLoadedURLs, [firstImageURL], "Expected first image to start loading after the cell is displayed")

        sut.simulateFeedImageCellIsDisplayed(at: 1)
        XCTAssertEqual(loader.imageLoadedURLs, [firstImageURL, lastImageURL], "Expected both images to start loading after cells are displayed")
    }

    func test_feedImageCell_cancelsRequestWhenFeedImageCellEndsDisplaying() {
        let firstImageURL = URL(string: "https://url-1.com")!
        let firstFeedImage = uniqueImage(url: firstImageURL)

        let lastImageURL = URL(string: "https://url-2.com")!
        let lastFeedImage = uniqueImage(url: lastImageURL)

        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0, with: [firstFeedImage, lastFeedImage])
        XCTAssertEqual(loader.canceledLoadRequests, [], "Expected no canceled downloads until a cell ends displaying")

        sut.simulateFeedImageCellEndsDiplaying(at: 0)
        XCTAssertEqual(loader.canceledLoadRequests, [firstImageURL], "Expected first image to cancel loading after the cell ends displaying")

        sut.simulateFeedImageCellEndsDiplaying(at: 1)
        XCTAssertEqual(loader.canceledLoadRequests, [firstImageURL, lastImageURL], "Expected images to cancel loading after cells ends displaying")
    }

    func test_feedImageCell_feedImageView_displaysAnIndicatorWhileLoadingData() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0, with: [uniqueImage(), uniqueImage()])

        let firstCell = sut.simulateFeedImageCellIsDisplayed(at: 0)
        let lastCell = sut.simulateFeedImageCellIsDisplayed(at: 1)

        XCTAssertTrue(firstCell.isShowingLoadingIndicator, "Expected an indicator while waiting for image load completion")
        XCTAssertTrue(lastCell.isShowingLoadingIndicator, "Expected an indicator while waiting for image load completion")

        loader.finishImageLoadingFailing(at: 0)
        XCTAssertFalse(firstCell.isShowingLoadingIndicator, "Expected no indicators after first image load completes")
        XCTAssertTrue(lastCell.isShowingLoadingIndicator, "Expected an indicator while waiting for image load completion even after first image loads")

        loader.finishImageLoadingFailing(at: 1)
        XCTAssertFalse(firstCell.isShowingLoadingIndicator, "Expected no indicators because image is already loaded")
        XCTAssertFalse(lastCell.isShowingLoadingIndicator, "Expected no indicators after second image load completes")

        firstCell.simulateImageLoadRetry()
        lastCell.simulateImageLoadRetry()
        XCTAssertTrue(firstCell.isShowingLoadingIndicator, "Expected a indicator when image is retrying to load")
        XCTAssertTrue(lastCell.isShowingLoadingIndicator, "Expected a indicator when image is retrying to load")

        loader.finishImageLoadingSuccessfully(at: 2)
        loader.finishImageLoadingSuccessfully(at: 3)
        XCTAssertFalse(firstCell.isShowingLoadingIndicator, "Expected no indicators because image loaded successfully")
        XCTAssertFalse(lastCell.isShowingLoadingIndicator, "Expected no indicators because image loaded successfully")
    }

    func test_feedImageCell_feedImageView_displaysImageDataWhenLoadSucceeds() {
        let firstImageData = UIImage.make(withColor: .green).pngData()!
        let lastImageData = UIImage.make(withColor: .blue).pngData()!

        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0, with: [uniqueImage(), uniqueImage()])

        let firstCell = sut.simulateFeedImageCellIsDisplayed(at: 0)
        let lastCell = sut.simulateFeedImageCellIsDisplayed(at: 1)
        loader.finishImageLoadingSuccessfully(at: 0, with: firstImageData)
        loader.finishImageLoadingSuccessfully(at: 1, with: lastImageData)

        XCTAssertEqual(firstCell.feedImageView.image?.pngData(), firstImageData, "Expected feed image to have loaded with the correct image data")
        XCTAssertEqual(lastCell.feedImageView.image?.pngData(), lastImageData, "Expected feed image to have loaded with the correct image data")
    }

    func test_feedImageCell_feedImageView_displaysARetryButtonWhenLoadingFails() {
        let firstImageURL = URL(string: "https://url-1.com")!
        let firstImage = uniqueImage(url: firstImageURL)
        let firstImageData = UIImage.make(withColor: .blue).pngData()!

        let lastImageURL = URL(string: "https://url-2.com")!
        let lastImage = uniqueImage(url: lastImageURL)
        let lastImageData = UIImage.make(withColor: .blue).pngData()!

        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0, with: [firstImage, lastImage])

        let firstCell = sut.simulateFeedImageCellIsDisplayed(at: 0)
        let lastCell = sut.simulateFeedImageCellIsDisplayed(at: 1)

        loader.finishImageLoadingFailing(at: 0)
        XCTAssertTrue(firstCell.isShowingRetryButton, "Expected retry button to be displayed after first cell image loading failure")

        loader.finishImageLoadingSuccessfully(at: 1, with: firstImageData)
        XCTAssertFalse(lastCell.isShowingRetryButton, "Expected retry button to remain hidden after last cell image loaded successfully")

        firstCell.simulateImageLoadRetry()
        XCTAssertEqual(loader.imageLoadedURLs, [firstImageURL, lastImageURL, firstImageURL], "Expected \(firstImageURL) to be called twice because of it's retry")

        loader.finishImageLoadingSuccessfully(at: 2, with: lastImageData)
        XCTAssertFalse(firstCell.isShowingRetryButton, "Expected retry button to be invisible after reloading first cell image successfully")
    }

    func test_feedImageCell_feedImageView_displaysARetryButtonWhenLoadedDataIsInvalid() {
        let invalidImageData = makeData()
        let validImageData = UIImage.make(withColor: .blue).pngData()!

        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0, with: [uniqueImage()])

        let firstCell = sut.simulateFeedImageCellIsDisplayed(at: 0)
        loader.finishImageLoadingSuccessfully(at: 0, with: invalidImageData)

        XCTAssertTrue(firstCell.isShowingRetryButton, "Expected retry button to be visible when loaded data is invalid")

        firstCell.simulateImageLoadRetry()
        loader.finishImageLoadingSuccessfully(at: 1, with: validImageData)

        XCTAssertFalse(firstCell.isShowingRetryButton, "Expected retry button to not be visible after retrying with valid data")
    }

    func test_feedImageCell_loadsFeedImageDataWhenPrefetching() {
        let firstImageURL = URL(string: "https://url-1.com")!
        let lastImageURL = URL(string: "https://url-2.com")!

        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0, with: [uniqueImage(url: firstImageURL), uniqueImage(url: lastImageURL)])

        sut.simulateFeedImageCellPrefetch(at: 0)
        sut.simulateFeedImageCellPrefetch(at: 1)
        XCTAssertEqual(loader.imageLoadedURLs, [firstImageURL, lastImageURL], "Expected cells to have loaded images with the correct URLs when prefetching")
    }

    func test_feedImageCell_cancelsFeedImageLoadingWhenPrefetchingIsCanceled() {
        let firstImageURL = URL(string: "https://url-1.com")!
        let lastImageURL = URL(string: "https://url-2.com")!

        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0, with: [uniqueImage(url: firstImageURL), uniqueImage(url: lastImageURL)])

        sut.simulateFeedImageCellPrefetchingCanceling(at: 0)
        sut.simulateFeedImageCellPrefetchingCanceling(at: 1)
        XCTAssertEqual(loader.canceledLoadRequests, [firstImageURL, lastImageURL], "Expected cells to cancel image loading when prefetching is canceled")
    }

    func test_feedImageCell_doesNotRenderImageWhenLoadingFinishesAfterCellGoesOffScreen() {
        let validImageData = UIImage.make(withColor: .blue).pngData()!

        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0, with: [uniqueImage()])

        let view = sut.simulateFeedImageCellEndsDiplaying(at: 0)
        loader.finishImageLoadingSuccessfully(at: 0, with: validImageData)

        XCTAssertNil(view.feedImageData)
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: FeedViewController, loader: FeedLoaderSpy) {
        let loader = FeedLoaderSpy()
        let sut = FeedUIComposer.composeWith(feedLoader: loader, imageLoader: loader)

        testMemoryLeak(loader, file: file, line: line)
        testMemoryLeak(sut, file: file, line: line)

        return (sut, loader)
    }

    private func expect(_ sut: FeedViewController, toRender expectedImages: [FeedImage], file: StaticString = #filePath, line: UInt = #line) {
        expectedImages.enumerated().forEach { index, image in expect(sut, toLoadFeedImage: image, inPosition: index, file: file, line: line) }
        XCTAssertEqual(sut.numberOfFeedImages, expectedImages.count)
    }

    private func expect(_ sut: FeedViewController, toLoadFeedImage image: FeedImage, inPosition index: Int, file: StaticString = #filePath, line: UInt = #line) {
        let cell = sut.feedImage(at: index) as! FeedImageCell
        XCTAssertNotNil(cell)

        let shouldDescriptionBeHidden = image.description == nil
        XCTAssertEqual(cell.isDescriptionHidden, shouldDescriptionBeHidden, "Expected cell to have a description when model has one", file: file, line: line)
        XCTAssertEqual(cell.descriptionText, image.description, "Expected cell description to match model", file: file, line: line)

        let shouldLocationBeHidden = image.location == nil
        XCTAssertEqual(cell.isLocationHidden, shouldLocationBeHidden, "Expected cell to have a location when model has one")
        XCTAssertEqual(cell.locationText, image.location, "Expected cell location to match model")
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

        func finishImageLoadingFailing(at index: Int) {
            imageLoadRequests[index].completion(.failure(makeNSError()))
        }

        func finishImageLoadingSuccessfully(at index: Int, with data: Data = Data()) {
            imageLoadRequests[index].completion(.success(data))
        }
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

    var feedImageData: Data? {
        return feedImageView.image?.pngData()
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
