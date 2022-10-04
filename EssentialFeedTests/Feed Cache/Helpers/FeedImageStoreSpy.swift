import Foundation
import EssentialFeed

final class FeedImageStoreSpy: FeedImageStore {
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
