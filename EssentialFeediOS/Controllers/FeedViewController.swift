import UIKit
import EssentialFeed

public final class FeedViewController: UITableViewController, UITableViewDataSourcePrefetching {
    private var feed = [FeedImage]() {
        didSet { tableView.reloadData() }
    }
    private var feedLoader: FeedLoader?
    private var imageLoader: FeedImageLoader?
    private var refreshController: FeedRefreshViewController?
    private var cellControllers = [IndexPath: FeedImageCellController]()

    convenience init(feedLoader: FeedLoader, imageLoader: FeedImageLoader) {
        self.init()

        self.feedLoader = feedLoader
        self.imageLoader = imageLoader
        self.refreshController = FeedRefreshViewController(feedLoader: feedLoader, onFeedLoad: { [weak self] in self?.feed = $0 })

    }

    public override func viewDidLoad() {
        tableView.prefetchDataSource = self

        refreshControl = refreshController?.view
        refreshController?.refresh()
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feed.count
    }

    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            cellController(at: indexPath).preload()
        }
    }

    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach(cancelTask)
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cellController(at: indexPath).view()
    }

    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cancelTask(at: indexPath)
    }

    private func cellController(at indexPath: IndexPath) -> FeedImageCellController {
        let model = feed[indexPath.row]
        let cellController = FeedImageCellController(model: model, imageLoader: imageLoader!)
        cellControllers[indexPath] = cellController
        return cellController
    }

    private func cancelTask(at indexPath: IndexPath) {
        cellControllers[indexPath] = nil
    }
}
