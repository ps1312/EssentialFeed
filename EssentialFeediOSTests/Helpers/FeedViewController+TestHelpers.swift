import Foundation
import UIKit
import EssentialFeediOS

extension FeedViewController {
    var feedImagesSection: Int {
        return 0
    }

    var numberOfFeedImages: Int {
        return tableView(tableView, numberOfRowsInSection: feedImagesSection)
    }

    var isShowingLoadingIndicator: Bool {
        guard let refreshControl = refreshControl else { return false }
        return refreshControl.isRefreshing
    }

    var errorMessage: String? {
        return errorView?.errorLabel.text
    }

    func simulatePullToRefresh() {
        refreshControl?.allTargets.forEach { target in
            refreshControl?.actions(forTarget: target, forControlEvent: .valueChanged)?.forEach {
                (target as NSObject).perform(Selector($0))
            }
        }
    }

    func feedImage(at row: Int) -> UITableViewCell {
        let indexPath = IndexPath(row: row, section: feedImagesSection)
        return tableView(tableView, cellForRowAt: indexPath)
    }

    @discardableResult
    func simulateFeedImageCellIsDisplayed(at row: Int) -> FeedImageCell {
        return feedImage(at: row) as! FeedImageCell
    }

    @discardableResult
    func simulateFeedImageCellEndsDiplaying(at row: Int) -> FeedImageCell {
        let indexPath = IndexPath(row: row, section: feedImagesSection)
        let currentCell = simulateFeedImageCellIsDisplayed(at: row)
        tableView(tableView, didEndDisplaying: currentCell, forRowAt: indexPath)
        return currentCell
    }

    func simulateFeedImageCellPrefetch(at row: Int) {
        let indexPath = IndexPath(row: row, section: feedImagesSection)
        tableView(tableView, prefetchRowsAt: [indexPath])
    }

    func simulateFeedImageCellPrefetchingCanceling(at row: Int) {
        simulateFeedImageCellPrefetch(at: row)

        let ds = tableView.prefetchDataSource
        let indexPath = IndexPath(row: row, section: feedImagesSection)
        ds?.tableView?(tableView, cancelPrefetchingForRowsAt: [indexPath])

    }
}
