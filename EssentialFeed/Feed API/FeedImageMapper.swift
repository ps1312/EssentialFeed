import Foundation

public final class FeedImageMapper {
    struct EmptyDataError: Error {}

    public static func map(_ data: Data, from response: HTTPURLResponse) throws -> Data {
        guard !data.isEmpty else { throw EmptyDataError() }
        return data
    }
}
