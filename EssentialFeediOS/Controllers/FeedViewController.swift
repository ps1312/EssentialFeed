import UIKit
import EssentialFeed

public final class FeedViewController: UITableViewController, UITableViewDataSourcePrefetching {
    private var feed = [FeedImage]() {
        didSet { tableView.reloadData() }
    }

    private var feedLoader: FeedLoader?
    private var imageLoader: FeedImageLoader?

    private var refreshController: FeedRefreshViewController?
    private var feedCellControllers = [IndexPath: FeedImageCellViewController]()

    convenience init(feedLoader: FeedLoader, imageLoader: FeedImageLoader) {
        self.init()
        self.feedLoader = feedLoader
        self.imageLoader = imageLoader
        self.refreshController = FeedRefreshViewController(feedLoader: feedLoader)
    }

    public override func viewDidLoad() {
        tableView.prefetchDataSource = self
        refreshControl = refreshController?.view

        refreshController?.onRefresh = { [weak self] feedImages in
            self?.feed = feedImages
        }
        refreshController?.refresh()
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feed.count
    }

    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach {  let _ = createFeedImageCell(for: $0).view }
    }

    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach(removeCellController)
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellController = createFeedImageCell(for: indexPath)
        feedCellControllers[indexPath] = cellController
        return cellController.view
    }

    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        removeCellController(at: indexPath)
    }

    private func createFeedImageCell(for indexPath: IndexPath) -> FeedImageCellViewController {
        let cellController = FeedImageCellViewController(model: feed[indexPath.row], imageLoader: imageLoader!)
        cellController.configureView()

        return cellController
    }

    private func removeCellController(at indexPath: IndexPath) {
        feedCellControllers[indexPath] = nil
    }
}
