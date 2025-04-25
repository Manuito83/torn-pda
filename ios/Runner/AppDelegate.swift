import UIKit
import Flutter
import UserNotifications        // for UNUserNotificationCenter
import MachO                   // for task_info APIs
import Darwin                  // for host_statistics64

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
        let memoryChannel = FlutterMethodChannel(name: "tornpda/memory", binaryMessenger: controller.binaryMessenger)
        
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
        
        memoryChannel.setMethodCallHandler { call, result in
            // Prevent uncaught errors from crashing the app
            do {
                switch call.method {
                    case "getMemoryInfoDetailed":
                        var info = task_vm_info_data_t()
                        var count = mach_msg_type_number_t(
                            MemoryLayout<task_vm_info_data_t>.stride
                            / MemoryLayout<integer_t>.stride
                        )
                        let kr = withUnsafeMutablePointer(to: &info) {
                            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
                            }
                        }
                        guard kr == KERN_SUCCESS else {
                            throw NSError(domain: NSPOSIXErrorDomain, code: Int(kr), userInfo: nil)
                        }

                        let resident     = Int(info.phys_footprint)   // bytes
                        let compressed   = Int(info.compressed)       // bytes
                        let external     = Int(info.external)         // bytes
                        let privateBytes = max(0, resident - compressed - external)

                        result([
                            "private":    privateBytes,
                            "compressed": compressed,
                            "external":   external,
                            "total":      resident
                        ])

                    case "getDeviceMemoryInfo":
                        // Total RAM via sysctl
                        var size: UInt64 = 0
                        var sizeOfSize = MemoryLayout<UInt64>.stride
                        let sysctlResult = sysctlbyname("hw.memsize", &size, &sizeOfSize, nil, 0)
                        guard sysctlResult == 0 else {
                            throw NSError(domain: NSPOSIXErrorDomain, code: Int(sysctlResult), userInfo: nil)
                        }
                        let totalMem = Int(size)

                        // Free + inactive pages via host_statistics64
                        var vmStats = vm_statistics64_data_t()
                        var count2 = mach_msg_type_number_t(
                            MemoryLayout<vm_statistics64_data_t>.stride
                            / MemoryLayout<integer_t>.stride
                        )
                        let hostPort = mach_host_self()
                        let kr2 = withUnsafeMutablePointer(to: &vmStats) {
                            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count2)) {
                                host_statistics64(
                                    hostPort,
                                    HOST_VM_INFO64,
                                    $0,
                                    &count2
                                )
                            }
                        }
                        guard kr2 == KERN_SUCCESS else {
                            throw NSError(domain: NSPOSIXErrorDomain, code: Int(kr2), userInfo: nil)
                        }

                        let pageSize = Int(vm_kernel_page_size)
                        var freePages = Int(vmStats.free_count) + Int(vmStats.inactive_count)
                        // Include speculative pages on iOS 13+
                        if #available(iOS 13.0, *) {
                            freePages += Int(vmStats.speculative_count)
                        }
                        let freeMem = freePages * pageSize

                        result([
                            "totalMem": totalMem,
                            "availMem": freeMem
                        ])

                    default:
                        result(FlutterMethodNotImplemented)
                    }

            } catch {
                result(FlutterError(
                    code:    "METHOD_CHANNEL_ERROR",
                    message: "Unexpected error: \(error.localizedDescription)",
                    details: nil
                ))
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