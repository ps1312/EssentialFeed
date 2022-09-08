import UIKit

final class FeedImageCell: UITableViewCell {
    @IBOutlet private(set) var locationContainer: UIView!
    @IBOutlet private(set) var locationLabel: UILabel!
    @IBOutlet private(set) var descriptionLabel: UILabel!
    @IBOutlet private(set) var feedImageView: UIImageView!

    override func awakeFromNib() {
            super.awakeFromNib()

            feedImageView.alpha = 0
        }

        override func prepareForReuse() {
            super.prepareForReuse()

            feedImageView.alpha = 0
        }

        func fadeIn(_ image: UIImage?) {
            feedImageView.image = image

            UIView.animate(
                withDuration: 0.3,
                delay: 0.3,
                options: [],
                animations: {
                    self.feedImageView.alpha = 1
                })
        }
}

extension FeedImageCell {
    func configure(with model: FeedImageViewModel) {
        locationContainer.isHidden = model.location == nil
        locationLabel.text = model.location

        descriptionLabel.isHidden = model.description == nil
        descriptionLabel.text = model.description

        fadeIn(UIImage(named: model.imageName))
    }
}
