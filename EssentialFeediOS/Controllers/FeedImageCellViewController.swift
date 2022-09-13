import Foundation
import UIKit

final class FeedImageCellViewController {
    private(set) lazy var view = bind(FeedImageCell())

    private let viewModel: FeedImageViewModel

    init(viewModel: FeedImageViewModel) {
        self.viewModel = viewModel
    }

    func bind(_ view: FeedImageCell) -> FeedImageCell {
        let cell = FeedImageCell()

        cell.descriptionLabel.isHidden = !viewModel.hasDescription
        cell.descriptionLabel.text = viewModel.description
        cell.locationContainer.isHidden = !viewModel.hasLocation
        cell.locationLabel.text = viewModel.location
        cell.retryButton.isHidden = true
        cell.onRetry = viewModel.loadImage

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

        viewModel.onLoadError = { [weak cell] in
            cell?.retryButton.isHidden = false
        }

        viewModel.loadImage()

        return cell
    }

    func preload() {
        viewModel.loadImage()
    }

    func cancelLoad() {
        viewModel.cancelLoad()
    }
}
