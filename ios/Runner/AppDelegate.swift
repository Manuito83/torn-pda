import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Set up the delegate for local notifications
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().delegate = self
        }
        
        GeneratedPluginRegistrant.register(with: self)

        // Set up the Flutter channel to handle icon changes
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let iconChannel = FlutterMethodChannel(name: "tornpda/icon", binaryMessenger: controller.binaryMessenger)
        
        iconChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
            if call.method == "changeIcon" {
                // Handle the passed arguments properly
                if let args = call.arguments as? [String: Any],
                   let iconName = args["iconName"] as? String? {
                    self.setApplicationIconName(iconName, result: result)
                } else {
                    // No arguments means reset to default
                    self.setApplicationIconName(nil, result: result)
                }
            } else {
                result(FlutterMethodNotImplemented)
            }
        }

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    // Method to change the app icon, checking the current icon to avoid unnecessary changes
    private func setApplicationIconName(_ iconName: String?, result: @escaping FlutterResult) {
        guard UIApplication.shared.supportsAlternateIcons else {
            result(FlutterError(code: "UNSUPPORTED", message: "Alternate icons are not supported", details: nil))
            return
        }

        // Get the current icon name
        let currentIconName = UIApplication.shared.alternateIconName

        // Avoid changing the icon if the current icon is already set
        if currentIconName == iconName {
            result(nil) // Icon is already set, no need to change it
            return
        }

        // Change to the specified icon or reset to default if `iconName` is `nil`
        UIApplication.shared.setAlternateIconName(iconName) { (error) in
            if let error = error {
                result(FlutterError(code: "ICON_CHANGE_FAILED", message: error.localizedDescription, details: nil))
            } else {
                result(nil)
            }
        }
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
