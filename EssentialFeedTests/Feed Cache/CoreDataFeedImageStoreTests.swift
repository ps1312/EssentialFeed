import XCTest
import EssentialFeed

class CoreDataFeedImageStoreTests: XCTestCase {
    func test_insert_deliversErrorOnAlwaysFailingStore() {
        let sut = makeSUT()
        let stub = NSManagedObjectContext.setupAlwaysFailingSaveStub()
        let exp = expectation(description: "wait for insertion to complete")

        stub.startIntercepting()
        sut.insert(url: makeURL(), with: makeData()) { error in
            XCTAssertNotNil(error, "Expected insert to fail on always failing core data context")
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    func test_retrieve_deliversErrorOnStoreFailure() {
        let sut = makeSUT()
        let stub = NSManagedObjectContext.setupAlwaysFailingFetchStub()
        let exp = expectation(description: "wait for insertion to complete")

        stub.startIntercepting()
        sut.retrieve(from: makeURL()) { error in
            XCTAssertNotNil(error, "Expected insert to fail on always failing core data context")
            exp.fulfill()
        }

        wait(for: [exp], timeout: 1.0)
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CoreDataFeedImageStore {
        let inMemoryStoreURL = URL(fileURLWithPath: "/dev/null")
        let store = try! CoreDataFeedImageStore(storeURL: inMemoryStoreURL)

        testMemoryLeak(store, file: file, line: line)

        return store
    }
}
