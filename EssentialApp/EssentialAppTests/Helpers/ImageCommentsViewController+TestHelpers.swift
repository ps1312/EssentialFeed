import Foundation
import UIKit
import EssentialFeediOS

extension ImageCommentsViewController {
    var commentsSection: Int {
        0
    }

    var isShowingLoadingIndicator: Bool {
        guard let refreshControl = refreshControl else { return false }
        return refreshControl.isRefreshing
    }

    var isShowingErrorMessage: Bool {
        guard let errorView = errorView else { return false }
        return errorView.isVisible
    }

    var errorMessage: String? {
        errorView?.button?.titleLabel?.text
    }

    var numberOfComments: Int {
        tableView(tableView, numberOfRowsInSection: commentsSection)
    }

    func simulatePullToRefresh() {
        refreshControl?.allTargets.forEach { target in
            refreshControl?.actions(forTarget: target, forControlEvent: .valueChanged)?.forEach {
                (target as NSObject).perform(Selector($0))
            }
        }
    }

    func imageComment(at row: Int) -> UITableViewCell {
        let indexPath = IndexPath(row: row, section: commentsSection)
        return tableView(tableView, cellForRowAt: indexPath)
    }

}
