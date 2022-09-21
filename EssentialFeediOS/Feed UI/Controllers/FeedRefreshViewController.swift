import UIKit

protocol FeedRefreshViewControllerDelegate {
    func didRequestFeedLoad()
}

final class FeedRefreshViewController: NSObject, FeedLoadingView {
    public var delegate: FeedRefreshViewControllerDelegate?
    @IBOutlet private(set) public var view: UIRefreshControl?

    func display(_ viewModel: FeedLoadingViewModel) {
        if viewModel.isLoading {
            view?.beginRefreshing()
        } else {
            view?.endRefreshing()
        }
    }

    @IBAction func refresh() {
        delegate?.didRequestFeedLoad()
    }
}
