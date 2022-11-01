import Foundation
import Combine
import UIKit
import EssentialFeed
import EssentialFeediOS

public class ImageCommentsUIComposer {

    public static func composeWith(commentsLoader: @escaping () -> AnyPublisher<[ImageComment], Error>) -> ImageCommentsViewController {
        let bundle = Bundle(for: ImageCommentsViewController.self)
        let storyboard = UIStoryboard(name: "ImageComments", bundle: bundle)

        let view = storyboard.instantiateInitialViewController() as! ImageCommentsViewController
        view.title = ImageCommentsPresenter.title
        view.delegate = LoadResourcePresentationAdapter<[ImageComment], ImageCommentsViewAdapter>(loader: commentsLoader)

        return view
    }

}

class ImageCommentsViewAdapter: ResourceView {

    func display(_ viewModel: ImageCommentsViewModel) {

    }

}
