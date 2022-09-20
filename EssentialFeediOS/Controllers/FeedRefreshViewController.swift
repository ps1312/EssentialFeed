import UIKit

protocol FeedRefreshViewControllerDelegate {
    func didRequestFeedLoad()
}

final class FeedRefreshViewController: NSObject, FeedLoadingView {
    private let delegate: FeedRefreshViewControllerDelegate
    private(set) lazy var view: UIRefreshControl = {
        let view = UIRefreshControl()
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }()

    init(delegate: FeedRefreshViewControllerDelegate) {
        self.delegate = delegate
    }

    func display(_ viewModel: FeedLoadingViewModel) {
        if viewModel.isLoading {
            view.beginRefreshing()
        } else {
            view.endRefreshing()
        }
    }

    @objc func refresh() {
        delegate.didRequestFeedLoad()
    }
}
