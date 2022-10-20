import Foundation
import UIKit
import EssentialFeediOS

extension FeedViewController {
    func snapshot(for configuration: SnapshotConfiguration) -> UIImage {
        return SnapshotWindow(configuration: configuration, root: self).snapshot()
    }
}
