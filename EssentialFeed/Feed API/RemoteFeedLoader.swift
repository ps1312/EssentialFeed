import Foundation

public typealias HTTPClientResult = Result<(Data, HTTPURLResponse), Error>

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}

public final class RemoteFeedLoader {
    private let url: URL
    private let client: HTTPClient

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public typealias Result = Swift.Result<[FeedItem], Error>

    public init(url: URL, client: HTTPClient) {
        self.url = url
        self.client = client
    }

    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { result in
            switch (result) {
            case let .success((data, response)):
                guard response.statusCode == 200, let _ = try? JSONDecoder().decode(Root.self, from: data) else {
                    completion(.failure(.invalidData))
                    return
                }

                completion(.success([]))
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}

struct Root: Decodable {
    struct ApiItem: Decodable {
        var id: UUID
        var description: String?
        var location: String?
        var image: URL?
    }

    var items = [ApiItem]()
}
