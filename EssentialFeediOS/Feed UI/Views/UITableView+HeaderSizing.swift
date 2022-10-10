import UIKit

extension UITableViewController {
    func sizeTableHeaderToFit() {
        guard let header = tableView.tableHeaderView else { return }

        let size = header.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)

        // somehow the header is bigger than the size defined (like a longer error text from another language)
        let needsFrameUpdate = header.frame.height != size.height

        if needsFrameUpdate {
            header.frame.size.height = header.systemLayoutSizeFitting(UIView.layoutFittingExpandedSize).height
            tableView.tableHeaderView = header
        }
    }
}
