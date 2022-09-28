import UIKit

public class ErrorView: UIView {
    public let button = UIButton()

    public var isVisible: Bool {
        return alpha > 0
    }

    func display(message: String) {
        button.setTitle(message, for: .normal)
        alpha = 1
    }

    func hideMessage() {
        button.setTitle(nil, for: .normal)
        alpha = 0
    }
}
