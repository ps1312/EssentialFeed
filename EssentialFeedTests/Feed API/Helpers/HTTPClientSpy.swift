import Foundation
import EssentialFeed

class HTTPClientSpy: HTTPClient {
    var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
    var requestedURLs: [URL] { return messages.map { $0.url } }
    var canceledURLs = [URL]()

    struct HTTCClientSpyTask: HTTPClientTask {
        var onCancel: (() -> Void)?

        func cancel() {
            onCancel?()
        }
    }

    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) -> HTTPClientTask {
        messages.append((url, completion))

        var task = HTTCClientSpyTask()
        task.onCancel = { [weak self] in
            self?.canceledURLs.append(url)
        }
        return task
    }

    func completeWith(error: Error, at index: Int = 0) {
        messages[index].completion(.failure(error))
    }

    func completeWith(statusCode: Int, data: Data, at index: Int = 0) {
        let response = HTTPURLResponse(
            url: messages[index].url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        messages[index].completion(.success((data, response)))
    }
}
