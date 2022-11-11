import XCTest
import EssentialFeediOS
import EssentialFeed
@testable import EssentialApp

class FeedAcceptanceTests: XCTestCase {
    func test_feed_displaysNoFeedImagesWhenOfflineWithEmptyCache() {
        let offline = HTTPClientStub()
        let empty = FeedStoreStub()
        let sut = SceneDelegate(client: offline, store: empty)
        sut.window = UIWindow(frame: CGRect(x: 0, y: 0, width: 1, height: 1))

        sut.configureView()

        let nav = sut.window?.rootViewController as! UINavigationController
        let feedViewController = nav.topViewController as! ListViewController

        XCTAssertFalse(feedViewController.isShowingLoadingIndicator)
        XCTAssertEqual(feedViewController.numberOfFeedImages, 0)
    }

    private final class HTTPClientStub: HTTPClient {
        private final class Task: HTTPClientTask {
            func cancel() {}
        }

        func get(from url: URL, completion: @escaping (EssentialFeed.HTTPClientResult) -> Void) -> EssentialFeed.HTTPClientTask {
            completion(.success((Data(), makeHTTPURLResponse())))
            return Task()
        }

        private func makeHTTPURLResponse() -> HTTPURLResponse {
            HTTPURLResponse(url: makeURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
        }
    }

    private final class FeedStoreStub: FeedStore, FeedImageStore {
        func delete(completion: @escaping DeletionCompletion) {}

        func persist(images: [EssentialFeed.LocalFeedImage], timestamp: Date, completion: @escaping PersistCompletion) {}

        func retrieve(completion: @escaping RetrieveCompletion) {
            completion(.empty)
        }

        func retrieve(from url: URL, completion: @escaping RetrievalCompletion) {}

        func insert(url: URL, with data: Data, completion: @escaping InsertCompletion) {}
    }
}
