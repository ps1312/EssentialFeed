import UIKit
import Combine
import EssentialFeed
import EssentialFeediOS

public class ImageCommentsUIComposer {
    public static func composeWith(loader: @escaping () -> AnyPublisher<[ImageComment], Error>) -> ListViewController {
        let adapter = LoadResourcePresentationAdapter<[ImageComment], ImageCommentsViewAdapter>(loader: { loader().dispatchOnMainQueue() })

        let viewController = ListViewController.makeWith(title: ImageCommentsPresenter.title, delegate: adapter)
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

private extension ListViewController {
    static func makeWith(title: String, delegate: LoadResourceViewControllerDelegate) -> ListViewController {
        let bundle = Bundle(for: ListViewController.self)
        let storyboard = UIStoryboard(name: "ImageComments", bundle: bundle)
        let controller = storyboard.instantiateInitialViewController() as! ListViewController
        controller.title = title
        controller.delegate = delegate

        return controller
    }
}
