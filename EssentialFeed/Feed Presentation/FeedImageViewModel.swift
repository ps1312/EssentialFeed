public struct FeedImageViewModel {
    public let description: String?
    public let location: String?

    public init(description: String?, location: String?) {
        self.description = description
        self.location = location
    }

    public var hasDescription: Bool {
        return description != nil
    }

    public var hasLocation: Bool {
        return location != nil
    }
}
