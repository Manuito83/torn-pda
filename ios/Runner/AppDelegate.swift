// AppDelegate.swift
import ActivityKit  // For Live Activities
import Darwin  // for host_statistics64
import Flutter
import MachO  // for task_info APIs
import UIKit
import UserNotifications  // for UNUserNotificationCenter
import home_widget
import workmanager_apple

#if canImport(AppIntents)
  import AppIntents
#endif

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  var iconChannel: FlutterMethodChannel!
  var memoryChannel: FlutterMethodChannel!
  var liveActivityChannel: FlutterMethodChannel!

  private let chatReplyRelay = ChatReplyRelay()

  // LA tokens must not cross the channel before the engine runs (see markEngineRunning)
  private var flutterEngineRunning = false

  lazy var liveActivityManager: Any? = {
    if #available(iOS 16.2, *) {
      let manager = LiveActivityManager()
      return manager
    } else {
      return nil
    }
  }()

  @available(iOS 16.2, *)
  private var activityManager: LiveActivityManager? {
    return liveActivityManager as? LiveActivityManager
  }

  lazy var racingLiveActivityManager: Any? = {
    if #available(iOS 16.2, *) {
      let manager = RacingLiveActivityManager()
      return manager
    } else {
      return nil
    }
  }()

  @available(iOS 16.2, *)
  private var racingActivityManager: RacingLiveActivityManager? {
    return racingLiveActivityManager as? RacingLiveActivityManager
  }

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Set up the delegate for local notifications
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    if #available(iOS 17, *) {
      HomeWidgetBackgroundWorker.setPluginRegistrantCallback { registry in
        GeneratedPluginRegistrant.register(with: registry)
      }
    }

    if #available(iOS 17.0, *) {
      HomeWidgetPlugin.setConfigurationLookup(to: [
        "RankedWarWidget": PdaWidgetMainIntent.self
      ])
    }

    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    WorkmanagerPlugin.registerPeriodicTask(
      withIdentifier: "com.manuito.tornpda.ranked_widget_refresh",
      frequency: NSNumber(value: 15 * 60)
    )

    WorkmanagerDebug.setCurrent(LoggingDebugHandler())

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Any inbound Dart call proves the engine is running: push tokens withheld until then.
  // Also covers push-to-start background launches, where the token arrives with no Dart
  // running and gets resynced on the next real app open
  private func markEngineRunning() {
    if flutterEngineRunning { return }
    flutterEngineRunning = true
    if #available(iOS 16.2, *), let channel = liveActivityChannel {
      if let token = activityManager?.activityPushToken {
        channel.invokeMethod(
          "liveActivityTokenUpdated",
          arguments: ["activityType": "travel", "token": token])
      }
      if let token = racingActivityManager?.activityPushToken {
        channel.invokeMethod(
          "liveActivityTokenUpdated",
          arguments: ["activityType": "racing", "token": token])
      }
    }
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let messenger = engineBridge.applicationRegistrar.messenger()

    chatReplyRelay.mainChannel = FlutterMethodChannel(
      name: ChatReplyRelay.channelName, binaryMessenger: messenger)

    // Set up the Flutter channel to handle AlarmKit
    let alarmChannel = FlutterMethodChannel(
      name: "tornpda/alarm", binaryMessenger: messenger)
    alarmChannel.setMethodCallHandler {
      (call: FlutterMethodCall, result: @escaping FlutterResult) in

      if #available(iOS 26.0, *) {
        AlarmKitHandler.handle(call: call, result: result)
      } else {
        result(FlutterError(code: "UNAVAILABLE", message: "AlarmKit not available", details: nil))
      }
    }
    // Expose the channel so AlarmKit callbacks can notify Flutter (e.g., alarm button taps)
    AlarmKitHandler.channel = alarmChannel

    // Set up the Flutter channel to check protected data availability (Keychain diagnostics)
    let protectedDataChannel = FlutterMethodChannel(
      name: "tornpda/protected_data", binaryMessenger: messenger)
    protectedDataChannel.setMethodCallHandler {
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
      self?.markEngineRunning()
      if call.method == "isProtectedDataAvailable" {
        result(UIApplication.shared.isProtectedDataAvailable)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    // Set up the Flutter channel to handle icon changes
    iconChannel = FlutterMethodChannel(
      name: "tornpda/icon", binaryMessenger: messenger)
    iconChannel.setMethodCallHandler { (call: FlutterMethodCall, result: @escaping FlutterResult) in
      self.markEngineRunning()
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
      name: "tornpda/memory", binaryMessenger: messenger)
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
      binaryMessenger: messenger
    )

    if #available(iOS 16.2, *) {
      self.activityManager?.onNewActivityPushToken = { [weak self] token in
        // ActivityKit delivers off the main thread and possibly before the engine runs;
        // channel calls need both, and a withheld token is resynced by markEngineRunning
        DispatchQueue.main.async {
          guard let self, self.flutterEngineRunning else { return }
          self.liveActivityChannel.invokeMethod(
            "liveActivityTokenUpdated",
            arguments: [
              "activityType": "travel",
              "token": token as Any,
            ])
        }
      }
      self.racingActivityManager?.onNewActivityPushToken = { [weak self] token in
        DispatchQueue.main.async {
          guard let self, self.flutterEngineRunning else { return }
          self.liveActivityChannel.invokeMethod(
            "liveActivityTokenUpdated",
            arguments: [
              "activityType": "racing",
              "token": token as Any,
            ])
        }
      }

      liveActivityChannel.setMethodCallHandler { [weak self] (call, result) in
        guard let self = self,
          let manager = self.activityManager,
          let racingManager = self.racingActivityManager
        else {
          result(
            FlutterError(
              code: "UNAVAILABLE",
              message: "LiveActivityManager not available or AppDelegate deallocated.",
              details: nil
            )
          )
          return
        }
        self.markEngineRunning()
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
            let showProgressBar = currentArgs["showProgressBar"] as? Bool,
            let hasArrived = currentArgs["hasArrived"] as? Bool
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
                showProgressBar: showProgressBar,
                hasArrived: hasArrived
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
            let showProgressBar = currentArgs["showProgressBar"] as? Bool,
            let hasArrived = currentArgs["hasArrived"] as? Bool
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
                showProgressBar: showProgressBar,
                hasArrived: hasArrived
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

        case "startRacingActivity":
          guard let currentArgs = args,
            let stateIdentifier = currentArgs["stateIdentifier"] as? String,
            let phase = currentArgs["phase"] as? String,
            let titleText = currentArgs["titleText"] as? String,
            let bodyText = currentArgs["bodyText"] as? String,
            let currentServerTimestamp = currentArgs["currentServerTimestamp"] as? Int,
            let showTimer = currentArgs["showTimer"] as? Bool
          else {
            result(
              FlutterError(
                code: "INVALID_ARGUMENTS",
                message: "Missing or invalid arguments for startRacingActivity.",
                details: nil
              )
            )
            return
          }
          let targetTimeTimestamp = currentArgs["targetTimeTimestamp"] as? Int
          let startTimeTimestamp = currentArgs["startTimeTimestamp"] as? Int
          Task {
            do {
              try await racingManager.startRacingActivity(
                stateIdentifier: stateIdentifier,
                phase: phase,
                titleText: titleText,
                bodyText: bodyText,
                targetTimeTimestamp: targetTimeTimestamp,
                startTimeTimestamp: startTimeTimestamp,
                currentServerTimestamp: currentServerTimestamp,
                showTimer: showTimer
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

        case "endRacingActivity":
          Task {
            await racingManager.endCurrentRacingActivity()
            result(nil)
          }

        case "isAnyRacingActivityActive":
          result(racingManager.isAnyRacingActivityActive())

        case "endTravelActivity":
          Task {
            await manager.endCurrentTravelActivity()
            result(nil)
          }

        case "isAnyTravelActivityActive":
          result(manager.isAnyTravelActivityActive())

        case "getPushToStartToken":
          guard let args = call.arguments as? [String: Any],
            let activityType = args["activityType"] as? String
          else {
            result(
              FlutterError(
                code: "INVALID_ARGUMENTS", message: "activityType is required", details: nil))
            return
          }

          if #available(iOS 17.2, *) {
            let token: String?
            switch activityType {
            case "travel":
              token = manager.getPushToStartToken(for: activityType)
            case "racing":
              token = Activity<RacingActivityAttributes>.pushToStartToken?.map {
                String(format: "%02x", $0)
              }.joined()
            default:
              token = nil
            }
            result(token)
          } else {
            result(nil)
          }

        default:
          result(FlutterMethodNotImplemented)
        }
      }
      self.activityManager?.checkAndAdoptExistingActivities()
      self.racingActivityManager?.checkAndAdoptExistingActivities()
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
    handleSceneDidBecomeActive()
  }

  // MARK: - Scene Lifecycle (Live Activities)
  func handleSceneDidBecomeActive() {
    if #available(iOS 16.2, *) {
      self.activityManager?.checkAndAdoptExistingActivities()
      self.racingActivityManager?.checkAndAdoptExistingActivities()
    }
  }

  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    didReceive response: UNNotificationResponse,
    withCompletionHandler completionHandler: @escaping () -> Void
  ) {
    guard let args = ChatReplyRelay.arguments(for: response) else {
      super.userNotificationCenter(
        center, didReceive: response, withCompletionHandler: completionHandler)
      return
    }
    chatReplyRelay.deliver(args, completion: completionHandler)
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

  // MARK: - AlarmKit Handlers
  // Handlers moved to AlarmKitHandler.swift
}

