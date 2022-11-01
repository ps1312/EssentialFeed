import Foundation
import EssentialFeediOS

extension ImageCommentsViewController {

    var isShowingLoadingIndicator: Bool {
        guard let refreshControl = refreshControl else { return false }
        return refreshControl.isRefreshing
    }

    var isShowingErrorMessage: Bool {
        guard let errorView = errorView else { return false }
        return errorView.isVisible
    }

    var errorMessage: String? {
        return errorView?.button?.titleLabel?.text
    }

    func simulatePullToRefresh() {
        refreshControl?.allTargets.forEach { target in
            refreshControl?.actions(forTarget: target, forControlEvent: .valueChanged)?.forEach {
                (target as NSObject).perform(Selector($0))
            }
        }
    }

}
