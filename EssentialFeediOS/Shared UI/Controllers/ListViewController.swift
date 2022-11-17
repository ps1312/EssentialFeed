import UIKit
import EssentialFeed

public final class ListViewController: UITableViewController, UITableViewDataSourcePrefetching, ResourceLoadingView, ResourceErrorView {
    private lazy var dataSource: UITableViewDiffableDataSource<Int, CellController> = {
        .init(tableView: tableView) { [weak self] tableView, indexPath, controller in
            controller.dataSource.tableView(tableView, cellForRowAt: indexPath)
        }
    }()

    public lazy var errorView: ErrorButton = ErrorButton()
    public var onRefresh: (() -> Void)?

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

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sizeTableHeaderToFit()
    }

    @objc func refresh() {
        onRefresh?()
    }

    public func display(_ cellControllers: [CellController]) {
        var snapshot = NSDiffableDataSourceSnapshot<Int, CellController>()
        snapshot.appendSections([0])
        snapshot.appendItems(cellControllers)
        dataSource.apply(snapshot)
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

    public override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let dl = dataSource.itemIdentifier(for: indexPath)?.delegate
        dl?.tableView?(tableView, willDisplay: cell, forRowAt: indexPath)
    }

    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        let dl = dataSource.itemIdentifier(for: indexPath)?.delegate
        dl?.tableView?(tableView, didEndDisplaying: cell, forRowAt: indexPath)
    }

    public override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let dl = dataSource.itemIdentifier(for: indexPath)?.delegate
        dl?.tableView?(tableView, didSelectRowAt: indexPath)
    }

    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            let pf = dataSource.itemIdentifier(for: indexPath)?.prefetch
            pf?.tableView(tableView, prefetchRowsAt: indexPaths)
        }
    }

    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            let pf = dataSource.itemIdentifier(for: indexPath)?.prefetch
            pf?.tableView?(tableView, cancelPrefetchingForRowsAt: indexPaths)
        }
    }
}
