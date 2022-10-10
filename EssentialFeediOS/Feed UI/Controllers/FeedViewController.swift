import UIKit
import EssentialFeed

protocol FeedRefreshViewControllerDelegate {
    func didRequestFeedLoad()
}

public final class FeedViewController: UITableViewController, UITableViewDataSourcePrefetching, FeedLoadingView, FeedErrorView {
    public var errorView: ErrorView? = ErrorView()

    var delegate: FeedRefreshViewControllerDelegate?
    public var cellControllers = [FeedImageCellController]() {
        didSet { tableView.reloadData() }
    }

    public override func viewDidLoad() {
        refresh()
    }

    @IBAction func refresh() {
        delegate?.didRequestFeedLoad()
    }

    public func display(_ viewModel: FeedLoadingViewModel) {
        if viewModel.isLoading {
            refreshControl?.beginRefreshing()
        } else {
            refreshControl?.endRefreshing()
        }
    }

    public func display(_ viewModel: FeedErrorViewModel) {
        if let message = viewModel.message {
            errorView?.display(message: message)
        } else {
            errorView?.hideMessage()
        }
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellControllers.count
    }

    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { cellController(at: $0).preload() }
    }

    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach(cancelTask)
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return cellController(at: indexPath).view(in: tableView)
    }

    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cancelTask(at: indexPath)
    }

    private func cellController(at indexPath: IndexPath) -> FeedImageCellController {
        return cellControllers[indexPath.row]
    }

    private func cancelTask(at indexPath: IndexPath) {
        cellControllers[indexPath.row].cancelLoad()
    }
}
