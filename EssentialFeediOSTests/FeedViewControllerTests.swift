import XCTest
import EssentialFeed

class FeedViewController: UITableViewController {
    private var loader: FeedLoader?

    convenience init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }

    override func viewDidLoad() {
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)

        refresh()
    }

    @objc func refresh() {
        refreshControl?.beginRefreshing()

        loader?.load { [weak self] _ in
            self?.refreshControl?.endRefreshing()
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
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()

        XCTAssertEqual(loader.loadCallsCount, 1)
    }

    func test_pullToRefresh_reloadsFeed() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()

        sut.simulatePullToRefresh()

        XCTAssertEqual(loader.loadCallsCount, 2)
    }

    func test_loadingIndicator_isDisplayedWhileLoadingFeed() {
        let (sut, loader) = makeSUT()

        sut.loadViewIfNeeded()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Loading indicator should be visible when loading feed after view appear")

        loader.completeFeedLoad(at: 0)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Loading indicator should be hidden after loading completes")

        sut.simulatePullToRefresh()
        XCTAssertTrue(sut.isShowingLoadingIndicator, "Loading indicator should be visible when user executes a pull to refresh")

        loader.completeFeedLoad(at: 1)
        XCTAssertFalse(sut.isShowingLoadingIndicator, "Loading indicator should be hidden after refresh completes")
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: FeedViewController, loader: FeedLoaderSpy) {
        let loader = FeedLoaderSpy()
        let sut = FeedViewController(loader: loader)

        testMemoryLeak(loader, file: file, line: line)
        testMemoryLeak(sut, file: file, line: line)

        return (sut, loader)
    }

    class FeedLoaderSpy: FeedLoader {
        var completions = [(LoadFeedResult) -> Void]()
        var loadCallsCount: Int {
            return completions.count
        }

        func load(completion: @escaping (LoadFeedResult) -> Void) {
            completions.append(completion)
        }

        func completeFeedLoad(at index: Int) {
            completions[index](.success([]))
        }
    }

}

private extension FeedViewController {
    var isShowingLoadingIndicator: Bool {
        guard let refreshControl = refreshControl else { return false }
        return refreshControl.isRefreshing
    }

    func simulatePullToRefresh() {
        refreshControl?.allTargets.forEach { target in
            refreshControl?.actions(forTarget: target, forControlEvent: .valueChanged)?.forEach {
                (target as NSObject).perform(Selector($0))
            }
        }
    }
}
