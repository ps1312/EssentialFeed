import UIKit
import EssentialFeed

public protocol ImageCommentsViewControllerDelegate {
    func didRequestImageCommentsLoad()
}

public final class ImageCommentsViewController: UITableViewController, UITableViewDataSourcePrefetching, ResourceLoadingView, ResourceErrorView {
    @IBOutlet public var errorView: ErrorView?

    public var delegate: ImageCommentsViewControllerDelegate?

    private var loadingControllers = [IndexPath: FeedImageCellController]()
    public var cellControllers = [FeedImageCellController]() {
        didSet { tableView.reloadData() }
    }

    public override func viewDidLoad() {
        refresh()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sizeTableHeaderToFit()
    }

    @IBAction func refresh() {
        delegate?.didRequestImageCommentsLoad()
    }

    public func display(_ controllers: [FeedImageCellController]) {
        loadingControllers = [:]
        cellControllers = controllers
    }

    public func display(_ viewModel: ResourceLoadingViewModel) {
        if viewModel.isLoading {
            refreshControl?.beginRefreshing()
        } else {
            refreshControl?.endRefreshing()
        }
    }

    public func display(_ viewModel: ResourceErrorViewModel) {
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
        cellController(at: indexPath).view(in: tableView)
    }

    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cancelTask(at: indexPath)
    }

    private func cellController(at indexPath: IndexPath) -> FeedImageCellController {
        let controller = cellControllers[indexPath.row]
        loadingControllers[indexPath] = controller
        return controller
    }

    private func cancelTask(at indexPath: IndexPath) {
        loadingControllers[indexPath]?.cancelLoad()
        loadingControllers[indexPath] = nil
    }
}
