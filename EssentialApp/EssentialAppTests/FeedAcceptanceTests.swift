import XCTest
import EssentialFeediOS
import EssentialFeed
@testable import EssentialApp

class FeedAcceptanceTests: XCTestCase {
    func test_feed_displaysNoFeedImagesWhenOfflineWithEmptyCache() {
        let sut = makeSUT(client: .offline, store: FeedStoreStub(feed: [.empty], images: [.empty]))

        XCTAssertFalse(sut.isShowingLoadingIndicator)
        XCTAssertEqual(sut.numberOfFeedImages, 0)
    }

    func test_feed_displaysFeedCellsWhenOnlineAndLoadsImages() {
        let data = try! JSONSerialization.data(withJSONObject: [ "items": [
            ["id": "2AB2AE66-A4B7-4A16-B374-51BBAC8DB086", "image": "http://feed.com/image-0"],
            ["id": "A28F5FE3-27A7-44E9-8DF5-53742D0E4A5A", "image": "http://feed.com/image-1"]
        ]])
        let image1 = UIImage.make(withColor: .gray).pngData()!
        let image2 = UIImage.make(withColor: .blue).pngData()!

        let sut = makeSUT(
            client: .online([
                .success((data, makeHTTPURLResponse())),
                .success((image1, makeHTTPURLResponse())), .success((image2, makeHTTPURLResponse()))]
            ),
            store: FeedStoreStub(feed: [.empty], images: [.empty, .empty])
        )

        XCTAssertFalse(sut.isShowingLoadingIndicator)
        XCTAssertEqual(sut.numberOfFeedImages, 2)

        let cell1 = sut.simulateFeedImageCellIsVisible(at: 0) as? FeedImageCell

        XCTAssertEqual(cell1?.feedImageData, image1)
        XCTAssertEqual(cell1?.isShowingLoadingIndicator, false)
        XCTAssertEqual(cell1?.isShowingRetryButton, false)

        let cell2 = sut.simulateFeedImageCellIsVisible(at: 1) as? FeedImageCell
        XCTAssertEqual(cell2?.feedImageData, image2)
        XCTAssertEqual(cell2?.isShowingLoadingIndicator, false)
        XCTAssertEqual(cell2?.isShowingRetryButton, false)
    }

    func test_feed_displaysCachedFeedWhenOffline() {
        let local = LocalFeedImage(id: UUID(), description: "a description", location: "a location", url: makeURL())
        let image = UIImage.make(withColor: .green).pngData()!
        let sut = makeSUT(
            client: .offline,
            store: FeedStoreStub(
                feed: [.found(feed: [local], timestamp: Date())],
                images: [.found(image)]
            )
        )

        let cell = sut.simulateFeedImageCellIsVisible(at: 0) as? FeedImageCell
        XCTAssertEqual(cell?.feedImageData, image)
        XCTAssertEqual(cell?.descriptionText, local.description)
        XCTAssertEqual(cell?.locationText, local.location)
    }

    func test_tapOnFeedImage_navigatesToComments() {
        let feedData = try! JSONSerialization.data(withJSONObject: [ "items": [
            ["id": "2AB2AE66-A4B7-4A16-B374-51BBAC8DB086", "image": "http://feed.com/image-0"],
        ]])
        let image1 = UIImage.make(withColor: .gray).pngData()!

        let commentsData = try! JSONSerialization.data(withJSONObject: [ "items": [
            ["id": "2AB2AE66-A4B7-4A16-B374-51BBAC8DB086",
             "message": "a message",
             "created_at": "2022-01-09T11:24:59+0000",
             "author": ["username": "a username"]
            ],
        ]])

        let sut = makeSUT(
            client: .online([
                .success((feedData, makeHTTPURLResponse())),
                .success((image1, makeHTTPURLResponse())),
                .success((commentsData, makeHTTPURLResponse()))
            ]),
            store: FeedStoreStub(feed: [.empty], images: [.empty])
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
