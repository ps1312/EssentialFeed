import UIKit
import EssentialFeed

final class FeedUIComposer {
    static func composeWith(feedLoader: FeedLoader, imageLoader: FeedImageLoader) -> FeedViewController {
        let refreshViewModel = FeedViewModel(feedLoader: feedLoader)
        let refreshController = FeedRefreshViewController(viewModel: refreshViewModel)
        let feedViewController = FeedViewController()

        refreshViewModel.onFeedLoad = FeedUIComposer.adaptFeedImagesToCells(forwardingTo: feedViewController, imageLoader: imageLoader)
        feedViewController.refreshController = refreshController

        return feedViewController
    }

    private static func adaptFeedImagesToCells(forwardingTo feedViewController: FeedViewController, imageLoader: FeedImageLoader) -> ([FeedImage]) -> Void {
        return { [weak feedViewController] feedImages in
            feedViewController?.tableModel = feedImages.map { model in
                let feedImageViewModel = FeedImageViewModel(model: model, imageLoader: imageLoader)
                let cellController = FeedImageCellViewController(viewModel: feedImageViewModel)

                return cellController
            }
        }
    }
}

public final class FeedViewController: UITableViewController, UITableViewDataSourcePrefetching {
    var refreshController: FeedRefreshViewController?

    var tableModel = [FeedImageCellViewController]() {
        didSet { tableView.reloadData() }
    }

    public override func viewDidLoad() {
        tableView.prefetchDataSource = self

        refreshControl = refreshController?.view
        refreshController?.refresh()
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableModel.count
    }

    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { tableModel[$0.row].preload() }
    }

    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach(cancelImageLoad)
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableModel[indexPath.row].view
    }

    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cancelImageLoad(at: indexPath)
    }

    private func cancelImageLoad(at indexPath: IndexPath) {
        tableModel[indexPath.row].cancelLoad()
    }
}
