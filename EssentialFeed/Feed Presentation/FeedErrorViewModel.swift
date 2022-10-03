public struct FeedErrorViewModel: Equatable {
    public var message: String?

    public init(message: String?) {
        self.message = message
    }

    public static var noError: FeedErrorViewModel {
        return FeedErrorViewModel(message: nil)
    }

    public static func error(message: String) -> FeedErrorViewModel {
        return FeedErrorViewModel(message: message)
    }
}
