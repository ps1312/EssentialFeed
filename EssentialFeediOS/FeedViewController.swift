import UIKit
import EssentialFeed

public class FeedImageCell: UITableViewCell {
    let descriptionLabel = UILabel()
    let locationLabel = UILabel()
}

public final class FeedViewController: UITableViewController {
    private var feed = [FeedImage]()
    private var loader: FeedLoader?

    convenience init(loader: FeedLoader) {
        self.init()
        self.loader = loader
    }

    public override func viewDidLoad() {
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)

        refresh()
    }

    @objc func refresh() {
        refreshControl?.beginRefreshing()

        loader?.load { [weak self] result in
            switch (result) {
            case .success(let images):
                self?.feed = images
                self?.tableView.reloadData()
                self?.refreshControl?.endRefreshing()

            default: break
            }
        }
    }

    public override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feed.count
    }

    public override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = feed[indexPath.row]

        let cell = FeedImageCell()
        cell.descriptionLabel.text = item.description
        cell.locationLabel.text = item.location

        return cell
    }
}
