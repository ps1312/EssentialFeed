import XCTest
import EssentialFeediOS
@testable import EssentialApp

class SceneDelegateTests: XCTestCase {

    func test_sceneWillConnectToSession_configuresWindow() {
        let window = UIWindow()
        let sut = SceneDelegate()
        sut.window = window

        sut.configureView()

        let root = sut.window?.rootViewController as! UINavigationController
        XCTAssertNotNil(root, "Expect root view controller attached to window to be an UINavigationController")
        XCTAssertNotNil(root.topViewController as! ListViewController, "Expected navigation top view controller to be a FeedViewController")
    }

    func test_configureView_makesWindowAsKeyAndVisible() {
        let window = UIWindowSpy()

        let sut = SceneDelegate()
        sut.window = window

        sut.configureView()

        XCTAssertEqual(window.makeKeyAndVisibleCallCount, 1, "Expected to make window key and visible")
    }

}

private class UIWindowSpy: UIWindow {
  var makeKeyAndVisibleCallCount = 0
  override func makeKeyAndVisible() {
    makeKeyAndVisibleCallCount = 1
  }
}
