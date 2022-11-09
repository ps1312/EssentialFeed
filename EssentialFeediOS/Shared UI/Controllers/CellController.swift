import Foundation
import UIKit

public struct CellController: Equatable, Hashable {
    public let id: UUID
    public let dataSource: UITableViewDataSource
    public let delegate: UITableViewDelegate?
    public let prefetch: UITableViewDataSourcePrefetching?

    public init(id: UUID = UUID(), _ source: UITableViewDataSource & UITableViewDelegate & UITableViewDataSourcePrefetching) {
        self.id = id
        self.dataSource = source
        self.delegate = source
        self.prefetch = source
    }

    public init(id: UUID = UUID(), _ dataSource: UITableViewDataSource) {
        self.id = id
        self.dataSource = dataSource
        self.delegate = nil
        self.prefetch = nil
    }

    public static func == (lhs: CellController, rhs: CellController) -> Bool {
        lhs.id == rhs.id
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
