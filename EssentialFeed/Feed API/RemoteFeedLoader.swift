import Foundation

public final class RemoteFeedLoader: FeedLoader {
    private let url: URL
    private let client: HTTPClient

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public typealias Result = LoadFeedResult

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func load(completion: @escaping (LoadFeedResult) -> Void) {
        client.get(from: url) { [weak self] result in
            guard self != nil else { return }

            switch (result) {
            case let .success((data, response)):
                do {
                    let items = try FeedItemsMapper.map(data, from: response)
                    completion(.success(items))
                } catch {
                    completion(.failure(error))
                }
                break
            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }
}
