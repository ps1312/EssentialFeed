import UIKit

final class FeedRefreshViewController: NSObject {
    private let viewModel: FeedRefreshViewModel
    private(set) lazy var view: UIRefreshControl = bind(UIRefreshControl())

    init(viewModel: FeedRefreshViewModel) {
        self.viewModel = viewModel
    }

    func bind(_ view: UIRefreshControl) -> UIRefreshControl {
        viewModel.onLoadingChange = { [weak self] isLoading in
            if isLoading {
                self?.view.beginRefreshing()
            } else {
                self?.view.endRefreshing()
            }
        }

        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }

    @objc func refresh() {
        viewModel.loadFeed()
    }
}
