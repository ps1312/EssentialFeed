import UIKit

final class FeedImageCellController {
    private let viewModel: FeedImageViewModel<UIImage>
    private(set) lazy var view: FeedImageCell = bind(FeedImageCell())

    init(viewModel: FeedImageViewModel<UIImage>) {
        self.viewModel = viewModel
    }

    func preload() {
        viewModel.loadImage()
    }

    func bind(_ cell: FeedImageCell) -> FeedImageCell {
        cell.descriptionLabel.isHidden = !viewModel.hasDescription
        cell.descriptionLabel.text = viewModel.description

        cell.locationContainer.isHidden = !viewModel.hasLocation
        cell.locationLabel.text = viewModel.location

        cell.retryButton.isHidden = true

        viewModel.onLoadingChange = { [weak cell] isLoading in
            if isLoading {
                cell?.imageContainer.startShimmering()
            } else {
                cell?.imageContainer.stopShimmering()
            }
        }

        viewModel.onImageLoad = { [weak cell] image in
            cell?.retryButton.isHidden = true
            cell?.feedImageView.image = image
        }

        viewModel.onImageLoadedWithError = { [weak cell] in
            cell?.retryButton.isHidden = false
        }

        cell.onRetry = viewModel.loadImage
        viewModel.loadImage()

        return cell
    }

    func cancelLoad() {
        viewModel.cancelLoad()
    }
}
