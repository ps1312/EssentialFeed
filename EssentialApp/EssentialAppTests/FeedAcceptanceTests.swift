import XCTest
import EssentialFeediOS
import EssentialFeed
@testable import EssentialApp

class FeedAcceptanceTests: XCTestCase {
    func test_feed_displaysNoFeedImagesWhenOfflineWithEmptyCache() {
        let sut = makeSUT(client: .offline, store: .empty(numOfImages: 1))

        XCTAssertFalse(sut.isShowingLoadingIndicator)
        XCTAssertEqual(sut.numberOfFeedImages, 0)
    }

    func test_feed_displaysFeedCellsWhenOnlineAndLoadsImages() {
        let image1Data = UIImage.make(withColor: .gray).pngData()!
        let image1JSON = makeFeedImageData(index: 1)

        let image2Data = UIImage.make(withColor: .blue).pngData()!
        let image2JSON = makeFeedImageData(index: 2)

        let image3Data = UIImage.make(withColor: .purple).pngData()!
        let image3JSON = makeFeedImageData(index: 3)

        let image4Data = UIImage.make(withColor: .cyan).pngData()!
        let image4JSON = makeFeedImageData(index: 4)

        let firstResultJSON = makeFeedData(images: [image1JSON])
        let secondResultJSON = makeFeedData(images: [image2JSON])
        let thirdResultJSON = makeFeedData(images: [image3JSON, image4JSON])
        let lastResultJSON = makeFeedData(images: [])

        let sut = makeSUT(
            client: .online([
                response(firstResultJSON), response(image1Data),
                response(secondResultJSON), response(image1Data), response(image2Data),
                response(thirdResultJSON), response(image1Data), response(image2Data), response(image3Data), response(image4Data),
                response(lastResultJSON)
            ]),
            store: .empty(numOfImages: 7)
        )

        XCTAssertFalse(sut.isShowingLoadingIndicator)
        XCTAssertEqual(sut.numberOfFeedImages, 1)
        expect(sut, toLoadImageData: image1Data, inCellAtIndex: 0)
        XCTAssertTrue(sut.canLoadMore)

        sut.simulateLoadMoreFeedImages()
        XCTAssertEqual(sut.numberOfFeedImages, 2)
        expect(sut, toLoadImageData: image1Data, inCellAtIndex: 0)
        expect(sut, toLoadImageData: image2Data, inCellAtIndex: 1)
        XCTAssertTrue(sut.canLoadMore)

        sut.simulateLoadMoreFeedImages()
        XCTAssertEqual(sut.numberOfFeedImages, 4)
        expect(sut, toLoadImageData: image1Data, inCellAtIndex: 0)
        expect(sut, toLoadImageData: image2Data, inCellAtIndex: 1)
        expect(sut, toLoadImageData: image3Data, inCellAtIndex: 2)
        expect(sut, toLoadImageData: image4Data, inCellAtIndex: 3)

        sut.simulateLoadMoreFeedImages()
        XCTAssertFalse(sut.canLoadMore)
    }

    func test_feed_displaysCachedFeedWhenOffline() {
        let local = LocalFeedImage(id: UUID(), description: "a description", location: "a location", url: makeURL())
        let image = UIImage.make(withColor: .green).pngData()!
        let sut = makeSUT(
            client: .offline,
            store: FeedStoreStub(feed: [.found(feed: [local], timestamp: Date())], images: [.found(image)])
        )

        let cell = sut.simulateFeedImageCellIsVisible(at: 0) as? FeedImageCell
        XCTAssertEqual(cell?.feedImageData, image)
        XCTAssertEqual(cell?.descriptionText, local.description)
        XCTAssertEqual(cell?.locationText, local.location)
    }

    func test_tapOnFeedImage_navigatesToComments() {
        let feedData = makeFeedData(images: [makeFeedImageData()])
        let image1 = UIImage.make(withColor: .gray).pngData()!
        let commentsData = makeCommentsData()

        let sut = makeSUT(
            client: .online([response(feedData), response(image1), response(commentsData)]),
            store: .empty(numOfImages: 1)
        )

        sut.simulateTapOnFeedImage(at: 0)
        RunLoop.current.run(until: Date())

        let currentView = sut.navigationController?.topViewController as? ListViewController
        XCTAssertEqual(currentView?.title, ImageCommentsPresenter.title)
        XCTAssertEqual(currentView?.numberOfImageComments, 1)
    }

    private func makeSUT(client: HTTPClientStub, store: FeedStoreStub) -> ListViewController {
        let sut = SceneDelegate(client: client, store: store)
        sut.window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        sut.configureView()

        let nav = sut.window?.rootViewController as! UINavigationController
        let controller = nav.topViewController as! ListViewController

        return controller
    }

    private func expect(_ sut: ListViewController, toLoadImageData imageData: Data, inCellAtIndex index: Int) {
        let cell = sut.simulateFeedImageCellIsVisible(at: index) as? FeedImageCell
        XCTAssertEqual(cell?.feedImageData, imageData)
        XCTAssertEqual(cell?.isShowingLoadingIndicator, false)
        XCTAssertEqual(cell?.isShowingRetryButton, false)
    }

    private func makeFeedData(images: Any) -> Data {
        try! JSONSerialization.data(withJSONObject: ["items": images])
    }

    private func makeFeedImageData(index: Int = 1) -> [String: Any] {
        ["id": UUID().uuidString, "image": "http://image\(index).com"]
    }

    private func makeCommentsData() -> Data {
        try! JSONSerialization.data(withJSONObject: [ "items": [
            ["id": "2AB2AE66-A4B7-4A16-B374-51BBAC8DB086",
             "message": "a message",
             "created_at": "2022-01-09T11:24:59+0000",
             "author": ["username": "a username"]
            ],
        ]])
    }

    private func response(_ data: Data) -> HTTPClientResult {
        .success((data, makeHTTPURLResponse()))
    }

    private final class HTTPClientStub: HTTPClient {
        static var offline: HTTPClientStub {
            HTTPClientStub(results: [.failure(makeNSError())])
        }

        static func online(_ results: [HTTPClientResult]) -> HTTPClientStub {
            HTTPClientStub(results: results)
        }

        private var results = [HTTPClientResult]()

        init(results: [HTTPClientResult]) {
            self.results = results
        }

        private final class Task: HTTPClientTask {
            func cancel() {}
        }

        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) -> HTTPClientTask {
            completion(results.remove(at: 0))
            return Task()
        }
    }

    private final class FeedStoreStub: FeedStore, FeedImageStore {
        static func empty(numOfImages: Int) -> FeedStoreStub {
            let images = Array(repeating: 0, count: numOfImages).map { _ in CacheImageRetrieveResult.empty }
            return FeedStoreStub(feed: [.empty], images: images)
        }

        private var feed = [CacheRetrieveResult]()
        private var images = [CacheImageRetrieveResult]()

        init(feed: [CacheRetrieveResult], images: [CacheImageRetrieveResult]) {
            self.feed = feed
            self.images = images
        }

        func delete(completion: @escaping DeletionCompletion) {}

        func persist(images: [LocalFeedImage], timestamp: Date, completion: @escaping PersistCompletion) {}

        func retrieve(completion: @escaping RetrieveCompletion) {
            completion(feed.remove(at: 0))
        }

        func retrieve(from url: URL, completion: @escaping RetrievalCompletion) {
            completion(images.remove(at: 0))
        }

        func insert(url: URL, with data: Data, completion: @escaping InsertCompletion) {}
    }
}

func makeHTTPURLResponse() -> HTTPURLResponse {
    HTTPURLResponse(url: makeURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
}
