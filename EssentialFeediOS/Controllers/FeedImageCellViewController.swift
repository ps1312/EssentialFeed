import Foundation
import EssentialFeed
import UIKit

final class FeedImageCellViewController: NSObject {
    private(set) lazy var view: FeedImageCell = FeedImageCell()
    private var task: FeedImageLoaderTask? = nil

    private let model: FeedImage
    private let imageLoader: FeedImageLoader

    init(model: FeedImage, imageLoader: FeedImageLoader) {
        self.model = model
        self.imageLoader = imageLoader
    }

    func configureView() {
        view.descriptionLabel.isHidden = model.description == nil
        view.descriptionLabel.text = model.description

        view.locationContainer.isHidden = model.location == nil
        view.locationLabel.text = model.location

        view.retryButton.isHidden = true

        view.onRetry = {[weak self] in
            self?.loadImage()
        }
        loadImage()
    }

    func preload() {
        loadImage()
    }

    @objc private func loadImage() {
        view.imageContainer.startShimmering()

        task = self.imageLoader.load(from: model.url) { [weak self] result in
            switch (result) {
            case .failure:
                self?.view.retryButton.isHidden = false

            case .success(let data):
                self?.view.retryButton.isHidden = true
                let image = UIImage(data: data)

                if image != nil {
                    self?.view.feedImageView.image = image
                } else {
                    self?.view.retryButton.isHidden = false
                }
            }

            self?.view.imageContainer.stopShimmering()
        }
    }

    deinit {
        task?.cancel()
        task = nil
    }
}
