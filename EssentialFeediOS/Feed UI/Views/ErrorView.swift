import UIKit

public class ErrorView {
    public let errorLabel = UILabel()

    func display(message: String) {
        errorLabel.text = message
    }
}
