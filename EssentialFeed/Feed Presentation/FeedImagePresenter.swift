import Foundation

public class FeedImagePresenter {

    public static func map(_ model: FeedImage) -> FeedImageViewModel {
        FeedImageViewModel(description: model.description, location: model.location)
    }

}
