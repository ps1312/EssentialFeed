import XCTest
import EssentialFeed

class FeedViewController: UITableViewController {
    private var loader: FeedLoader?

    convenience init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }

    override func viewDidLoad() {
        refresh()

        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }

    @objc func refresh() {
        loader?.load { _ in }
    }

}

class FeedViewControllerTests: XCTestCase {

    func test_init_doesLoadFeed() {
        let loader = FeedLoaderSpy()
        let _ = FeedViewController(loader: loader)

        XCTAssertEqual(loader.loadCallsCount, 0)
    }

    func test_viewDidLoad_loadsFeed() {
        let loader = FeedLoaderSpy()
        let sut = FeedViewController(loader: loader)

        sut.loadViewIfNeeded()

        XCTAssertEqual(loader.loadCallsCount, 1)
    }

    func test_pullToRefresh_reloadsFeed() {
        let loader = FeedLoaderSpy()
        let sut = FeedViewController(loader: loader)

        sut.loadViewIfNeeded()

        sut.simulatePullToRefresh()

        XCTAssertEqual(loader.loadCallsCount, 2)
    }

    class FeedLoaderSpy: FeedLoader {
        var loadCallsCount = 0

        func load(completion: @escaping (LoadFeedResult) -> Void) {
            loadCallsCount += 1
        }
    }

}

private extension FeedViewController {
    func simulatePullToRefresh() {
        refreshControl?.allTargets.forEach { target in
            refreshControl?.actions(forTarget: target, forControlEvent: .valueChanged)?.forEach {
                (target as NSObject).perform(Selector($0))
            }
        }
    }
}
