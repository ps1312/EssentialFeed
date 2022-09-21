import UIKit

public class FeedImageCell: UITableViewCell {
    @IBOutlet var descriptionLabel: UILabel!
    @IBOutlet var locationContainer: UIView!
    @IBOutlet var locationLabel: UILabel!
    @IBOutlet var feedImageView: UIImageView!
    @IBOutlet var imageContainer: UIView!
    @IBOutlet var retryButton: UIButton!

    var onRetry: (() -> Void)?

    @IBAction func retryButtonTapped() {
        onRetry?()
    }
}
