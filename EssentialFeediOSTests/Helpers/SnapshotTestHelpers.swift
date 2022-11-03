import Foundation
import UIKit
import XCTest

func assert(snapshot: UIImage, named: String, file: StaticString = #file, line: UInt = #line) {
    let snapshotData = makeSnapshotData(snapshot: snapshot)
    let snapshotURL = makeSnapshotURL(file: String(describing: file), name: named)

    guard let storedSnapshotData = try? Data(contentsOf: snapshotURL) else {
        XCTFail("Failed to load stored snapshot at URL: \(snapshotURL). Use the `record` method to store a snapshot before asserting.", file: file, line: line)
        return
    }

    if snapshotData != storedSnapshotData {
        let temporarySnapshotURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(snapshotURL.lastPathComponent)

        try? snapshotData?.write(to: temporarySnapshotURL)

        XCTFail("New snapshot does not match stored snapshot. New snapshot URL: \(temporarySnapshotURL), Stored snapshot URL: \(snapshotURL)", file: file, line: line)
    }
}

func record(snapshot: UIImage, named: String, file: StaticString = #file, line: UInt = #line) {
    let snapshotData = makeSnapshotData(snapshot: snapshot)
    let snapshotURL = makeSnapshotURL(file: String(describing: file), name: named)

    do {
        try FileManager.default.createDirectory(at: snapshotURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try snapshotData?.write(to: snapshotURL)

        XCTFail("Recorded snapshot - use `assert` now to make the images comparisson", file: file, line: line)
    } catch {
        XCTFail("Failed to record snapshot image PNG", file: file, line: line)
    }
}

func makeSnapshotData(snapshot: UIImage, file: StaticString = #file, line: UInt = #line) -> Data? {
    guard let snapshotData = snapshot.pngData() else {
        XCTFail("Failed to generate SUT snapshot data", file: file, line: line)
        return nil
    }
    return snapshotData
}

func makeSnapshotURL(file: String, name: String) -> URL {
    return URL(filePath: "\(file)").deletingLastPathComponent().appending(component: "snapshots").appending(component: "\(name).png")
}
