import Foundation
import Combine
import UIKit
import EssentialFeed
import EssentialFeediOS

public class ImageCommentsUIComposer {

    public static func composeWith(commentsLoader: @escaping () -> AnyPublisher<[ImageComment], Error>) -> ImageCommentsViewController {
        let adapter = LoadResourcePresentationAdapter<[ImageComment], ImageCommentsViewAdapter>(loader: commentsLoader)

        let viewController = ImageCommentsUIComposer.createControllerWith(title: ImageCommentsPresenter.title, delegate: adapter)

        let view = ImageCommentsViewAdapter()
        view.controller = viewController

        adapter.presenter = LoadResourcePresenter<[ImageComment], ImageCommentsViewAdapter>(
            loadingView: WeakRefVirtualProxy(viewController),
            errorView: WeakRefVirtualProxy(viewController),
            resourceView: view,
            mapper: { _ in return ImageCommentsViewModel(comments: []) }
        )

        viewController.delegate = adapter

        return viewController
    }

    private static func createControllerWith(title: String, delegate: ImageCommentsViewControllerDelegate) -> ImageCommentsViewController {
        let bundle = Bundle(for: ImageCommentsViewController.self)
        let storyboard = UIStoryboard(name: "ImageComments", bundle: bundle)
        let tableView = storyboard.instantiateInitialViewController() as! ImageCommentsViewController
        tableView.title = title
        tableView.delegate = delegate

        return tableView
    }

}

class ImageCommentsViewAdapter: ResourceView {
    weak var controller: ImageCommentsViewController?

    func display(_ viewModel: ImageCommentsViewModel) {
        controller?.cellControllers = viewModel.comments.map {
            ImageCommentCellController(viewModel: $0)
        }
    }

}
