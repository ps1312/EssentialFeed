import XCTest
import EssentialFeed

class CoreDataFeedStoreTests: XCTestCase, FailableFeedStoreSpec {
    func test_retrieve_deliversEmptyOnEmptyCache() {
        let sut = makeSUT()

        assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }

    func test_retrieve_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()

        assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
    }

    func test_retrieve_deliversDataOnNonEmptyCache() {
        let sut = makeSUT()

        assertThatRetrieveDeliversDataOnNonEmptyCache(on: sut)
    }

    func test_retrieve_hasNoSideEffectsOnNonEmptyCache() {
        let sut = makeSUT()

        assertThatRetrieveHasNoSideEffectsOnEmptyCache(on: sut)
    }

    func test_insert_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()

        assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
    }

    func test_insert_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()

        assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
    }

    func test_insert_overridesPreviouslyInsertedValues() {
        let sut = makeSUT()

        assertThatInsertOverridesPreviouslyInsertedValues(on: sut)
    }

    func test_delete_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()

        assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
    }

    func test_delete_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()

        assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
    }

    func test_delete_hasNoSideEffectsOnEmptyCache() {
        let sut = makeSUT()

        assertThatDeleteHasNoSideEffectsOnEmptyCache(on: sut)
    }

    func test_delete_emptiesPreviouslyInsertedCache() {
        let sut = makeSUT()

        assertThatDeleteEmptiesPreviouslyInsertedCache(on: sut)
    }

    func test_storeSideEffects_runSerially() {
        let sut = makeSUT()

        assertThatStoreSideEffectsRunSerially(on: sut)
    }

    func test_retrieve_deliversErrorOnRetrievalFailure() {
        let stub = NSManagedObjectContext.setupAlwaysFailingFetchStub()
        stub.startIntercepting()

        let sut = makeSUT()

        assertThatRetrieveDeliversErrorOnRetrievalFailure(on: sut)
    }

    func test_retrieve_hasNoSideEffectsOnFailure() {
        let stub = NSManagedObjectContext.setupAlwaysFailingFetchStub()
        stub.startIntercepting()

        let sut = makeSUT()

        assertThatRetrieveHasNoSideEffectsOnFailure(on: sut)
    }

    func test_insert_deliversErrorOnInsertionFailure() {
        let stub = NSManagedObjectContext.setupAlwaysFailingSaveStub()
        stub.startIntercepting()

        let sut = makeSUT()

        assertThatInsertDeliversErrorOnInsertionFailure(on: sut)
    }

    func test_insert_hasNoSideEffectsOnFailure() {
        let stub = NSManagedObjectContext.setupAlwaysFailingSaveStub()
        stub.startIntercepting()

        let sut = makeSUT()

        assertThatInsertHasNoSideEffectsOnFailure(on: sut)
    }

    func test_delete_deliversErrorOnDeletionFailure() {

    }

    func test_delete_hasNoSideEffectsOnFailure() {

    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CoreDataFeedStore {
        let inMemoryStoreURL = URL(fileURLWithPath: "/dev/null")
        let sut = try! CoreDataFeedStore(storeURL: inMemoryStoreURL)

        testMemoryLeak(sut, file: file, line: line)

        return sut
    }
    
}

extension NSManagedObjectContext {
    static func setupAlwaysFailingFetchStub() -> Stub {
        Stub(
            #selector(NSManagedObjectContext.__execute(_:)),
            #selector(Stub.execute(_:))
        )
    }

    static func setupAlwaysFailingSaveStub() -> Stub {
        Stub(
            #selector(NSManagedObjectContext.save),
            #selector(Stub.save)
        )
    }

    class Stub: NSObject {
        private let source: Selector
        private let destination: Selector

        init(_ source: Selector, _ destination: Selector) {
            self.source = source
            self.destination = destination
        }

        @objc func execute(_: Any) throws -> Any {
            throw makeNSError()
        }

        @objc func save() throws {
            throw makeNSError()
        }

        func startIntercepting() {
            method_exchangeImplementations(
                class_getInstanceMethod(NSManagedObjectContext.self, source)!,
                class_getInstanceMethod(Stub.self, destination)!
            )
        }

        deinit {
            method_exchangeImplementations(
                class_getInstanceMethod(Stub.self, destination)!,
                class_getInstanceMethod(NSManagedObjectContext.self, source)!
            )
        }
    }
}
