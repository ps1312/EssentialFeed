import Foundation

extension CoreDataFeedStore: FeedImageStore {
    public func insert(url: URL, with data: Data, completion: @escaping InsertCompletion) {
        perform { context in
            do {
                let model = try ManagedFeedImage.findBy(url: url)
                model?.data = data

                try context.save()
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }

    public func retrieve(from url: URL, completion: @escaping RetrievalCompletion) {
        perform { context in
            do {
                if let imageData = context.userInfo[url] as? Data {
                    return completion(.found(imageData))
                }
                
                guard let model = try ManagedFeedImage.findBy(url: url), let imageData = model.data else {
                    return completion(.empty)
                }

                completion(.found(imageData))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
