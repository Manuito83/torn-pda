import AppIntents
import CryptoKit
import Flutter
import Foundation
import SwiftUI

#if canImport(AlarmKit)
  import AlarmKit
#endif

enum AlarmKitHandler {
  static var channel: FlutterMethodChannel?
  @available(iOS 26.0, *)
  static func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    #if canImport(AlarmKit)
      switch call.method {
      case "setAlarm":
        handleSetAlarm(call: call, result: result)
      case "cancelAlarm":
        handleCancelAlarm(call: call, result: result)
      case "listAlarms":
        handleListAlarms(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    #else
      result(FlutterError(code: "UNAVAILABLE", message: "AlarmKit not present", details: nil))
    #endif
  }
}

#if canImport(AlarmKit)

  enum AlarmPayloadStore {
    // Persists the payload per alarm UUID so OpenAppIntent can deliver it back to Flutter when the alarm is opened.
    // Lives in UserDefaults to survive process restarts between scheduling and user tapping the alarm.
    private static let storeKey = "tornpda.alarmPayloads"

    private static var userDefaults: UserDefaults {
      UserDefaults.standard
    }

    static func save(id: String, payload: String) {
      var current = userDefaults.dictionary(forKey: storeKey) as? [String: String] ?? [:]
      current[id] = payload
      userDefaults.set(current, forKey: storeKey)
    }

    static func remove(id: String) {
      var current = userDefaults.dictionary(forKey: storeKey) as? [String: String] ?? [:]
      current.removeValue(forKey: id)
      userDefaults.set(current, forKey: storeKey)
    }

    static func payload(for id: String) -> String? {
      let current = userDefaults.dictionary(forKey: storeKey) as? [String: String]
      return current?[id]
    }

    static func compact(aliveIds: Set<String>) {
      var current = userDefaults.dictionary(forKey: storeKey) as? [String: String] ?? [:]
      let stale = current.keys.filter { !aliveIds.contains($0) }
      if stale.isEmpty { return }
      stale.forEach { current.removeValue(forKey: $0) }
      userDefaults.set(current, forKey: storeKey)
    }
  }

  @available(iOS 26.0, *)
  extension AlarmKitHandler {

    fileprivate static func handleSetAlarm(call: FlutterMethodCall, result: @escaping FlutterResult)
    {
      // Maps Flutter call into an AlarmKit schedule: normalizes id, requests permission, schedules,
      // and saves payload for later delivery when the alarm is opened.
      var debugMessages: [String] = []
      func recordDebug(_ message: String) {
        debugMessages.append(message)
      }

      guard let args = call.arguments as? [String: Any] else {
        result(FlutterError(code: "INVALID_ARGUMENTS", message: "Arguments missing", details: nil))
        return
      }

      let label = args["label"] as? String ?? "Alarm"
      let metadataPayload = args["metadata"] as? [String: Any]
      let metaContext = metadataPayload?["context"] as? String
      let metaDetails = metadataPayload?["details"] as? String
      let metaPayload = metadataPayload?["payload"] as? String

      let idString = args["id"] as? String
      guard let uuid = uuidFrom(idString) else {
        result(
          FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid id encoding", details: nil))
        return
      }

      let uuidString = uuid.uuidString

      guard let milliseconds = args["milliseconds"] as? Int else {
        result(
          FlutterError(
            code: "INVALID_ARGUMENTS", message: "milliseconds is required", details: nil))
        return
      }

      let date = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)

      let formatter = DateFormatter()
      formatter.timeStyle = .long
      formatter.dateStyle = .long
      recordDebug("AlarmKit: Scheduling for Date (Local): \(formatter.string(from: date))")

      Task { @MainActor in
        do {
          let alarmManager = try await ensureAuthorization()
          let attributes = makeAttributes(
            label: label,
            uuidString: uuidString,
            context: metaContext,
            details: metaDetails,
            payload: metaPayload
          )

          let schedule = Alarm.Schedule.fixed(date)

          let now = Date()
          if date <= now {
            recordDebug(
              "AlarmKit WARNING: Scheduled time is in the past or the same instant (\(date))."
            )
          }

          let countdownDuration = Alarm.CountdownDuration(
            preAlert: nil,
            postAlert: TimeInterval(60)
          )

          let configuration = AlarmManager.AlarmConfiguration(
            countdownDuration: countdownDuration,
            schedule: schedule,
            attributes: attributes,
            stopIntent: nil,
            secondaryIntent: OpenAppIntent(alarmID: uuidString),
            sound: .default
          )

          _ = try await alarmManager.schedule(id: uuid, configuration: configuration)
          if let metaPayload {
            AlarmPayloadStore.save(id: uuidString, payload: metaPayload)
          }
          recordDebug("AlarmKit: Scheduled alarm with UUID \(uuidString)")
          result([
            "uuid": uuidString,
            "debug": debugMessages.joined(separator: "\n"),
          ])
        } catch {
          let debugDetail = debugMessages.joined(separator: "\n")
          result(
            FlutterError(
              code: "SCHEDULING_FAILED", message: error.localizedDescription,
              details: ["debug": debugDetail]))
        }
      }
    }

