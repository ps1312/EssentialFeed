import UIKit
import EssentialFeed

final class FeedImageCellController {
    private let model: FeedImage
    private let imageLoader: FeedImageLoader
    private var task: FeedImageLoaderTask?

    init(model: FeedImage, imageLoader: FeedImageLoader) {
        self.model = model
        self.imageLoader = imageLoader
    }

    func preload() {
        task = imageLoader.load(from: model.url) { _ in }
    }

    func view() -> FeedImageCell {
        let cell = FeedImageCell()
        cell.descriptionLabel.isHidden = model.description == nil
        cell.descriptionLabel.text = model.description

        cell.locationContainer.isHidden = model.location == nil
        cell.locationLabel.text = model.location

        cell.retryButton.isHidden = true

        let loadImage = { [weak self, weak cell] in
            guard let self = self else { return }

            cell?.imageContainer.startShimmering()

            self.task = self.imageLoader.load(from: self.model.url) { result in
                switch (result) {
                case .failure:
                    cell?.retryButton.isHidden = false

                case .success(let data):
                    cell?.retryButton.isHidden = true
                    let image = UIImage(data: data)

                    if image != nil {
                        cell?.feedImageView.image = image
                    } else {
                        cell?.retryButton.isHidden = false
                    }
                }

                cell?.imageContainer.stopShimmering()
            }

        }

        cell.onRetry = loadImage
        loadImage()

        return cell
    }

    func cancelLoad() {
        task?.cancel()
        task = nil
    }
}
