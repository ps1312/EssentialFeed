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
        refreshControl?.beginRefreshing()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }

    @objc func refresh() {
        loader?.load { _ in
            self.refreshControl?.endRefreshing()
        }
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

    func test_loadingIndicator_isVisibleWhileLoadingFeed() {
        let loader = FeedLoaderSpy()
        let sut = FeedViewController(loader: loader)

        sut.loadViewIfNeeded()
        XCTAssertEqual(sut.refreshControl?.isRefreshing, true)

        loader.completeFeedLoad()
        XCTAssertEqual(sut.refreshControl?.isRefreshing, false)
    }

    class FeedLoaderSpy: FeedLoader {
        var completions = [(LoadFeedResult) -> Void]()
        var loadCallsCount: Int {
            return completions.count
        }

        func load(completion: @escaping (LoadFeedResult) -> Void) {
            completions.append(completion)
        }

        func completeFeedLoad() {
            completions[0](.success([]))
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
