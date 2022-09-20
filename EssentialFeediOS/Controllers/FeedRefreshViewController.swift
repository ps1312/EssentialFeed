import UIKit

final class FeedRefreshViewController: NSObject, FeedLoadingView {
    private let presenter: FeedPresenter
    private(set) lazy var view: UIRefreshControl = {
        let view = UIRefreshControl()
        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }()

    init(presenter: FeedPresenter) {
        self.presenter = presenter
    }

    func display(_ viewModel: FeedLoadingViewModel) {
        if viewModel.isLoading {
            view.beginRefreshing()
        } else {
            view.endRefreshing()
        }
    }

    @objc func refresh() {
        presenter.loadFeed()
    }
}
