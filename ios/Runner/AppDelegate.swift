import UIKit
import Flutter

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
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Quick_actions fix, refer to https://github.com/flutter/flutter/issues/13634
  @available(iOS 9.0, *)
  override func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
  let controller = window.rootViewController as? FlutterViewController
  let channel = FlutterMethodChannel(name: "plugins.flutter.io/quick_actions", binaryMessenger: controller! as! FlutterBinaryMessenger)
  channel.invokeMethod("launch", arguments: shortcutItem.type)
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
