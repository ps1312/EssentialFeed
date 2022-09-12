import UIKit

final class FeedRefreshViewController: NSObject {
    private(set) lazy var view = bind(view: UIRefreshControl())
    private var viewModel: FeedRefreshViewModel

    init(viewModel: FeedRefreshViewModel) {
        self.viewModel = viewModel
    }

    func bind(view: UIRefreshControl) -> UIRefreshControl {
        viewModel.onChange = { viewModel in
            if viewModel.isLoading {
                view.beginRefreshing()
            } else {
                view.endRefreshing()
            }
        }

        view.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return view
    }

    @objc func refresh() {
        viewModel.loadImages()
    }
}
