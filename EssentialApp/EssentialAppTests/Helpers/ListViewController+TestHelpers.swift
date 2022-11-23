import Foundation
import UIKit
@testable import EssentialFeediOS

extension ListViewController {
    var isShowingLoadingIndicator: Bool {
        guard let refreshControl = refreshControl else { return false }
        return refreshControl.isRefreshing
    }

    var errorMessage: String? {
        errorView.titleLabel?.text
    }

    var isShowingErrorMessage: Bool? {
        errorView.isVisible
    }

    func simulatePullToRefresh() {
        refreshControl?.simulate(.valueChanged)
    }

    func simulateTapOnError() {
        errorView.simulate(.touchUpInside)
    }
}

// MARK: - FeedViewController helpers

extension ListViewController {
    var feedSection: Int {
        0
    }

    var numberOfFeedImages: Int {
        tableView.numberOfRows(inSection: feedSection)
    }

    func feedImageCell(at row: Int) -> UITableViewCell {
        let indexPath = IndexPath(row: row, section: feedSection)
        return tableView.dataSource!.tableView(tableView, cellForRowAt: indexPath)
    }

    @discardableResult
    func simulateFeedImageCellIsVisible(at row: Int) -> UITableViewCell {
        feedImageCell(at: row)
    }

    func simulateFeedImageCellNearVisible(at row: Int) {
        let indexPath = IndexPath(row: row, section: feedSection)
        tableView(tableView, prefetchRowsAt: [indexPath])
    }

    func simulateFeedImageCellPrefetchCancel(at row: Int) {
        simulateFeedImageCellNearVisible(at: row)

        let ds = tableView.prefetchDataSource
        let indexPath = IndexPath(row: row, section: feedSection)
        ds?.tableView?(tableView, cancelPrefetchingForRowsAt: [indexPath])
    }

    @discardableResult
    func simulateFeedImageCellNotVisible(at row: Int) -> UITableViewCell {
        let indexPath = IndexPath(row: row, section: feedSection)
        let currentCell = simulateFeedImageCellIsVisible(at: row)
        tableView(tableView, didEndDisplaying: currentCell, forRowAt: indexPath)
        return currentCell
    }

    @discardableResult
    func simulateItemCellWillBecomeVisible(at row: Int) -> UITableViewCell {
        let indexPath = IndexPath(row: row, section: feedSection)
        let currentCell = simulateFeedImageCellNotVisible(at: row)
        tableView.delegate?.tableView?(tableView, willDisplay: currentCell, forRowAt: indexPath)
        return currentCell
    }

    func simulateTapOnFeedImage(at row: Int) {
        simulateFeedImageCellIsVisible(at: row)
        tableView(tableView, didSelectRowAt: IndexPath(row: row, section: feedSection))
    }

    var isShowingLoadingMoreIndicator: Bool {
        let loadMoreIndexPath = IndexPath(row: 0, section: loadMoreSection)
        let dataSource = tableView.dataSource

        let numberOfSections = dataSource?.numberOfSections?(in: tableView)
        guard let numberOfSections = numberOfSections, numberOfSections > loadMoreSection else { return false }

        guard let cell = dataSource?.tableView(tableView, cellForRowAt: loadMoreIndexPath) as? LoadMoreCell else { return false }

        return cell.isLoading
    }

    func loadMoreCell() -> LoadMoreCell? {
        let loadMoreIndexPath = IndexPath(row: 0, section: loadMoreSection)
        let dataSource = tableView.dataSource

        let numberOfSections = dataSource?.numberOfSections?(in: tableView)
        guard let numberOfSections = numberOfSections, numberOfSections > loadMoreSection else { return nil }

        guard let cell = dataSource?.tableView(tableView, cellForRowAt: loadMoreIndexPath) as? LoadMoreCell else { return nil }

        return cell
    }

    var loadMoreErrorMessage: String? {
        loadMoreCell()?.errorMessage

    }

    func simulateLoadMoreFeedImages() {
        let loadMoreIndexPath = IndexPath(row: 0, section: loadMoreSection)

        guard let cell = loadMoreCell() else { return }

        let delegate = tableView.delegate
        delegate?.tableView?(tableView, willDisplay: cell, forRowAt: loadMoreIndexPath)
    }

    private var loadMoreSection: Int {
        1
    }
}

// MARK: - ImageCommentsViewController helpers

extension ListViewController {
    var commentsSection: Int {
        0
    }

    var numberOfImageComments: Int {
        tableView.numberOfRows(inSection: commentsSection)
    }

    func imageCommentCell(at row: Int) -> UITableViewCell {
        let indexPath = IndexPath(row: row, section: commentsSection)
        return tableView.dataSource!.tableView(tableView, cellForRowAt: indexPath)
    }
}
