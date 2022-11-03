import Foundation
import EssentialFeed
import UIKit

public class ImageCommentCellController: CellController {
    private let viewModel: ImageCommentViewModel
    private(set) var cell: ImageCommentCell?

    public init(viewModel: ImageCommentViewModel) {
        self.viewModel = viewModel
    }

    public func view(in tableView: UITableView) -> UITableViewCell {
        cell = tableView.dequeueReusableCell()

        cell?.usernameLabel.text = viewModel.username
        cell?.dateLabel.text = viewModel.date
        cell?.messageLabel.text = viewModel.message

        return cell!
    }

    public func preload() {}

    public func cancelLoad() {
        releaseCellForReuse()
    }

    private func releaseCellForReuse() {
        cell = nil
    }
}
