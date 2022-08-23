import Foundation

public class URLSessionHTTPClient: HTTPClient {
    struct UnexpectedResultValues: Error {}

    private let session: URLSession

    public typealias Result = HTTPClientResult

    public init (session: URLSession = .shared) {
        self.session = session
    }

    public func get(from url: URL, completion: @escaping (Result) -> Void) {
        session.dataTask(with: url) { data, response, error in
            if let error = error {
                return completion(.failure(error))
            }

            guard let data = data, let response = response as? HTTPURLResponse else {
                return completion(.failure(UnexpectedResultValues()))
            }

            completion(.success((data, response)))
        }.resume()
    }
}
