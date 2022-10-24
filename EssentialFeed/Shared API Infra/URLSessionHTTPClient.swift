import Foundation

public class URLSessionHTTPClient: HTTPClient {
    private struct UnexpectedValuesError: Error {}

    private let session: URLSession

    public typealias Result = HTTPClientResult

    public init (session: URLSession = .shared) {
        self.session = session
    }

    struct URLSessionHTTPClientTask: HTTPClientTask {
        let task: URLSessionDataTask

        func cancel() {
            task.cancel()
        }
    }

    public func get(from url: URL, completion: @escaping (Result) -> Void) -> HTTPClientTask {
        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                return completion(.failure(error))
            }

            guard let data = data, let response = response as? HTTPURLResponse else {
                return completion(.failure(UnexpectedValuesError()))
            }

            completion(.success((data, response)))
        }
        task.resume()
        return URLSessionHTTPClientTask(task: task)
    }
}
