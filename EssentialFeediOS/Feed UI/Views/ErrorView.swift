import UIKit

public class ErrorView {
    public let button = UIButton()

    func display(message: String) {
        button.setTitle(message, for: .normal)
    }

    func hideMessage() {
        button.setTitle(nil, for: .normal)
    }
}
