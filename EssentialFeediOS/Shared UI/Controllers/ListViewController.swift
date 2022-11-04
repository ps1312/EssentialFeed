import UIKit
import EssentialFeed

public struct CellController {
    public let dataSource: UITableViewDataSource
    public let delegate: UITableViewDelegate?
    public let prefetch: UITableViewDataSourcePrefetching?

    public init(_ dataSource: UITableViewDataSource, _ delegate: UITableViewDelegate?, _ prefetch: UITableViewDataSourcePrefetching?) {
        self.dataSource = dataSource
        self.delegate = delegate
        self.prefetch = prefetch
    }

    public init(_ dataSource: UITableViewDataSource) {
        self.dataSource = dataSource
        self.delegate = nil
        self.prefetch = nil
    }
}

public final class ListViewController: UITableViewController, UITableViewDataSourcePrefetching, ResourceLoadingView, ResourceErrorView {

    private var loadingControllers = [IndexPath: CellController]()

    @IBOutlet public var errorView: ErrorView?

    public var onRefresh: (() -> Void)?
    public var cellControllers = [CellController]() {
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
        onRefresh?()
    }

    public func display(_ controllers: [CellController]) {
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

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let ds = cellController(at: indexPath).dataSource
        return ds.tableView(tableView, cellForRowAt: indexPath)
    }

    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let dl = removeLoadingController(at: indexPath)?.delegate
        dl?.tableView?(tableView, didEndDisplaying: cell, forRowAt: indexPath)
    }

    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            let pf = cellController(at: indexPath).prefetch
            pf?.tableView(tableView, prefetchRowsAt: indexPaths)
        }
    }

    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            let pf = removeLoadingController(at: indexPath)?.prefetch
            pf?.tableView?(tableView, cancelPrefetchingForRowsAt: indexPaths)
        }
    }

    private func cellController(at indexPath: IndexPath) -> CellController {
        let controller = cellControllers[indexPath.row]
        loadingControllers[indexPath] = controller
        return controller
    }

    private func removeLoadingController(at indexPath: IndexPath) -> CellController? {
        let controller = loadingControllers[indexPath]
        loadingControllers[indexPath] = nil
        return controller
    }
}
