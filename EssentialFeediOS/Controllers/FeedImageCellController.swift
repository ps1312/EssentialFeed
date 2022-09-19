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

    func display(isLoading: Bool, shouldRetry: Bool, image: UIImage?, description: String?, location: String?) {
        cell.descriptionLabel.isHidden = description == nil
        cell.descriptionLabel.text = description

        cell.locationContainer.isHidden = location == nil
        cell.locationLabel.text = location

        cell.retryButton.isHidden = !shouldRetry
        cell.onRetry = presenter.loadImage

        cell.feedImageView.image = image

        if isLoading {
            cell.imageContainer.startShimmering()
        } else {
            cell.imageContainer.stopShimmering()
        }
    }

    func cancelLoad() {
        presenter.cancelLoad()
    }
}
