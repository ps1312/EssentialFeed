import UIKit

final class FeedRefreshViewController: NSObject {
    private(set) lazy var view = bind(view: UIRefreshControl())
    private var viewModel: FeedViewModel

    init(viewModel: FeedViewModel) {
        self.viewModel = viewModel
    }

    func bind(view: UIRefreshControl) -> UIRefreshControl {
        viewModel.onLoadingChanged = { isLoading in
            if isLoading {
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
