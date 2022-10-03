import Foundation

public class RemoteImageLoader: FeedImageLoader {
    private let client: HTTPClient

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    struct RemoteFeedImageLoaderTask: FeedImageLoaderTask {
        let task: HTTPClientTask

        func cancel() {
            task.cancel()
        }
    }

    public init(client: HTTPClient) {
        self.client = client
    }

    public func load(from url: URL, completion: @escaping (FeedImageLoader.Result) -> Void) -> FeedImageLoaderTask {
        let httpTask = client.get(from: url) { [weak self] result in
            guard self != nil else { return }

            switch (result) {
            case .failure:
                completion(.failure(Error.connectivity))

            case let .success((data, response)):
                if response.statusCode == 200, !data.isEmpty {
                    completion(.success(data))
                } else {
                    completion(.failure(Error.invalidData))
                }

            }
        }

        return RemoteFeedImageLoaderTask(task: httpTask)
    }
}
