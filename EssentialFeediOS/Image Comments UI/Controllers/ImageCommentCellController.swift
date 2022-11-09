import Foundation
import EssentialFeed
import UIKit

public class ImageCommentCellController: NSObject, UITableViewDataSource {
    private let viewModel: ImageCommentViewModel
    private(set) var cell: ImageCommentCell?

    public init(viewModel: ImageCommentViewModel) {
        self.viewModel = viewModel
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cell = tableView.dequeueReusableCell()

        cell?.usernameLabel.text = viewModel.username
        cell?.dateLabel.text = viewModel.date
        cell?.messageLabel.text = viewModel.message

        return cell!
    }

    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        releaseCellForReuse()
    }

    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {}

    private func releaseCellForReuse() {
        cell = nil
    }
}
