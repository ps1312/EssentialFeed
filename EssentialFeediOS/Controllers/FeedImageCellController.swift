import UIKit

final class FeedImageCellController: FeedImageView {
    private let presenter: FeedImagePresenter<WeakRefVirtualProxy<FeedImageCellController>, UIImage>

    private(set) lazy var cell = FeedImageCell()

    init(presenter: FeedImagePresenter<WeakRefVirtualProxy<FeedImageCellController>, UIImage>) {
        self.presenter = presenter
    }

    func preload() {
        presenter.loadImage()
    }

    func view() -> FeedImageCell {
        presenter.loadImage()
        return cell
    }

    func display(_ viewModel: FeedImageViewModel<UIImage>) {
        cell.descriptionLabel.isHidden = viewModel.description == nil
        cell.descriptionLabel.text = viewModel.description

        cell.locationContainer.isHidden = viewModel.location == nil
        cell.locationLabel.text = viewModel.location

        cell.retryButton.isHidden = !viewModel.shouldRetry
        cell.onRetry = presenter.loadImage

        cell.feedImageView.image = viewModel.image

        if viewModel.isLoading {
            cell.imageContainer.startShimmering()
        } else {
            cell.imageContainer.stopShimmering()
        }
    }

    func cancelLoad() {
        presenter.cancelLoad()
    }
}
