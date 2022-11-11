import XCTest
import EssentialFeediOS
import EssentialFeed
@testable import EssentialApp

class FeedAcceptanceTests: XCTestCase {
    func test_feed_displaysNoFeedImagesWhenOfflineWithEmptyCache() {
        let offline = HTTPClientStub(results: [.failure(makeNSError())])
        let sut = makeSUT(client: offline, store: FeedStoreStub())

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

        let online = HTTPClientStub(results: [
            .success((data, makeHTTPURLResponse())),
            .success((image1, makeHTTPURLResponse())),
            .success((image2, makeHTTPURLResponse()))
        ])
        let sut = makeSUT(client: online, store: FeedStoreStub())

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

    private func makeSUT(client: HTTPClientStub, store: FeedStoreStub) -> ListViewController {
        let sut = SceneDelegate(client: client, store: store)
        sut.window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1, height: 1))
        sut.configureView()

        let nav = sut.window?.rootViewController as! UINavigationController
        let controller = nav.topViewController as! ListViewController

        return controller
    }

    private final class HTTPClientStub: HTTPClient {
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
