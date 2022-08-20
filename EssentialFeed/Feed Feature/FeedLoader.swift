import Foundation

protocol FeedLoader {
    func load(completion: Result<[FeedItem], Error>)
}
