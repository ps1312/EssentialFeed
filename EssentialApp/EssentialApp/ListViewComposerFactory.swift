import UIKit
import Foundation
import EssentialFeediOS

extension ListViewController {
    static func makeWith(title: String, onRefresh: @escaping () -> Void, storyboardName: String) -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyboard = UIStoryboard(name: storyboardName, bundle: bundle)
        let controller = storyboard.instantiateInitialViewController() as! ListViewController
        controller.title = title
        controller.onRefresh = onRefresh

        return controller
    }
}
