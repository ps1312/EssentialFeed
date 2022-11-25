import UIKit
import Combine
import EssentialFeed
import EssentialFeediOS

public class ImageCommentsUIComposer {
    public static func composeWith(loader: @escaping () -> AnyPublisher<[ImageComment], Error>) -> ListViewController {
        let adapter = LoadResourcePresentationAdapter<[ImageComment], ImageCommentsViewAdapter>(loader: loader)

        let viewController = ListViewController.makeWith(
            title: ImageCommentsPresenter.title,
            onRefresh: adapter.loadResource,
            storyboardName: "ImageComments"
        )
        let view = ImageCommentsViewAdapter()
        view.controller = viewController

        adapter.presenter = LoadResourcePresenter<[ImageComment], ImageCommentsViewAdapter>(
            loadingView: WeakRefVirtualProxy(viewController),
            errorView: WeakRefVirtualProxy(viewController),
            resourceView: view,
            mapper: { ImageCommentsPresenter.map($0) }
        )

        return viewController
    }
}
