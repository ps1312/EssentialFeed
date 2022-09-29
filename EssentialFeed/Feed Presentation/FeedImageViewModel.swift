public struct FeedImageViewModel<Image> {
    public let isLoading: Bool
    public let shouldRetry: Bool
    public let image: Image?
    public let description: String?
    public let location: String?

    public init(isLoading: Bool, shouldRetry: Bool, image: Image?, description: String?, location: String?) {
        self.isLoading = isLoading
        self.shouldRetry = shouldRetry
        self.image = image
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
