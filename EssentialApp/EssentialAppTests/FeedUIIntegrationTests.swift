import XCTest
import Combine
import EssentialFeed
import EssentialFeediOS
import EssentialApp

class FeedUIIntegrationTests: XCTestCase {

    func test_feedView_hasTitle() {
        let (sut,_) = makeSUT()

        sut.loadViewIfNeeded()

        let localizedTitle = fetchLocalizedValue(table: "Feed", key: "FEED_VIEW_TITLE", inClass: FeedPresenter.self)
        XCTAssertEqual(sut.title, localizedTitle)
    }

    func test_feedLoader_isCalledUponViewActions() {
        let (sut, loader) = makeSUT()

        XCTAssertEqual(loader.loadCallsCount, 0, "Feed loader should not be called on init")

        sut.loadViewIfNeeded()
        XCTAssertEqual(loader.loadCallsCount, 1, "Feed loader should be first called when view appears")

        loader.completeFeedLoad()
        sut.simulatePullToRefresh()
        XCTAssertEqual(loader.loadCallsCount, 2, "Feed loader should be called again after user pulls to refresh")

        loader.completeFeedLoad(at: 1)
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

        loader.completeFeedLoad(at: 1, with: [])
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Loading indicator should disappear after refresh completes with a success")
    }

    func test_tapOnFeedImage_notifiesHandler() {
        let image0 = uniqueImage()
        let image1 = uniqueImage()
        var selectedImages = [FeedImage]()
        let (sut, loader) = makeSUT(onFeedImageTap: { selectedImages.append($0) })
        sut.loadViewIfNeeded()

        loader.completeFeedLoad(at: 0, with: [image0, image1])

        sut.simulateTapOnFeedImage(at: 0)
        XCTAssertEqual(selectedImages, [image0])

        sut.simulateTapOnFeedImage(at: 1)
        XCTAssertEqual(selectedImages, [image0, image1])
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
        loader.completeFeedLoad(at: 1, with: [firstImage, secondImage])
        expect(sut, toRender: [firstImage, secondImage])

        sut.simulateLoadMoreFeedImages()
        loader.completeLoadMore(with: [firstImage, secondImage, thirdImage, lastImage], lastPage: false)
        expect(sut, toRender: [firstImage, secondImage, thirdImage, lastImage])

        sut.simulateLoadMoreFeedImages()
        loader.completeLoadMoreWithError(at: 1, lastPage: true)
        expect(sut, toRender: [firstImage, secondImage, thirdImage, lastImage])

        sut.simulatePullToRefresh()
        loader.completeFeedLoad(at: 2, with: [firstImage, secondImage])
        expect(sut, toRender: [firstImage, secondImage])

        sut.simulatePullToRefresh()
        loader.completeFeedLoad(at: 3, with: makeNSError())
        expect(sut, toRender: [firstImage, secondImage])
    }

