import UIKit

struct SnapshotConfiguration {
    let size: CGSize
    let safeAreaInsets: UIEdgeInsets
    let layoutMargins: UIEdgeInsets
    let traitCollection: UITraitCollection


    static func iPhone13(style: UIUserInterfaceStyle, contentSize: UIContentSizeCategory = .medium) -> SnapshotConfiguration {
        return SnapshotConfiguration(
            size: CGSize(width: 390, height: 844),
            safeAreaInsets: UIEdgeInsets(top: 47, left: 0, bottom: 34, right: 0),
            layoutMargins: UIEdgeInsets(top: 55, left: 8, bottom: 42, right: 8),
            traitCollection: UITraitCollection(traitsFrom: [
                .init(forceTouchCapability: .unavailable),
                .init(layoutDirection: .leftToRight),
                .init(preferredContentSizeCategory: contentSize),
                .init(userInterfaceIdiom: .phone),
                .init(horizontalSizeClass: .compact),
                .init(verticalSizeClass: .regular),
                .init(displayScale: 3),
                .init(accessibilityContrast: .normal),
                .init(displayGamut: .P3),
                .init(userInterfaceStyle: style)
            ]))
    }
}
