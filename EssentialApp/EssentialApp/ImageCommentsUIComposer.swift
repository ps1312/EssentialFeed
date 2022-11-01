import Foundation
import UIKit
import EssentialFeed
import EssentialFeediOS

public class ImageCommentsUIComposer {

    public static func composeWith() -> ImageCommentsViewController {
        let bundle = Bundle(for: ImageCommentsViewController.self)
        let storyboard = UIStoryboard(name: "ImageComments", bundle: bundle)

        let view = storyboard.instantiateInitialViewController() as! ImageCommentsViewController
        view.title = ImageCommentsPresenter.title

        return view
    }

}