    fileprivate static func handleCancelAlarm(
      call: FlutterMethodCall, result: @escaping FlutterResult
    ) {
      // Cancels the alarm in AlarmKit and drops any stored payload for that UUID. ID is normalized the same way as set
      guard let args = call.arguments as? [String: Any], let idString = args["id"] as? String else {
        result(
          FlutterError(code: "INVALID_ARGUMENTS", message: "Missing or invalid id", details: nil))
        return
      }

      // Accept either a UUID string or a deterministic string id (same mapping as handleSetAlarm)
      guard let uuid = uuidFrom(idString) else {
        result(
          FlutterError(code: "INVALID_ARGUMENTS", message: "Invalid id encoding", details: nil))
        return
      }

      Task { @MainActor in
        do {
          let alarmManager = AlarmManager.shared
          try alarmManager.cancel(id: uuid)
          AlarmPayloadStore.remove(id: uuid.uuidString)
          result(nil)
        } catch {
          result(
            FlutterError(code: "CANCEL_FAILED", message: error.localizedDescription, details: nil))
        }
      }
    }

    fileprivate static func handleListAlarms(
      call: FlutterMethodCall, result: @escaping FlutterResult
    ) {
      // Returns AlarmKit alarms and prunes payload metadata for alarms that no longer exist (keeps store tidy)
      Task { @MainActor in
        do {
          let alarmManager = AlarmManager.shared
          var alarmsList: [[String: Any]] = []
          var aliveIds: Set<String> = []

          let alarms = try alarmManager.alarms
          for alarm in alarms {
            var alarmInfo: [String: Any] = [
              "id": alarm.id.uuidString
            ]
            aliveIds.insert(alarm.id.uuidString)

            alarmInfo["label"] = "Alarm"

            if case .relative(let relativeSchedule) = alarm.schedule {
              alarmInfo["hour"] = relativeSchedule.time.hour
              alarmInfo["minute"] = relativeSchedule.time.minute
              alarmInfo["debug"] =
                "Relative: \(relativeSchedule.time.hour):\(relativeSchedule.time.minute)"
            } else if case .fixed(let date) = alarm.schedule {
              let components = Calendar.current.dateComponents([.hour, .minute], from: date)
              alarmInfo["hour"] = components.hour
              alarmInfo["minute"] = components.minute
              let milliseconds = Int(date.timeIntervalSince1970 * 1000)
              alarmInfo["scheduledMillis"] = milliseconds

              let formatter = DateFormatter()
              formatter.timeStyle = .long
              formatter.dateStyle = .long
              formatter.timeZone = TimeZone.current
              let localDate = formatter.string(from: date)

              formatter.timeZone = TimeZone(identifier: "UTC")
              let utcDate = formatter.string(from: date)

              let debugString = "Fixed Date - Local: \(localDate) | UTC: \(utcDate)"
              alarmInfo["debug"] = debugString
            }

            alarmsList.append(alarmInfo)
          }

          AlarmPayloadStore.compact(aliveIds: aliveIds)

          result(alarmsList)
        } catch {
          result(
            FlutterError(
              code: "LIST_FAILED", message: error.localizedDescription, details: nil))
        }
      }
    }

