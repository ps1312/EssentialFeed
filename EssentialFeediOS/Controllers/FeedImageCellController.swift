import UIKit

final class FeedImageCellController {
    private let viewModel: FeedImageViewModel
    private(set) lazy var view: FeedImageCell = bind(FeedImageCell())

    init(viewModel: FeedImageViewModel) {
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

        viewModel.onImageLoad = { [weak cell] imageData in
            cell?.retryButton.isHidden = true
            let image = UIImage(data: imageData)

            if image != nil {
                cell?.feedImageView.image = image
            } else {
                cell?.retryButton.isHidden = false
            }
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
