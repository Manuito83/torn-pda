import UIKit
import Flutter
//import flutter_downloader

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if #available(iOS 10.0, *) {
        UNUserNotificationCenter.current().delegate = self as?
        UNUserNotificationCenterDelegate
    }
    GeneratedPluginRegistrant.register(with: self)
    //FlutterDownloaderPlugin.setPluginRegistrantCallback(registerPlugins)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
    
  /*
  override func applicationDidBecomeActive(_ application: UIApplication) {
    if #available(iOS 14.0, *) {
      WidgetCenter.shared.getCurrentConfigurations { (result) in
        guard let widgets = try? result.get() else { return }
        widgets.forEach { (widget) in
          print(widget.debugDescription)
        }
      }
    }
  }
  */
}

/*
private func registerPlugins(registry: FlutterPluginRegistry) {
    if (!registry.hasPlugin("FlutterDownloaderPlugin")) {
       FlutterDownloaderPlugin.register(with: registry.registrar(forPlugin: "FlutterDownloaderPlugin")!)
    }
}
*/

// Flutter 2.2.3 USB keyboard fix
extension FlutterViewController {
    open override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesBegan(presses, with: event)
    }

    open override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesEnded(presses, with: event)
    }

    open override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        super.pressesCancelled(presses, with: event)
    }
}
