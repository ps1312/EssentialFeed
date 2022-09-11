import UIKit
import EssentialFeed

public final class FeedViewController: UITableViewController, UITableViewDataSourcePrefetching {
    private var feed = [FeedImage]() {
        didSet { tableView.reloadData() }
    }
    private var feedLoader: FeedLoader?
    private var imageLoader: FeedImageLoader?
    private var tasks = [IndexPath: FeedImageLoaderTask]()
    private var refreshController: FeedRefreshViewController?

    convenience init(feedLoader: FeedLoader, imageLoader: FeedImageLoader) {
        self.init()
        self.feedLoader = feedLoader
        self.imageLoader = imageLoader
        self.refreshController = FeedRefreshViewController(feedLoader: feedLoader)
    }

    public override func viewDidLoad() {
        tableView.prefetchDataSource = self
        refreshControl = refreshController?.view

        refreshController?.onRefresh = { [weak self] feedImages in
            self?.feed = feedImages
        }
        refreshController?.refresh()
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feed.count
    }

    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach { indexPath in
            let item = feed[indexPath.row]
            self.tasks[indexPath] = imageLoader?.load(from: item.url) { _ in }
        }
    }

    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        indexPaths.forEach(cancelTask)
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = feed[indexPath.row]

        let cell = FeedImageCell()
        cell.descriptionLabel.isHidden = item.description == nil
        cell.descriptionLabel.text = item.description

        cell.locationContainer.isHidden = item.location == nil
        cell.locationLabel.text = item.location

        cell.retryButton.isHidden = true

        let loadImage = { [weak self, weak cell] in
            cell?.imageContainer.startShimmering()

            self?.tasks[indexPath] = self?.imageLoader?.load(from: item.url) { result in
                switch (result) {
                case .failure:
                    cell?.retryButton.isHidden = false

                case .success(let data):
                    cell?.retryButton.isHidden = true
                    let image = UIImage(data: data)

                    if image != nil {
                        cell?.feedImageView.image = image
                    } else {
                        cell?.retryButton.isHidden = false
                    }
                }

                cell?.imageContainer.stopShimmering()
            }

        }

        cell.onRetry = loadImage
        loadImage()

        return cell
    }

    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cancelTask(at: indexPath)
    }

    private func cancelTask(at indexPath: IndexPath) {
        tasks[indexPath]?.cancel()
        tasks[indexPath] = nil
    }
}