// MARK: - Chat notification reply
final class ChatReplyRelay {
  static let channelName = "tornpda/chat_reply"
  private static let category = "TORN_CHAT_DM"
  private static let action = "tchat_reply_action"

  var mainChannel: FlutterMethodChannel?
  private var engine: FlutterEngine?
  private var headlessChannel: FlutterMethodChannel?
  private var headlessReady = false
  private var pending: [(args: [String: Any], finish: () -> Void)] = []

  // Remote: userId, local: payload
  static func arguments(for response: UNNotificationResponse) -> [String: Any]? {
    let content = response.notification.request.content
    guard let input = response as? UNTextInputNotificationResponse,
      response.actionIdentifier == action, content.categoryIdentifier == category
    else { return nil }
    var args: [String: Any] = ["text": input.userText]
    for key in ["event", "kind", "userId", "sender", "payload"] {
      if let value = content.userInfo[key] { args[key] = "\(value)" }
    }
    return args
  }

  func deliver(_ args: [String: Any], completion: @escaping () -> Void) {
    var finished = false
    let finish = {
      if finished { return }
      finished = true
      completion()
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 25, execute: finish)
    guard let channel = mainChannel else {
      runHeadless(args, finish)
      return
    }
    channel.invokeMethod("reply", arguments: args) { [weak self] result in
      if (result as AnyObject?) === FlutterMethodNotImplemented {
        self?.runHeadless(args, finish)
      } else {
        finish()
      }
    }
  }

  // iOS woke the app without a scene
  private func runHeadless(_ args: [String: Any], _ finish: @escaping () -> Void) {
    pending.append((args, finish))
    if engine != nil {
      if headlessReady { flushHeadless() }
      return
    }
    let engine = FlutterEngine(
      name: "tornpda_chat_reply", project: nil, allowHeadlessExecution: true)
    // Handlers can only be set once running
    engine.run(
      withEntrypoint: "tornChatReplyMain", libraryURI: "package:torn_pda/utils/notification.dart")
    let channel = FlutterMethodChannel(
      name: Self.channelName, binaryMessenger: engine.binaryMessenger)
    channel.setMethodCallHandler { [weak self] call, result in
      if call.method == "ready", let self {
        self.headlessReady = true
        self.flushHeadless()
      }
      result(nil)
    }
    GeneratedPluginRegistrant.register(with: engine)
    self.engine = engine
    headlessChannel = channel
  }

  private func flushHeadless() {
    let batch = pending
    pending.removeAll()
    for item in batch {
      headlessChannel?.invokeMethod("reply", arguments: item.args) { _ in item.finish() }
    }
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
