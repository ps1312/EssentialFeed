import Combine
import UIKit
import EssentialFeed
import EssentialFeediOS

public class ImageCommentsUIComposer {
    public static func composeWith(loader: @escaping () -> AnyPublisher<[ImageComment], Error>) -> ImageCommentsViewController {
        let adapter = LoadResourcePresentationAdapter<[ImageComment], ImageCommentsViewAdapter>(loader: loader)

        let viewController = ImageCommentsViewController.makeWith(title: ImageCommentsPresenter.title, delegate: adapter)
        let view = ImageCommentsViewAdapter()
        view.controller = viewController

        adapter.presenter = LoadResourcePresenter<[ImageComment], ImageCommentsViewAdapter>(
            loadingView: WeakRefVirtualProxy(viewController),
            errorView: WeakRefVirtualProxy(viewController),
            resourceView: view,
            mapper: { _ in return ImageCommentsViewModel(comments: []) }
        )

        return viewController
    }
}

private extension ImageCommentsViewController {
    static func makeWith(title: String, delegate: ImageCommentsViewControllerDelegate) -> ImageCommentsViewController {
        let bundle = Bundle(for: ImageCommentsViewController.self)
        let storyboard = UIStoryboard(name: "ImageComments", bundle: bundle)
        let controller = storyboard.instantiateInitialViewController() as! ImageCommentsViewController
        controller.title = title
        controller.delegate = delegate

        return controller
    }
}
