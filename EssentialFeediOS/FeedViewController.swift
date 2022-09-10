import UIKit
import EssentialFeed

public class FeedImageCell: UITableViewCell {
    let descriptionLabel = UILabel()
    let locationContainer = UIView()
    let locationLabel = UILabel()
    let imageContainer = UIView()
    private(set) public lazy var retryButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        return button
    }()

    var onRetry: (() -> Void)?

    @objc func retryButtonTapped() {
        onRetry?()
    }
}

public protocol FeedImageLoaderTask {
    func cancel()
}

public protocol FeedImageLoader {
    typealias Result = Swift.Result<Data, Error>

    func load(from url: URL, completion: @escaping (Result) -> Void) -> FeedImageLoaderTask
}

public final class FeedViewController: UITableViewController {
    private var feed = [FeedImage]()
    private var feedLoader: FeedLoader?
    private var imageLoader: FeedImageLoader?
    private var tasks = [IndexPath: FeedImageLoaderTask]()

    convenience init(feedLoader: FeedLoader, imageLoader: FeedImageLoader) {
        self.init()
        self.feedLoader = feedLoader
        self.imageLoader = imageLoader
    }

    public override func viewDidLoad() {
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)

        refresh()
    }

    @objc func refresh() {
        refreshControl?.beginRefreshing()

        feedLoader?.load { [weak self] result in
            switch (result) {
            case .success(let images):
                self?.feed = images
                self?.tableView.reloadData()

            default: break

            }

            self?.refreshControl?.endRefreshing()
        }
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feed.count
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

                case .success:
                    cell?.retryButton.isHidden = true

                }

                cell?.imageContainer.stopShimmering()
            }

        }

        cell.onRetry = loadImage
        loadImage()

        return cell
    }

    public override func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        tasks[indexPath]?.cancel()
        tasks[indexPath] = nil
    }
}
