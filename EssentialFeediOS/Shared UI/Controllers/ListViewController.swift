import UIKit
import EssentialFeed

public final class ListViewController: UITableViewController, UITableViewDataSourcePrefetching, ResourceLoadingView, ResourceErrorView {
    private lazy var dataSource: UITableViewDiffableDataSource<Int, CellController> = {
        .init(tableView: tableView) { [weak self] tableView, indexPath, controller in
            self?.cellController(at: indexPath).dataSource.tableView(tableView, cellForRowAt: indexPath)
        }
    }()
    private var loadingControllers = [IndexPath: CellController]()

    public lazy var errorView: ErrorButton = ErrorButton()
    public var onRefresh: (() -> Void)?
    public var cellControllers = [CellController]() {
        didSet { handleCellControllersUpdate() }
    }

    public override func viewDidLoad() {
        configureLoadingIndicator()
        configureErrorButton()
        refresh()
    }

    private func configureDataSource() {
        dataSource.defaultRowAnimation = .fade
        tableView.dataSource = dataSource
    }

    private func configureLoadingIndicator() {
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }

    private func configureErrorButton() {
        let container = UIView()
        container.backgroundColor = .clear
        container.addSubview(errorView)

        errorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            errorView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: errorView.trailingAnchor),
            errorView.topAnchor.constraint(equalTo: container.topAnchor),
            container.bottomAnchor.constraint(equalTo: errorView.bottomAnchor),
        ])

        errorView.onHide = { [weak self] in
            self?.tableView.beginUpdates()
            self?.sizeTableHeaderToFit()
            self?.tableView.endUpdates()
        }

        tableView.tableHeaderView = container
    }

    private func handleCellControllersUpdate() {
        var snapshot = NSDiffableDataSourceSnapshot<Int, CellController>()
        snapshot.appendSections([0])
        snapshot.appendItems(cellControllers)
        dataSource.apply(snapshot)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sizeTableHeaderToFit()
    }

    @objc func refresh() {
        onRefresh?()
    }

    public func display(_ viewModel: ResourceLoadingViewModel) {
        viewModel.isLoading ? refreshControl?.beginRefreshing() : refreshControl?.endRefreshing()
    }

    public func display(_ viewModel: ResourceErrorViewModel) {
        if let message = viewModel.message {
            errorView.display(message: message)
        } else {
            errorView.hideMessage()
        }
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
