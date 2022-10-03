import Foundation

public class RemoteImageLoader: FeedImageLoader {
    private let client: HTTPClient

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    private final class RemoteImageLoaderTask: FeedImageLoaderTask {
        private var completion: ((FeedImageLoader.Result) -> Void)?
        var task: HTTPClientTask?

        init(_ completion: @escaping (FeedImageLoader.Result) -> Void) {
            self.completion = completion
        }

        func complete(_ result: FeedImageLoader.Result) {
            completion?(result)
        }

        func cancel() {
            task?.cancel()
            preventFurtherCompletions()
        }

        private func preventFurtherCompletions() {
            completion = nil
        }
    }

    public init(client: HTTPClient) {
        self.client = client
    }

    public func load(from url: URL, completion: @escaping (FeedImageLoader.Result) -> Void) -> FeedImageLoaderTask {
        let remoteTask = RemoteImageLoaderTask(completion)
        remoteTask.task = client.get(from: url) { [weak self] result in
            guard self != nil else { return }

            switch (result) {
            case .failure:
                remoteTask.complete(.failure(Error.connectivity))

            case let .success((data, response)):
                if response.statusCode == 200, !data.isEmpty {
                    remoteTask.complete(.success(data))
                } else {
                    remoteTask.complete(.failure(Error.invalidData))
                }

            }
        }

        return remoteTask
    }
}
