struct FeedImageViewModel<Image> {
    let isLoading: Bool
    let shouldRetry: Bool
    let image: Image?
    let description: String?
    let location: String?

    var hasDescription: Bool {
        return description != nil
    }

    var hasLocation: Bool {
        return location != nil
    }
}
