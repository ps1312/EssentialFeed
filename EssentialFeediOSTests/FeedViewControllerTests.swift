import XCTest

class FeedViewController {}

class FeedViewControllerTests: XCTestCase {

    func test_init_doesLoadFeed() {
        let loader = FeedLoaderSpy()
        let _ = FeedViewController()

        XCTAssertEqual(loader.loadCallsCount, 0)
    }

    class FeedLoaderSpy {
        var loadCallsCount = 0
    }

}
