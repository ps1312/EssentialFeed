import XCTest
import EssentialFeediOS
import EssentialFeed
@testable import EssentialApp

class FeedAcceptanceTests: XCTestCase {
    func test_feed_displaysNoFeedImagesWhenOfflineWithEmptyCache() {
        let offline = HTTPClientStub()
        offline.result = .failure(makeNSError())
        let empty = FeedStoreStub()
        let sut = SceneDelegate(client: offline, store: empty)
        sut.window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1, height: 1))

        sut.configureView()

        let nav = sut.window?.rootViewController as! UINavigationController
        let feedViewController = nav.topViewController as! ListViewController

        XCTAssertFalse(feedViewController.isShowingLoadingIndicator)
        XCTAssertEqual(feedViewController.numberOfFeedImages, 0)
    }

    func test_feed_displaysFeedCellsWhenOnlineAndLoadsImages() {
        let data = try! JSONSerialization.data(withJSONObject: [ "items": [
            ["id": "2AB2AE66-A4B7-4A16-B374-51BBAC8DB086", "image": "http://feed.com/image-0"],
            ["id": "A28F5FE3-27A7-44E9-8DF5-53742D0E4A5A", "image": "http://feed.com/image-1"]
        ]])

        let online = HTTPClientStub()
        online.result = .success((data, makeHTTPURLResponse()))

        let empty = FeedStoreStub()

        let sut = SceneDelegate(client: online, store: empty)
        sut.window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1, height: 1))

        sut.configureView()

        let nav = sut.window?.rootViewController as! UINavigationController
        let feedViewController = nav.topViewController as! ListViewController

        XCTAssertFalse(feedViewController.isShowingLoadingIndicator)
        XCTAssertEqual(feedViewController.numberOfFeedImages, 2)

        let image1 = UIImage.make(withColor: .gray).pngData()!
        online.result = .success((image1, makeHTTPURLResponse()))

        let cell1 = feedViewController.simulateFeedImageCellIsVisible(at: 0) as? FeedImageCell

        XCTAssertEqual(cell1?.feedImageData, image1)
        XCTAssertEqual(cell1?.isShowingLoadingIndicator, false)
        XCTAssertEqual(cell1?.isShowingRetryButton, false)
    }

    private final class HTTPClientStub: HTTPClient {
        var result: HTTPClientResult?

        private final class Task: HTTPClientTask {
            func cancel() {}
        }

        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) -> HTTPClientTask {
            if let result = result {
                completion(result)
            }
            return Task()
        }
    }

    private final class FeedStoreStub: FeedStore, FeedImageStore {
        func delete(completion: @escaping DeletionCompletion) {}

        func persist(images: [LocalFeedImage], timestamp: Date, completion: @escaping PersistCompletion) {}

        func retrieve(completion: @escaping RetrieveCompletion) {
            completion(.empty)
        }

        func retrieve(from url: URL, completion: @escaping RetrievalCompletion) {
            completion(.empty)
        }

        func insert(url: URL, with data: Data, completion: @escaping InsertCompletion) {}
    }
}

func makeHTTPURLResponse() -> HTTPURLResponse {
    HTTPURLResponse(url: makeURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
}
