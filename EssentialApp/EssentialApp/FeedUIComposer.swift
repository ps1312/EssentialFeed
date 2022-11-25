import UIKit
import Combine
import EssentialFeed
import EssentialFeediOS

public final class FeedUIComposer {
    public static func composeWith(
        onFeedImageTap: @escaping (FeedImage) -> Void,
        loader: @escaping () -> AnyPublisher<Paginated<FeedImage>, Error>,
        imageLoader: @escaping (URL) -> FeedImageLoader.Publisher
    ) -> ListViewController {
        let adapter = LoadResourcePresentationAdapter<Paginated<FeedImage>, FeedViewAdapter>(loader: loader)
        let viewController = ListViewController.makeWith(
            title: FeedPresenter.title,
            onRefresh: adapter.loadResource,
            storyboardName: "Feed"
        )
        let view = FeedViewAdapter(onFeedImageTap: onFeedImageTap, imageLoader: { imageLoader($0) })
        view.controller = viewController

        adapter.presenter = LoadResourcePresenter<Paginated<FeedImage>, FeedViewAdapter>(
            loadingView: WeakRefVirtualProxy(viewController),
            errorView: WeakRefVirtualProxy(viewController),
            resourceView: view,
            mapper: { $0 }
        )

        return viewController
    }
}