    func test_feedLoadFailure_stopsLoadingAnimation() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0, with: makeNSError())

        XCTAssertFalse(sut.isShowingLoadingIndicator, "Expected loading indicator to not be visible after loading finishes with an error")
    }

    func test_feedLoadFailure_displaysAnErrorMessage() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0, with: makeNSError())

        let localizedTitle = fetchLocalizedValue(table: "Shared", key: "GENERIC_CONNECTION_ERROR", inClass: FeedPresenter.self)
        XCTAssertEqual(sut.isShowingErrorMessage, true, "Expected error message to be displayed on feed load failure")
        XCTAssertEqual(sut.errorMessage, localizedTitle, "Expected message to be set on feed load failure")
    }

    func test_feedRefresh_hidesErrorMessage() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0, with: makeNSError())
        sut.simulatePullToRefresh()

        XCTAssertEqual(sut.isShowingErrorMessage, false, "Expected error message not to be displayed after reloading feed")
        XCTAssertEqual(sut.errorMessage, nil, "Expected message to be nil after reloading feed")
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

        sut.simulateFeedImageCellIsVisible(at: 0)
        XCTAssertEqual(loader.imageLoadedURLs, [firstImageURL], "Expected first image to start loading after the cell is displayed")

        sut.simulateFeedImageCellIsVisible(at: 1)
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

        sut.simulateFeedImageCellNotVisible(at: 0)
        XCTAssertEqual(loader.canceledLoadRequests, [firstImageURL], "Expected first image to cancel loading after the cell ends displaying")

        sut.simulateFeedImageCellNotVisible(at: 1)
        XCTAssertEqual(loader.canceledLoadRequests, [firstImageURL, lastImageURL], "Expected images to cancel loading after cells ends displaying")
    }

    func test_feedImageCell_feedImageView_displaysAnIndicatorWhileLoadingData() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0, with: [uniqueImage(), uniqueImage()])

        let firstCell = sut.simulateFeedImageCellIsVisible(at: 0) as? FeedImageCell
        let lastCell = sut.simulateFeedImageCellIsVisible(at: 1) as? FeedImageCell

        XCTAssertEqual(firstCell?.isShowingLoadingIndicator, true, "Expected an indicator while waiting for image load completion")
        XCTAssertEqual(lastCell?.isShowingLoadingIndicator, true, "Expected an indicator while waiting for image load completion")

        loader.finishImagePublisherLoadingFailing(at: 0)
        XCTAssertEqual(firstCell?.isShowingLoadingIndicator, false, "Expected no indicators after first image load completes")
        XCTAssertEqual(lastCell?.isShowingLoadingIndicator, true, "Expected an indicator while waiting for image load completion even after first image loads")

        loader.finishImagePublisherLoadingFailing(at: 1)
        XCTAssertEqual(firstCell?.isShowingLoadingIndicator, false, "Expected no indicators because image is already loaded")
        XCTAssertEqual(lastCell?.isShowingLoadingIndicator, false, "Expected no indicators after second image load completes")

        firstCell?.simulateImageLoadRetry()
        lastCell?.simulateImageLoadRetry()
        XCTAssertEqual(firstCell?.isShowingLoadingIndicator, true, "Expected a indicator when image is retrying to load")
        XCTAssertEqual(lastCell?.isShowingLoadingIndicator, true, "Expected a indicator when image is retrying to load")

        loader.finishImagePublisherLoadingSuccessfully(at: 2)
        loader.finishImagePublisherLoadingSuccessfully(at: 3)
        XCTAssertEqual(firstCell?.isShowingLoadingIndicator, false, "Expected no indicators because image loaded successfully")
        XCTAssertEqual(lastCell?.isShowingLoadingIndicator, false, "Expected no indicators because image loaded successfully")
    }

    func test_feedImageCell_feedImageView_displaysImageDataWhenLoadSucceeds() {
        let firstImageData = UIImage.make(withColor: .green).pngData()!
        let lastImageData = UIImage.make(withColor: .blue).pngData()!

        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0, with: [uniqueImage(), uniqueImage()])

        let firstCell = sut.simulateFeedImageCellIsVisible(at: 0) as! FeedImageCell
        let lastCell = sut.simulateFeedImageCellIsVisible(at: 1) as! FeedImageCell
        loader.finishImagePublisherLoadingSuccessfully(at: 0, with: firstImageData)
        loader.finishImagePublisherLoadingSuccessfully(at: 1, with: lastImageData)

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

        let firstCell = sut.simulateFeedImageCellIsVisible(at: 0) as! FeedImageCell
        let lastCell = sut.simulateFeedImageCellIsVisible(at: 1) as! FeedImageCell

        loader.finishImagePublisherLoadingFailing(at: 0)
        XCTAssertTrue(firstCell.isShowingRetryButton, "Expected retry button to be displayed after first cell image loading failure")

        loader.finishImagePublisherLoadingSuccessfully(at: 1, with: firstImageData)
        XCTAssertFalse(lastCell.isShowingRetryButton, "Expected retry button to remain hidden after last cell image loaded successfully")

        firstCell.simulateImageLoadRetry()
        XCTAssertEqual(loader.imageLoadedURLs, [firstImageURL, lastImageURL, firstImageURL], "Expected \(firstImageURL) to be called twice because of it's retry")

        loader.finishImagePublisherLoadingSuccessfully(at: 2, with: lastImageData)
        XCTAssertFalse(firstCell.isShowingRetryButton, "Expected retry button to be invisible after reloading first cell image successfully")
    }

    func test_feedImageCell_feedImageView_displaysARetryButtonWhenLoadedDataIsInvalid() {
        let invalidImageData = makeData()
        let validImageData = UIImage.make(withColor: .blue).pngData()!

        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0, with: [uniqueImage()])

        let firstCell = sut.simulateFeedImageCellIsVisible(at: 0) as! FeedImageCell
        loader.finishImagePublisherLoadingSuccessfully(at: 0, with: invalidImageData)

        XCTAssertTrue(firstCell.isShowingRetryButton, "Expected retry button to be visible when loaded data is invalid")

        firstCell.simulateImageLoadRetry()
        loader.finishImagePublisherLoadingSuccessfully(at: 1, with: validImageData)

        XCTAssertFalse(firstCell.isShowingRetryButton, "Expected retry button to not be visible after retrying with valid data")
    }

    func test_feedImageCell_loadsFeedImageDataWhenPrefetching() {
        let firstImageURL = URL(string: "https://url-1.com")!
        let lastImageURL = URL(string: "https://url-2.com")!

        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0, with: [uniqueImage(url: firstImageURL), uniqueImage(url: lastImageURL)])

        sut.simulateFeedImageCellNearVisible(at: 0)
        sut.simulateFeedImageCellNearVisible(at: 1)
        XCTAssertEqual(loader.imageLoadedURLs, [firstImageURL, lastImageURL], "Expected cells to have loaded images with the correct URLs when near visible")
    }

    func test_feedImageCell_cancelsFeedImageLoadingWhenPrefetchingIsCanceled() {
        let firstImageURL = URL(string: "https://url-1.com")!
        let lastImageURL = URL(string: "https://url-2.com")!

        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0, with: [uniqueImage(url: firstImageURL), uniqueImage(url: lastImageURL)])

        sut.simulateFeedImageCellPrefetchCancel(at: 0)
        sut.simulateFeedImageCellPrefetchCancel(at: 1)
        XCTAssertEqual(loader.canceledLoadRequests, [firstImageURL, lastImageURL], "Expected cells to cancel image loading when prefetching is canceled")
    }

    func test_feedImageCell_doesNotRenderImageWhenLoadingFinishesAfterCellGoesOffScreen() {
        let validImageData = UIImage.make(withColor: .blue).pngData()!

        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0, with: [uniqueImage()])

        let view = sut.simulateFeedImageCellNotVisible(at: 0) as! FeedImageCell
        loader.finishImagePublisherLoadingSuccessfully(at: 0, with: validImageData)

        XCTAssertNil(view.feedImageData)
    }

    func test_feedLoader_completesLoadingInMainQueue() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()

        let exp = expectation(description: "Wait for load to finish in background queue")
        DispatchQueue.global().async {
            loader.completeFeedLoad(at: 0)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_feedImageLoader_completesLoadingInMainQueue() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeFeedLoad(at: 0, with: [uniqueImage()])
        sut.simulateFeedImageCellIsVisible(at: 0)

        let exp = expectation(description: "Wait for image load to finish in background queue")
        DispatchQueue.global().async {
            loader.finishImagePublisherLoadingSuccessfully(at: 0)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_feedLoad_displaysEmptyFeedOnRefreshAfterFeedLoader() {
        let image1 = uniqueImage()
        let image2 = uniqueImage()
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()

        loader.completeFeedLoad(at: 0, with: [image1, image2])
        expect(sut, toRender: [image1, image2])

        sut.simulatePullToRefresh()
        loader.completeFeedLoad(at: 1, with: [])
        expect(sut, toRender: [])
    }

    func test_tapOnErrorView_hidesErrorMessage() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()

        loader.completeFeedLoad(at: 0, with: makeNSError())
        sut.simulateTapOnError()

        XCTAssertEqual(sut.isShowingErrorMessage, false)
    }

    func test_feedImageWillDisplay_requestsImageLoadAfterCancellingFirst() {
        let image = uniqueImage()
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()

        loader.completeFeedLoad(at: 0, with: [image])
        sut.simulateItemCellWillBecomeVisible(at: 0)

        XCTAssertEqual(loader.canceledLoadRequests, [image.url], "Expected cellForRowAt request to be cancelled after view disappears")
        XCTAssertEqual(loader.imageLoadedURLs, [image.url, image.url], "Expected image to load again after becoming visible")
    }

    func test_feedImageCell_configuresViewCorrectlyWhenCellBecomingVisibleAgain() {
        let imageData = UIImage.make(withColor: .cyan).pngData()!
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeFeedLoad(with: [uniqueImage()])

        let cell = sut.simulateItemCellWillBecomeVisible(at: 0) as? FeedImageCell
        XCTAssertEqual(cell?.isShowingLoadingIndicator, true)
        XCTAssertEqual(cell?.isShowingRetryButton, false)
        XCTAssertEqual(cell?.feedImageData, nil)

        loader.finishImagePublisherLoadingSuccessfully(at: 1, with: imageData)
        RunLoop.current.run(until: Date())
        XCTAssertEqual(cell?.isShowingLoadingIndicator, false)
        XCTAssertEqual(cell?.isShowingRetryButton, false)
        XCTAssertEqual(cell?.feedImageData, imageData)
    }

    func test_feedCell_isConfiguredCorrectlyWhenTransitioningFromPrefetchToVisibleWhileRequestingImage() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeFeedLoad(with: [uniqueImage()])

        sut.simulateItemCellWillBecomeVisible(at: 0)
        let view0 = sut.simulateFeedImageCellIsVisible(at: 0) as? FeedImageCell

        XCTAssertEqual(view0?.feedImageView.image, nil, "Expected no rendered image when view becomes visible while still preloading image")
        XCTAssertEqual(view0?.isShowingRetryButton, false, "Expected no retry action when view becomes visible while still preloading image")
        XCTAssertEqual(view0?.isShowingLoadingIndicator, true, "Expected loading indicator when view becomes visible while still preloading image")

        let imageData = UIImage.make(withColor: .red).pngData()!
        loader.finishImagePublisherLoadingSuccessfully(at: 1, with: imageData)

        XCTAssertEqual(view0?.feedImageView.image?.pngData(), imageData, "Expected rendered image after image preloads successfully")
        XCTAssertEqual(view0?.isShowingRetryButton, false, "Expected no retry action after image preloads successfully")
        XCTAssertEqual(view0?.isShowingLoadingIndicator, false, "Expected no loading indicator after image preloads successfully")
    }

    // MARK: - Load more tests
    func test_loadMore_isCalledUponLoadMoreAction() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeFeedLoad()
        XCTAssertEqual(loader.loadMoreCallCount, 0, "Expected no load more after view appears")

        sut.simulateLoadMoreFeedImages()
        XCTAssertEqual(loader.loadMoreCallCount, 1, "Expected load more after user requests to load more")

        sut.simulateLoadMoreFeedImages()
        XCTAssertEqual(loader.loadMoreCallCount, 1, "Expected still only one load more call until current request is finished")

        loader.completeLoadMore(at: 0, lastPage: false)
        sut.simulateLoadMoreFeedImages()
        XCTAssertEqual(loader.loadMoreCallCount, 2, "Expected another load more request after previous one completes and is not last page")

        loader.completeLoadMoreWithError(at: 1, lastPage: false)
        sut.simulateLoadMoreFeedImages()
        XCTAssertEqual(loader.loadMoreCallCount, 3, "Expected another load more request after previous completes with error and is not last page")

        loader.completeLoadMore(at: 2, lastPage: true)
        sut.simulateLoadMoreFeedImages()
        XCTAssertEqual(loader.loadMoreCallCount, 3, "Expected no more load more requests because it is last page")
    }

    func test_loadingMoreIndicator_isDisplayedWhileLoadingMoreFeed() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeFeedLoad()
        XCTAssertFalse(sut.isShowingLoadingMoreIndicator, "Expected no loading more indicator until user requests load more")

        sut.simulateLoadMoreFeedImages()
        XCTAssertTrue(sut.isShowingLoadingMoreIndicator, "Expected loading more indicator after user requests for more feed images")

        loader.completeLoadMore(at: 0, lastPage: false)
        XCTAssertFalse(sut.isShowingLoadingMoreIndicator, "Expected no loading more indicator after request completes with success")

        sut.simulateLoadMoreFeedImages()
        XCTAssertTrue(sut.isShowingLoadingMoreIndicator, "Expected loading more indicator after user requests for more feed images")

        loader.completeLoadMoreWithError(at: 1, lastPage: false)
        XCTAssertFalse(sut.isShowingLoadingMoreIndicator, "Expected no loading more indicator after request completes with error")

        sut.simulateLoadMoreFeedImages()
        XCTAssertTrue(sut.isShowingLoadingMoreIndicator, "Expected indicator to appear after requesting more feed images after load more failure")

        loader.completeLoadMore(at: 2, lastPage: true)
        XCTAssertFalse(sut.isShowingLoadingMoreIndicator, "Expected no loading more indicator on last page")
    }

    func test_loadMore_displaysAdditionalLoadedFeed() {
        let image1 = uniqueImage()
        let image2 = uniqueImage()
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        loader.completeFeedLoad(with: [image1])
        expect(sut, toRender: [image1])

        sut.simulateLoadMoreFeedImages()
        loader.completeLoadMore(with: [image1, image2], lastPage: false)
        expect(sut, toRender: [image1, image2])
    }

    func test_loadMoreError_isDisplayedCorrectly() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeFeedLoad()

        sut.simulateLoadMoreFeedImages()
        loader.completeLoadMoreWithError(at: 0, lastPage: false)
        XCTAssertEqual(sut.loadMoreErrorMessage, LoadResourcePresenter<Paginated<FeedImage>, FeedViewAdapter>.loadError, "Expected load more error message to appears after load more fails")

        sut.simulateLoadMoreFeedImages()
        loader.completeLoadMore(at: 1, lastPage: false)
        XCTAssertEqual(sut.loadMoreErrorMessage, nil, "Expected no load more error after user requests for more images")
    }

    func test_loadMore_completesLoadingInMainQueue() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeFeedLoad()
        sut.simulateLoadMoreFeedImages()

        let exp = expectation(description: "wait for load more to finish in main queue")
        DispatchQueue.global().async {
            loader.completeLoadMore(lastPage: true)
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_tapOnLoadMoreError_retriesLoadMore() {
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeFeedLoad()

        sut.simulateLoadMoreFeedImages()
        loader.completeLoadMoreWithError(lastPage: true)
        sut.tapOnLoadMoreError()
        XCTAssertEqual(loader.loadMoreCallCount, 2, "Expected tap on error to retry to load more")

        sut.tapOnLoadMoreError()
        XCTAssertEqual(loader.loadMoreCallCount, 2, "Expected no further load more calls until current load more completes")

        loader.completeLoadMoreWithError(at: 1, lastPage: true)
        sut.tapOnLoadMoreError()
        XCTAssertEqual(loader.loadMoreCallCount, 3, "Expected another load more call after previous one completes")
    }

    func test_feedImageCell_doesNotTriggerImageReloadWhileRequestingData() {
        let image = uniqueImage()
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeFeedLoad(with: [image])

        sut.simulateFeedImageCellNearVisible(at: 0)
        XCTAssertEqual(loader.imageLoadedURLs, [image.url], "Expected image request when view is about to appear")

        sut.simulateFeedImageCellIsVisible(at: 0)
        XCTAssertEqual(loader.imageLoadedURLs, [image.url], "Expected no image request until previous one completes")

        loader.finishImagePublisherLoadingSuccessfully(at: 0)
        sut.simulateFeedImageCellIsVisible(at: 0)
        XCTAssertEqual(loader.imageLoadedURLs, [image.url, image.url], "Expected another image request after previous one completes")
    }

    func test_loadMore_doesNotReloadAlreadyLoadedCellControllers() {
        let image1 = uniqueImage()
        let image2 = uniqueImage()
        let (sut, loader) = makeSUT()
        sut.loadViewIfNeeded()
        loader.completeFeedLoad(with: [image1])

        sut.simulateFeedImageCellIsVisible(at: 0)
        XCTAssertEqual(loader.imageLoadedURLs, [image1.url], "Expected image request when view appears")

        sut.simulateLoadMoreFeedImages()
        loader.completeLoadMore(with: [image1, image2], lastPage: true)
        sut.simulateFeedImageCellIsVisible(at: 0)
        sut.simulateFeedImageCellIsVisible(at: 1)
        XCTAssertEqual(loader.imageLoadedURLs, [image1.url, image2.url], "Expected first image to not reload after loading more")
    }

    private func makeSUT(
        onFeedImageTap: @escaping (FeedImage) -> Void = { _ in },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: ListViewController, loader: FeedLoaderSpy) {
        let loader = FeedLoaderSpy()
        let sut = FeedUIComposer.composeWith(onFeedImageTap: onFeedImageTap, loader: loader.loadPublisher, imageLoader: loader.loadImageDataPublisher)

        testMemoryLeak(loader, file: file, line: line)
        testMemoryLeak(sut, file: file, line: line)

        return (sut, loader)
    }

    private func expect(_ sut: ListViewController, toRender expectedImages: [FeedImage], file: StaticString = #filePath, line: UInt = #line) {
//        sut.tableView.layoutIfNeeded()
        RunLoop.main.run(until: Date())
        expectedImages.enumerated().forEach { index, image in
            expect(sut, toLoadFeedImage: image, inPosition: index, file: file, line: line)
        }
        XCTAssertEqual(sut.numberOfFeedImages, expectedImages.count, file: file, line: line)
    }

    private func expect(_ sut: ListViewController, toLoadFeedImage image: FeedImage, inPosition index: Int, file: StaticString = #filePath, line: UInt = #line) {
        let cell = sut.feedImageCell(at: index) as? FeedImageCell
        XCTAssertNotNil(cell)

        let shouldDescriptionBeHidden = image.description == nil
        XCTAssertEqual(cell?.isDescriptionHidden, shouldDescriptionBeHidden, "Expected cell to have a description when model has one", file: file, line: line)
        XCTAssertEqual(cell?.descriptionText, image.description, "Expected cell description to match model", file: file, line: line)

        let shouldLocationBeHidden = image.location == nil
        XCTAssertEqual(cell?.isLocationHidden, shouldLocationBeHidden, "Expected cell to have a location when model has one")
        XCTAssertEqual(cell?.locationText, image.location, "Expected cell location to match model")
    }

    private func uniqueImage(description: String? = nil, location: String? = nil, url: URL = makeURL()) -> FeedImage {
        return FeedImage(id: UUID(), description: description, location: location, url: url)
    }
}
