import UIKit

public class FeedImageCell: UITableViewCell {
    let descriptionLabel = UILabel()
    let locationContainer = UIView()
    let locationLabel = UILabel()
    let feedImageView = UIImageView()
    let imageContainer = UIView()
    private(set) public lazy var retryButton: UIButton = {
        let button = UIButton()
        button.addTarget(self, action: #selector(retryButtonTapped), for: .touchUpInside)
        return button
    }()

    var onRetry: (() -> Void)?

    @objc func retryButtonTapped() {
        onRetry?()
    }
}
