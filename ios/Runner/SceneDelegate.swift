import Flutter
import UIKit

class SceneDelegate: FlutterSceneDelegate {
  private var appDelegate: AppDelegate? { UIApplication.shared.delegate as? AppDelegate }

  override func scene(
    _ scene: UIScene, willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    super.scene(scene, willConnectTo: session, options: connectionOptions)
    if let vc = (scene as? UIWindowScene)?.windows.first?.rootViewController {
      objc_setAssociatedObject(vc, "deallocTrail", DeallocTrail(), .OBJC_ASSOCIATION_RETAIN)
    }
    appDelegate?.trail("sceneWillConnect")
  }

  override func sceneDidDisconnect(_ scene: UIScene) {
    appDelegate?.trail("sceneDidDisconnect")
    super.sceneDidDisconnect(scene)
  }

  override func sceneDidEnterBackground(_ scene: UIScene) {
    appDelegate?.trail("sceneDidEnterBackground")
    super.sceneDidEnterBackground(scene)
  }

  override func sceneWillEnterForeground(_ scene: UIScene) {
    appDelegate?.trail("sceneWillEnterForeground")
    super.sceneWillEnterForeground(scene)
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    appDelegate?.trail("sceneDidBecomeActive")
    appDelegate?.handleSceneDidBecomeActive()
  }
}
