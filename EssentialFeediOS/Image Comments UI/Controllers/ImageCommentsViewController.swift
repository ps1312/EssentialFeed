import UIKit
import EssentialFeed

public final class ImageCommentsViewController: UITableViewController, ResourceLoadingView, ResourceErrorView {
    @IBOutlet public var errorView: ErrorView?

    public var delegate: LoadResourceViewControllerDelegate?

    public var cellControllers = [ImageCommentCellController]() {
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
        delegate?.didRequestLoad()
    }

    public func display(_ controllers: [ImageCommentCellController]) {
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
        cellController(at: indexPath).view(in: tableView)
    }

    private func cellController(at indexPath: IndexPath) -> ImageCommentCellController {
        return cellControllers[indexPath.row]
    }
}
