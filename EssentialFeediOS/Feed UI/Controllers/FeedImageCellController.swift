import UIKit
import EssentialFeed

public protocol FeedImageCellControllerDelegate {
    func didRequestImageLoad()
    func didCancelImageLoad()
}

public final class FeedImageCellController: NSObject {
    public typealias ResourceViewModel = UIImage

    private let selected: () -> Void
    private let viewModel: FeedImageViewModel
    private let delegate: FeedImageCellControllerDelegate
    private(set) var cell: FeedImageCell?

    public init(selected: @escaping () -> Void, viewModel: FeedImageViewModel, delegate: FeedImageCellControllerDelegate) {
        self.selected = selected
        self.viewModel = viewModel
        self.delegate = delegate
    }
}

extension FeedImageCellController: UITableViewDelegate, UITableViewDataSource, UITableViewDataSourcePrefetching {
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 1 }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        cell = tableView.dequeueReusableCell()

        cell?.feedImageView.image = nil
        cell?.retryButton.isHidden = true
        cell?.imageContainer.startShimmering()

        cell?.descriptionLabel.isHidden = !viewModel.hasDescription
        cell?.descriptionLabel.text = viewModel.description
        cell?.locationContainer.isHidden = !viewModel.hasLocation
        cell?.locationLabel.text = viewModel.location
        cell?.onRetry = { [weak self] in
            self?.delegate.didRequestImageLoad()
        }

        delegate.didRequestImageLoad()
        return cell!
    }

    public func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        self.cell = cell as? FeedImageCell
        delegate.didRequestImageLoad()
    }

    public func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        cancelLoad()
    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selected()
    }

    public func tableView(_ tableView: UITableView, prefetchRowsAt indexPaths: [IndexPath]) {
        delegate.didRequestImageLoad()
    }

    public func tableView(_ tableView: UITableView, cancelPrefetchingForRowsAt indexPaths: [IndexPath]) {
        cancelLoad()
    }

    private func cancelLoad() {
        delegate.didCancelImageLoad()
        releaseCellForReuse()
    }

    private func releaseCellForReuse() {
        cell = nil
    }
}

extension FeedImageCellController: ResourceLoadingView, ResourceErrorView, ResourceView {
    public func display(_ viewModel: ResourceLoadingViewModel) {
        if viewModel.isLoading {
            cell?.imageContainer.startShimmering()
        } else {
            cell?.imageContainer.stopShimmering()
        }
    }

    public func display(_ viewModel: ResourceErrorViewModel) {
        cell?.retryButton.isHidden = viewModel.message == nil
    }

    public func display(_ viewModel: UIImage) {
        cell?.feedImageView.image = viewModel
    }
}
