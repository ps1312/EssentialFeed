import UIKit
import EssentialFeed

final class FeedRefreshViewController: NSObject {
    private let onFeedLoad: ([FeedImage]) -> Void
    private let feedLoader: FeedLoader
    private(set) lazy var view: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
        return refreshControl
    }()

    init(feedLoader: FeedLoader, onFeedLoad: @escaping ([FeedImage]) -> Void) {
        self.feedLoader = feedLoader
        self.onFeedLoad = onFeedLoad
    }

    @objc func refresh() {
        view.beginRefreshing()

        feedLoader.load { [weak self] result in
            if let feed = try? result.get() {
                self?.onFeedLoad(feed)
            }

            self?.view.endRefreshing()
        }
    }
}