    fileprivate static func makeAttributes(
      label: String,
      uuidString: String,
      context: String?,
      details: String?,
      payload: String?
    ) -> AlarmAttributes<TornAlarmMetadata> {
      let stopButton = AlarmButton(
        text: LocalizedStringResource(stringLiteral: "Stop"),
        textColor: .white,
        systemImageName: "bell.slash.circle.fill"
      )

      let openAppButton = AlarmButton(
        text: LocalizedStringResource(stringLiteral: "Open App"),
        textColor: .white,
        systemImageName: "arrow.right.circle.fill"
      )

      let alert = AlarmPresentation.Alert(
        title: LocalizedStringResource(stringLiteral: label),
        stopButton: stopButton,
        secondaryButton: openAppButton,
        secondaryButtonBehavior: .custom
      )

      let presentation = AlarmPresentation(alert: alert)

      return AlarmAttributes(
        presentation: presentation,
        metadata: TornAlarmMetadata(
          id: uuidString, label: label, context: context, details: details, payload: payload),
        tintColor: .primary
      )
    }

    @MainActor
    fileprivate static func ensureAuthorization() async throws -> AlarmManager {
      // Ensures the user has granted AlarmKit permission before scheduling/canceling
      let alarmManager = AlarmManager.shared

      switch alarmManager.authorizationState {
      case .authorized:
        return alarmManager
      case .notDetermined:
        let status = try await alarmManager.requestAuthorization()
        if status == .authorized {
          return alarmManager
        }
        throw NSError(
          domain: "AlarmKit", code: 1,
          userInfo: [NSLocalizedDescriptionKey: "Alarm permission not granted"])
      case .denied:
        throw NSError(
          domain: "AlarmKit", code: 2,
          userInfo: [NSLocalizedDescriptionKey: "Alarm permission denied"])
      @unknown default:
        throw NSError(
          domain: "AlarmKit", code: 3,
          userInfo: [NSLocalizedDescriptionKey: "Unknown alarm permission state"])
      }
    }

    fileprivate static func uuidFrom(_ idString: String?) -> UUID? {
      guard let idString else { return UUID() }
      // If caller already sent a UUID, reuse it; otherwise, derive a deterministic UUID from the logical id
      // so set/cancel/list share the same mapping.
      if let parsed = UUID(uuidString: idString) {
        return parsed
      }
      guard let data = idString.data(using: .utf8) else { return nil }

      let digest = SHA256.hash(data: data)
      var bytes = [UInt8](digest.prefix(16))

      // Set version (name-based, using SHA) and variant per RFC 4122.
      bytes[6] = (bytes[6] & 0x0F) | 0x50  // version 5-style marker
      bytes[8] = (bytes[8] & 0x3F) | 0x80  // variant RFC 4122

      let uuid = uuid_t(
        bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
        bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]
      )
      return UUID(uuid: uuid)
    }
  }

  @available(iOS 26.0, *)
  struct TornAlarmMetadata: AlarmMetadata, Codable {
    var id: String
    var label: String
    var context: String?
    var details: String?
    var payload: String?
  }

  @available(iOS 26.0, *)
  struct OpenAppIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Open App"
    static var description = IntentDescription("Open the app for alarm context")
    static var openAppWhenRun: Bool = true

    @Parameter(title: "alarmID")
    var alarmID: String

    init(alarmID: String) {
      self.alarmID = alarmID
    }

    init() {
      self.alarmID = ""
    }

    func perform() async throws -> some IntentResult {
      if let payload = AlarmPayloadStore.payload(for: alarmID) {
        await AlarmKitHandler.dispatchAlarmPayload(payload)
        AlarmPayloadStore.remove(id: alarmID)
      } else {
        await MainActor.run {
          AlarmKitHandler.channel?.invokeMethod(
            "handleAlarmDebug",
            arguments: ["message": "OpenAppIntent: no payload stored for id \(alarmID)"])
        }
      }
      return .result()
    }
  }

  @available(iOS 26.0, *)
  extension AlarmKitHandler {
    @MainActor
    fileprivate static func dispatchAlarmPayload(_ payload: String) async {
      if let channel {
        channel.invokeMethod(
          "handleAlarmTap",
          arguments: [
            "payload": payload,
            "debug": "AlarmKit dispatchAlarmPayload -> \(payload)",
          ])
      } else {
      }
    }
  }
#endif
