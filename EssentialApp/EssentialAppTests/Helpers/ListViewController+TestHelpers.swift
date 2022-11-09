import Foundation
import UIKit
@testable import EssentialFeediOS

extension ListViewController {
    var itemsSection: Int {
        0
    }

    var numberOfItems: Int {
        tableView.numberOfRows(inSection: itemsSection)
    }

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

    func itemCell(at row: Int) -> UITableViewCell {
        let indexPath = IndexPath(row: row, section: itemsSection)
        return tableView.dataSource!.tableView(tableView, cellForRowAt: indexPath)
    }

    @discardableResult
    func simulateItemCellIsDisplayed(at row: Int) -> UITableViewCell {
        itemCell(at: row)
    }

    @discardableResult
    func simulateItemCellEndsDiplaying(at row: Int) -> UITableViewCell {
        let indexPath = IndexPath(row: row, section: itemsSection)
        let currentCell = simulateItemCellIsDisplayed(at: row)
        tableView(tableView, didEndDisplaying: currentCell, forRowAt: indexPath)
        return currentCell
    }

    func simulateItemCellPrefetch(at row: Int) {
        let indexPath = IndexPath(row: row, section: itemsSection)
        tableView(tableView, prefetchRowsAt: [indexPath])
    }

    func simulateItemCellPrefetchingCanceling(at row: Int) {
        simulateItemCellPrefetch(at: row)

        let ds = tableView.prefetchDataSource
        let indexPath = IndexPath(row: row, section: itemsSection)
        ds?.tableView?(tableView, cancelPrefetchingForRowsAt: [indexPath])
    }
}
