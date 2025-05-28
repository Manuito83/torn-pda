// AppDelegate.swift
import ActivityKit  // For Live Activities
import Darwin  // for host_statistics64
import Flutter
import MachO  // for task_info APIs
import UIKit
import UserNotifications  // for UNUserNotificationCenter

@main
@objc class AppDelegate: FlutterAppDelegate {

  var iconChannel: FlutterMethodChannel!
  var memoryChannel: FlutterMethodChannel!

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Set up the delegate for local notifications
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    GeneratedPluginRegistrant.register(with: self)

    let controller: FlutterViewController = window?.rootViewController as! FlutterViewController

    // Set up the Flutter channel to handle icon changes
    iconChannel = FlutterMethodChannel(
      name: "tornpda/icon", binaryMessenger: controller.binaryMessenger)
    iconChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      if call.method == "changeIcon" {
        // Handle the passed arguments properly
        if let args = call.arguments as? [String: Any],
          let iconName = args["iconName"] as? String?
        {
          self.setApplicationIconName(iconName, result: result)
        } else {
          // No arguments means reset to default
          self.setApplicationIconName(nil, result: result)
        }
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    // Set up the Flutter channel to handle memory info
    memoryChannel = FlutterMethodChannel(
      name: "tornpda/memory", binaryMessenger: controller.binaryMessenger)
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

          let resident = Int(info.phys_footprint)
          let compressed = Int(info.compressed)
          let external = Int(info.external)
          let privateBytes = max(0, resident - compressed - external)

          result([
            "private": privateBytes,
            "compressed": compressed,
            "external": external,
            "total": resident,
          ])

        case "getDeviceMemoryInfo":
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
            "availMem": freeMem,
          ])

        default:
          result(FlutterMethodNotImplemented)
        }

      } catch {
        result(
          FlutterError(
            code: "METHOD_CHANNEL_ERROR",
            message: "Unexpected error: \(error.localizedDescription)",
            details: nil
          ))
      }
    }

    // MARK: - Live Activity Channel Initialization
    liveActivityChannel = FlutterMethodChannel(
      name: "com.tornpda.liveactivity",
      binaryMessenger: controller.binaryMessenger
    )

    if #available(iOS 16.2, *) {
      liveActivityChannel.setMethodCallHandler { [weak self] (call, result) in
        guard let self = self, let manager = self.typedLiveActivityManager else {
          result(
            FlutterError(
              code: "UNAVAILABLE",
              message: "LiveActivityManager not available or AppDelegate deallocated.",
              details: nil
            )
          )
          return
        }
        let args = call.arguments as? [String: Any]

        switch call.method {
        case "startTravelActivity":
          guard let currentArgs = args,
            let currentDestinationDisplayName = currentArgs["currentDestinationDisplayName"]
              as? String,
            let currentDestinationFlagAsset = currentArgs["currentDestinationFlagAsset"] as? String,
            let originDisplayName = currentArgs["originDisplayName"] as? String,
            let originFlagAsset = currentArgs["originFlagAsset"] as? String,
            let arrivalTimeTimestamp = currentArgs["arrivalTimeTimestamp"] as? Int,
            let departureTimeTimestamp = currentArgs["departureTimeTimestamp"] as? Int,
            let currentServerTimestamp = currentArgs["currentServerTimestamp"] as? Int,
            let vehicleAssetName = currentArgs["vehicleAssetName"] as? String,
            let activityStateTitle = currentArgs["activityStateTitle"] as? String,
            let showProgressBar = currentArgs["showProgressBar"] as? Bool
          else {
            result(
              FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Missing or invalid arguments for startTravelActivity.",
                details: nil
              )
            )
            return
          }
          let earliestReturnTimestamp = currentArgs["earliestReturnTimestamp"] as? Int
          Task {
            do {
              try await manager.startTravelActivity(
                currentDestinationDisplayName: currentDestinationDisplayName,
                currentDestinationFlagAsset: currentDestinationFlagAsset,
                originDisplayName: originDisplayName,
                originFlagAsset: originFlagAsset,
                arrivalTimeTimestamp: arrivalTimeTimestamp,
                departureTimeTimestamp: departureTimeTimestamp,
                currentServerTimestamp: currentServerTimestamp,
                vehicleAssetName: vehicleAssetName,
                earliestReturnTimestamp: earliestReturnTimestamp,
                activityStateTitle: activityStateTitle,
                showProgressBar: showProgressBar
              )
              result(nil)
            } catch {
              let nsError = error as NSError
              result(
                FlutterError(
                  code: "START_FAILED",
                  message: error.localizedDescription,
                  details: [
                    "domain": nsError.domain, "code": nsError.code, "userInfo": nsError.userInfo,
                  ]
                )
              )
            }
          }

        case "updateTravelActivity":
          guard let currentArgs = args,
            let currentDestinationDisplayName = currentArgs["currentDestinationDisplayName"]
              as? String,
            let currentDestinationFlagAsset = currentArgs["currentDestinationFlagAsset"] as? String,
            let originDisplayName = currentArgs["originDisplayName"] as? String,
            let originFlagAsset = currentArgs["originFlagAsset"] as? String,
            let arrivalTimeTimestamp = currentArgs["arrivalTimeTimestamp"] as? Int,
            let departureTimeTimestamp = currentArgs["departureTimeTimestamp"] as? Int,
            let currentServerTimestamp = currentArgs["currentServerTimestamp"] as? Int,
            let vehicleAssetName = currentArgs["vehicleAssetName"] as? String,
            let activityStateTitle = currentArgs["activityStateTitle"] as? String,
            let showProgressBar = currentArgs["showProgressBar"] as? Bool
          else {
            result(
              FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Missing or invalid arguments for updateTravelActivity.",
                details: nil
              )
            )
            return
          }
          let earliestReturnTimestamp = currentArgs["earliestReturnTimestamp"] as? Int
          Task {
            do {
              try await manager.updateTravelActivity(
                currentDestinationDisplayName: currentDestinationDisplayName,
                currentDestinationFlagAsset: currentDestinationFlagAsset,
                originDisplayName: originDisplayName,
                originFlagAsset: originFlagAsset,
                arrivalTimeTimestamp: arrivalTimeTimestamp,
                departureTimeTimestamp: departureTimeTimestamp,
                currentServerTimestamp: currentServerTimestamp,
                vehicleAssetName: vehicleAssetName,
                earliestReturnTimestamp: earliestReturnTimestamp,
                activityStateTitle: activityStateTitle,
                showProgressBar: showProgressBar
              )
              result(nil)
            } catch {
              let nsError = error as NSError
              result(
                FlutterError(
                  code: "UPDATE_FAILED",
                  message: error.localizedDescription,
                  details: [
                    "domain": nsError.domain, "code": nsError.code, "userInfo": nsError.userInfo,
                  ]
                )
              )
            }
          }

        case "endTravelActivity":
          Task {
            await manager.endCurrentTravelActivity()
            result(nil)
          }

        case "checkExistingActivities":
          manager.checkAndAdoptExistingActivities()
          result(nil)

        default:
          result(FlutterMethodNotImplemented)
        }
      }
      self.typedLiveActivityManager?.checkAndAdoptExistingActivities()
    } else {
      liveActivityChannel.setMethodCallHandler { (call, result) in
        print("Live Activities method '\(call.method)' called on unsupported iOS version.")
        result(
          FlutterError(
            code: "UNAVAILABLE",
            message: "Live Activities require iOS 16.2 or newer.",
            details: nil
          )
        )
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // MARK: - Properties (Live Activities)
  var liveActivityChannel: FlutterMethodChannel!

  lazy var liveActivityManagerHolder: Any? = {
    if #available(iOS 16.2, *) {
      let manager = LiveActivityManager()
      manager.onNewActivityPushToken = { [weak self] token in
        guard let self = self, let channel = self.liveActivityChannel else {
          print(
            "AppDelegate: Self or liveActivityChannel deallocated/not initialized when trying to send token."
          )
          return
        }
        print(
          "AppDelegate: New Live Activity Push Token received (on background thread): \(token ?? "nil")"
        )
        DispatchQueue.main.async {
          print("AppDelegate: Sending token to Flutter on main thread.")
          channel.invokeMethod("liveActivityTokenUpdated", arguments: token)
        }
      }
      return manager
    } else {
      return nil
    }
  }()

  @available(iOS 16.2, *)
  private var typedLiveActivityManager: LiveActivityManager? {
    return liveActivityManagerHolder as? LiveActivityManager
  }

  // MARK: - Application Lifecycle (Live Activities)
  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    if #available(iOS 16.2, *) {
      self.typedLiveActivityManager?.checkAndAdoptExistingActivities()
    }
  }

  // MARK: - Remote Notifications (Live Activities)
  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    print("AppDelegate: Received remote notification: \(userInfo)")

    if #available(iOS 16.2, *) {
      if let aps = userInfo["aps"] as? [String: AnyObject],
        let event = aps["event"] as? String,
        event == "update" || event == "end",
        aps["timestamp"] as? Int != nil
      {
        print("AppDelegate: System-handled Live Activity push received. Event: \(event).")
        completionHandler(.newData)
        return
      }

      guard let manager = self.typedLiveActivityManager else {
        print("AppDelegate: LiveActivityManager not available for app-driven LA update.")
        completionHandler(.noData)
        return
      }

      if let liveEvent = userInfo["event"] as? String {
        guard let destinationFromPush = userInfo["destination"] as? String,
          let arrivalTimeFromPush = userInfo["arrivalTime"] as? Int,
          let departureTimeFromPush = userInfo["departureTime"] as? Int,
          let currentServerTimeFromPush = userInfo["currentServerTime"] as? Int
        else {
          print("AppDelegate: Custom app-driven Live Activity push missing required data.")
          completionHandler(.failed)
          return
        }
        print("AppDelegate: Processing custom app-driven Live Activity event: \(liveEvent)")

        let defaultOriginDisplayName = "Torn"
        let defaultOriginFlagAsset = "torn_ball.png"
        let defaultVehicleAssetName = "plane_right.png"
        let defaultActivityStateTitle = "Traveling to"
        let destinationFlagAsset =
          "ball_\(destinationFromPush.lowercased().replacingOccurrences(of: " ", with: "-")).png"

        Task {
          do {
            switch liveEvent {
            case "start":
              try await manager.startTravelActivity(
                currentDestinationDisplayName: destinationFromPush,
                currentDestinationFlagAsset: destinationFlagAsset,
                originDisplayName: defaultOriginDisplayName,
                originFlagAsset: defaultOriginFlagAsset,
                arrivalTimeTimestamp: arrivalTimeFromPush,
                departureTimeTimestamp: departureTimeFromPush,
                currentServerTimestamp: currentServerTimeFromPush,
                vehicleAssetName: defaultVehicleAssetName,
                earliestReturnTimestamp: userInfo["earliestReturnTimestamp"] as? Int,
                activityStateTitle: defaultActivityStateTitle,
                showProgressBar: userInfo["showProgressBar"] as? Bool ?? true
              )
            case "update":
              try await manager.updateTravelActivity(
                currentDestinationDisplayName: destinationFromPush,
                currentDestinationFlagAsset: destinationFlagAsset,
                originDisplayName: userInfo["originDisplayName"] as? String
                  ?? defaultOriginDisplayName,
                originFlagAsset: userInfo["originFlagAsset"] as? String ?? defaultOriginFlagAsset,
                arrivalTimeTimestamp: arrivalTimeFromPush,
                departureTimeTimestamp: departureTimeFromPush,
                currentServerTimestamp: currentServerTimeFromPush,
                vehicleAssetName: userInfo["vehicleAssetName"] as? String
                  ?? defaultVehicleAssetName,
                earliestReturnTimestamp: userInfo["earliestReturnTimestamp"] as? Int,
                activityStateTitle: userInfo["activityStateTitle"] as? String
                  ?? defaultActivityStateTitle,
                showProgressBar: userInfo["showProgressBar"] as? Bool ?? true
              )
            case "end":
              await manager.endCurrentTravelActivity()
            default:
              print("AppDelegate: Unknown custom app-driven Live Activity event: \(liveEvent)")
            }
            completionHandler(.newData)
          } catch {
            print("AppDelegate: Error processing custom app-driven LiveActivity push: \(error)")
            completionHandler(.failed)
          }
        }
      } else {
        print("AppDelegate: Remote notification not a recognized Live Activity push format.")
        completionHandler(.noData)
      }
    } else {
      print("AppDelegate: Received remote notification, Live Activities not supported.")
      completionHandler(.noData)
    }
  }

  // MARK: - App Icon Changer
  private func setApplicationIconName(_ iconName: String?, result: @escaping FlutterResult) {
    guard UIApplication.shared.supportsAlternateIcons else {
      result(
        FlutterError(
          code: "UNSUPPORTED", message: "Alternate icons are not supported", details: nil))
      return
    }

    // Get the current icon name
    let currentIconName = UIApplication.shared.alternateIconName

    if currentIconName == iconName {
      result(nil)  // Icon is already set, no need to change it
      return
    }

    UIApplication.shared.setAlternateIconName(iconName) { (error) in
      if let error = error {
        result(
          FlutterError(
            code: "ICON_CHANGE_FAILED", message: error.localizedDescription, details: nil))
      } else {
        result(nil)
      }
    }
  }

  // MARK: - UNUserNotificationCenterDelegate (Enhanced, considered part of new structure if explicit)
  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    let userInfo = notification.request.content.userInfo
    print("AppDelegate: Foreground notification received: \(userInfo)")
    completionHandler([.alert, .sound, .badge])
  }

  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    let userInfo = response.notification.request.content.userInfo
    print("AppDelegate: User interacted with notification: \(userInfo)")
    completionHandler()
  }
}

// MARK: - FlutterViewController Press Event Handling (Existing Functionality)
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
