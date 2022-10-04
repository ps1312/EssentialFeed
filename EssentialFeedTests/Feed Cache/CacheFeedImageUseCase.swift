import XCTest
import EssentialFeed

class CacheFeedImageUseCase: XCTestCase {
    func test_init_doesNotMessageStore() {
        let (_ , store) = makeSUT()
        XCTAssertTrue(store.messages.isEmpty, "Expected no collaboration with store yet")
    }

    func test_save_messagesStoreToSaveDataInURL() {
        let url = makeURL()
        let data = makeData()
        let (sut, store) = makeSUT()

        sut.save(url: url, with: data) { _ in }

        XCTAssertEqual(store.messages, [.insert(url, data)], "Expected save to message store to insert image data in a url")
    }

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedImageLoader, FeedImageStoreSpy) {
        let store = FeedImageStoreSpy()
        let sut = LocalFeedImageLoader(store: store)

        testMemoryLeak(store, file: file, line: line)
        testMemoryLeak(sut, file: file, line: line)

        return (sut, store)
    }

    private class FeedImageStoreSpy: FeedImageStore {
        enum Message: Equatable {
            case retrieve(from: URL)
            case insert(URL, Data)
        }
        var messages = [Message]()
        var retrievalCompletions = [RetrievalCompletion]()
        var insertCompletions = [InsertCompletion]()

        func retrieve(from url: URL, completion: @escaping RetrievalCompletion) {
            messages.append(.retrieve(from: url))
            retrievalCompletions.append(completion)
        }

        func completeRetrieve(with error: Error, at index: Int = 0) {
            retrievalCompletions[index](.failure(error))
        }

        func completeRetrieve(with data: Data, at index: Int = 0) {
            retrievalCompletions[index](.success(data))
        }

        func insert(url: URL, with data: Data, completion: @escaping InsertCompletion) {
            messages.append(.insert(url, data))
            insertCompletions.append(completion)
        }

        func completeInsert(with error: Error, at index: Int = 0) {
            insertCompletions[index](error)
        }

        func completeInsertWithSuccess(at index: Int = 0) {
            insertCompletions[index](nil)
        }
    }
}
