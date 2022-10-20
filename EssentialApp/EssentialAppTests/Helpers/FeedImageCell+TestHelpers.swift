import Foundation
import EssentialFeediOS

extension FeedImageCell {
    var descriptionText: String? {
        return descriptionLabel.text
    }

    var locationText: String? {
        return locationLabel.text
    }

    var isLocationHidden: Bool {
        return locationContainer.isHidden
    }

    var isDescriptionHidden: Bool {
        return descriptionLabel.isHidden
    }

    var isShowingLoadingIndicator: Bool {
        return imageContainer.isShimmering
    }

    var isShowingRetryButton: Bool {
        return !retryButton.isHidden
    }

    var feedImageData: Data? {
        return feedImageView.image?.pngData()
    }

    func simulateImageLoadRetry() {
        retryButton.allTargets.forEach { target in
            retryButton.actions(forTarget: target, forControlEvent: .touchUpInside)?.forEach {
                (target as NSObject).perform(Selector($0))
            }
        }
    }
}
