import UIKit

protocol FeedImageCellControllerDelegate {
    func didRequestImageLoad()
    func didCancelImageLoad()
}

final class FeedImageCellController: FeedImageView {
    private let delegate: FeedImageCellControllerDelegate
    private(set) var cell: FeedImageCell?

    init(delegate: FeedImageCellControllerDelegate) {
        self.delegate = delegate
    }

    func preload() {
        delegate.didRequestImageLoad()
    }

    func view(in tableView: UITableView) -> FeedImageCell {
        cell = tableView.dequeueReusableCell()
        delegate.didRequestImageLoad()
        return cell!
    }

    func display(_ viewModel: FeedImageViewModel<UIImage>) {
        cell?.descriptionLabel.isHidden = !viewModel.hasDescription
        cell?.descriptionLabel.text = viewModel.description

        cell?.locationContainer.isHidden = !viewModel.hasLocation
        cell?.locationLabel.text = viewModel.location

        cell?.retryButton.isHidden = !viewModel.shouldRetry
        cell?.onRetry = delegate.didRequestImageLoad

        cell?.feedImageView.image = viewModel.image

        if viewModel.isLoading {
            cell?.imageContainer.startShimmering()
        } else {
            cell?.imageContainer.stopShimmering()
        }
    }

    func cancelLoad() {
        delegate.didCancelImageLoad()
        releaseCellForReuse()
    }

    private func releaseCellForReuse() {
        cell = nil
    }
}
