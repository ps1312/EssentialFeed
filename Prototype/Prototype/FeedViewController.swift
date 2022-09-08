import UIKit

struct FeedImageViewModel {
    let description: String?
    let location: String?
    let imageName: String
}

final class FeedViewController: UITableViewController {
    private var feed = [FeedImageViewModel]()

    override func viewWillAppear(_ animated: Bool) {
        onRefresh()
    }

    @IBAction private func onRefresh() {
        refreshControl?.beginRefreshing()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.feed = FeedImageViewModel.prototypeFeed
            self.refreshControl?.endRefreshing()
            self.tableView.reloadData()
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return feed.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeedImageCell", for: indexPath) as! FeedImageCell

        cell.configure(with: feed[indexPath.row])

        return cell
    }

}
