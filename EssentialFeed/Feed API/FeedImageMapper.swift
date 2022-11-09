import Foundation

public final class FeedImageMapper {
    public enum Error: Swift.Error {
        case noData
        case invalidData
    }

    public static func map(_ data: Data, from response: HTTPURLResponse) throws -> Data {
        guard !data.isEmpty else { throw Error.noData }
        guard response.statusCode == OK_200 else { throw Error.invalidData }

        return data
    }

    private static let OK_200 = 200
}
