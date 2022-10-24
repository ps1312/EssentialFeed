import Foundation

public final class RemoteLoader<T> {
    private let url: URL
    private let client: HTTPClient
    private let mapper: (Data, HTTPURLResponse) throws -> T

    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }

    public typealias Result = Swift.Result<T, Swift.Error>

    public init(url: URL, client: HTTPClient, mapper: @escaping (Data, HTTPURLResponse) throws -> T) {
        self.url = url
        self.client = client
        self.mapper = mapper
    }

    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { [weak self] result in
            guard let self = self else { return }

            switch (result) {
            case let .success((data, response)):
                do {
                    completion(.success(try self.mapper(data, response)))
                } catch {
                    completion(.failure(Error.invalidData))
                }

            case .failure:
                completion(.failure(Error.connectivity))
            }
        }
    }
}
