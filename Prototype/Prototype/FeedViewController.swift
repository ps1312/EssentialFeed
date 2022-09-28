import UIKit

struct FeedImageViewModel {
    let description: String?
    let location: String?
    let imageName: String
}

class ErrorView: UIView {
    @IBOutlet public var button: UIButton?

    override func awakeFromNib() {
        alpha = 0
        button?.setTitle(nil, for: .normal)
    }

    @IBAction func onTap() {
        hideMessage()
    }

    public func show(message: String) {
        button?.setTitle(message, for: .normal)
        UIView.animate(withDuration: 0.25, animations: {
            self.alpha = 1
        })
    }

    public func hideMessage() {
        UIView.animate(
            withDuration: 0.25,
            animations: { self.alpha = 0 },
            completion: { completed in
            if completed {
                self.button?.setTitle(nil, for: .normal)
            }
        })
    }
}

final class FeedViewController: UITableViewController {
    @IBOutlet private(set) public var errorView: ErrorView?

    private var feed = [FeedImageViewModel]()

    override func viewWillAppear(_ animated: Bool) {
        onRefresh()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.sizeTableHeaderToFit()

    }

    @IBAction private func onRefresh() {
        refreshControl?.beginRefreshing()
        self.errorView?.hideMessage()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.errorView?.show(message: "Aconteceu algo inexperado")
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

extension UITableViewController {
    func sizeTableHeaderToFit() {
        guard let header = tableView.tableHeaderView else { return }

        let size = header.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)

        // somehow the header is bigger than the size defined (like a longer error text from another language)
        let needsFrameUpdate = header.frame.height != size.height

        if needsFrameUpdate {
            header.frame.size.height = header.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize).height
            tableView.tableHeaderView = header
        }
    }
}
