import AppIntents
import Foundation
import WidgetKit

enum PdaLockBar: String, AppEnum {
  case energy, nerve, happy, life

  static let typeDisplayRepresentation: TypeDisplayRepresentation = "Bar"
  static let caseDisplayRepresentations: [PdaLockBar: DisplayRepresentation] = [
    .energy: "Energy", .nerve: "Nerve", .happy: "Happy", .life: "Life",
  ]
}

struct PdaBarsIntent: WidgetConfigurationIntent {
  static let title: LocalizedStringResource = "Torn PDA"
  static let description = IntentDescription("Bars, status, cooldowns and shortcuts.")

  @Parameter(title: "Shortcuts in medium size", default: true)
  var showShortcuts: Bool

  @Parameter(title: "Show money", default: true)
  var showMoney: Bool

  @Parameter(title: "Lock screen bar", default: .energy)
  var lockBar: PdaLockBar
}

struct PdaRefreshIntent: AppIntent {
  static let title: LocalizedStringResource = "Refresh Torn PDA widget"
  static let isDiscoverable = false

  func perform() async throws -> some IntentResult {
    UserDefaults(suiteName: pdaAppGroup)?.set(true, forKey: "widget_force_fetch")
    return .result()
  }
}

struct PdaEntry: TimelineEntry {
  var date: Date
  var snapshot: PdaSnapshot?
  var error: String?
  var shortcuts: [PdaShortcut]
  var use24h: Bool
  var tornTime: Bool
  var configuration: PdaBarsIntent
}

struct PdaBarsProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> PdaEntry {
    PdaEntry(
      date: Date(), snapshot: .preview, error: nil, shortcuts: PdaShortcut.previews,
      use24h: true, tornTime: false, configuration: PdaBarsIntent())
  }

  func snapshot(for configuration: PdaBarsIntent, in context: Context) async -> PdaEntry {
    if context.isPreview { return placeholder(in: context) }
    return entry(at: Date(), snapshot: PdaWidgetStore.cachedSnapshot(), error: nil, configuration: configuration)
  }

  func timeline(for configuration: PdaBarsIntent, in context: Context) async -> Timeline<PdaEntry> {
    let now = Date()
    var snapshot = PdaWidgetStore.cachedSnapshot()
    var failure: String?

    if PdaWidgetStore.shouldFetch(cached: snapshot, now: now) {
      do {
        snapshot = try await PdaWidgetStore.fetch()
      } catch PdaApiError.noKey {
        snapshot = nil
        PdaWidgetStore.clearSnapshot()
        failure = PdaWidgetStore.missingKeyMessage
      } catch PdaApiError.torn(let code, let reason) {
        if [2, 13, 16, 18].contains(code) {
          snapshot = nil
          PdaWidgetStore.clearSnapshot()
        }
        failure = "API error: \(reason)"
      } catch {
        failure = "Could not reach Torn"
      }
    }

    let horizon = now + 4 * 3600
    let dates = [now] + (snapshot?.changeDates(until: horizon) ?? []).filter { $0 > now + 60 }
    let first = entry(at: now, snapshot: snapshot, error: failure, configuration: configuration)
    let entries = dates.map { date in
      var next = first
      next.date = date
      return next
    }
    return Timeline(entries: entries, policy: .after(now + 15 * 60))
  }

  private func entry(at date: Date, snapshot: PdaSnapshot?, error: String?, configuration: PdaBarsIntent)
    -> PdaEntry
  {
    let prefs = UserDefaults(suiteName: pdaAppGroup)
    return PdaEntry(
      date: date,
      snapshot: snapshot,
      error: error,
      shortcuts: PdaWidgetStore.shortcuts(),
      use24h: prefs?.string(forKey: "widget_time_format") != "12",
      tornTime: prefs?.string(forKey: "widget_time_zone") == "torn",
      configuration: configuration
    )
  }
}

enum PdaWidgetStore {
  private static var prefs: UserDefaults? { UserDefaults(suiteName: pdaAppGroup) }

  static func cachedSnapshot() -> PdaSnapshot? {
    guard let data = prefs?.data(forKey: "widget_snapshot") else { return nil }
    return try? JSONDecoder().decode(PdaSnapshot.self, from: data)
  }

  // Nil: app has shared nothing yet
  static var missingKeyMessage: String {
    prefs?.string(forKey: "widget_api_key") == nil
      ? "Open Torn PDA once and come back. Still here? Tap Reload."
      : "Add your API key in Torn PDA"
  }

  static func clearSnapshot() {
    prefs?.removeObject(forKey: "widget_snapshot")
  }

  static func shouldFetch(cached: PdaSnapshot?, now: Date) -> Bool {
    if prefs?.bool(forKey: "widget_force_fetch") == true {
      prefs?.set(false, forKey: "widget_force_fetch")
      return true
    }
    guard let cached else { return true }
    return now.timeIntervalSince(cached.fetchedAt) > 60
  }

  static func fetch() async throws -> PdaSnapshot {
    guard let key = prefs?.string(forKey: "widget_api_key"), !key.isEmpty else { throw PdaApiError.noKey }

    var components = URLComponents(string: "https://api.torn.com/user/")!
    components.queryItems = [
      URLQueryItem(name: "selections", value: "profile,icons,bars,cooldowns,newevents,newmessages,travel,money,education"),
      URLQueryItem(name: "comment", value: "PDA-Widget"),
      URLQueryItem(name: "key", value: key),
    ]
    var request = URLRequest(url: components.url!)
    request.timeoutInterval = 15

    let data: Data
    do {
      (data, _) = try await URLSession.shared.data(for: request)
    } catch {
      throw PdaApiError.network
    }
    guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
      throw PdaApiError.network
    }

    let snapshot = try parseSnapshot(from: json, fetchedAt: Date())
    if let encoded = try? JSONEncoder().encode(snapshot) {
      prefs?.set(encoded, forKey: "widget_snapshot")
    }
    return snapshot
  }

  static func shortcuts() -> [PdaShortcut] {
    guard let prefs else { return [] }
    let count = prefs.integer(forKey: "shortcuts_number")
    return (0..<min(count, 9)).compactMap { index in
      let name = prefs.string(forKey: "shortcut\(index + 1)_name") ?? ""
      let url = prefs.string(forKey: "shortcut\(index + 1)_url") ?? ""
      guard !name.isEmpty, !url.isEmpty else { return nil }
      return PdaShortcut(
        id: index, name: name, url: url,
        iconBase64: prefs.string(forKey: "shortcut\(index + 1)_icon") ?? "",
        iconTint: prefs.string(forKey: "shortcut\(index + 1)_icon_tint") ?? "")
    }
  }
}

extension PdaSnapshot {
  static var preview: PdaSnapshot {
    let now = Date()
    func bar(_ current: Int, _ maximum: Int, _ increment: Int, _ interval: Int) -> PdaBar {
      PdaBar(
        current: current, maximum: maximum, increment: increment, interval: interval,
        firstTick: now + 120, fullAt: now + TimeInterval((maximum - current) / increment * interval))
    }
    return PdaSnapshot(
      fetchedAt: now,
      energy: bar(55, 150, 5, 600),
      nerve: bar(31, 100, 1, 300),
      happy: bar(4245, 5025, 5, 900),
      life: bar(4023, 4023, 201, 300),
      chainCurrent: 0, chainTimeoutAt: nil, chainOnCooldown: false,
      statusState: "Okay", statusDescription: "Okay", statusUntil: nil,
      travelDestination: "Torn", travelArrival: nil,
      drugEnd: now + 4 * 3600 + 45 * 60, boosterEnd: now + 44 * 3600, medicalEnd: nil,
      drugLevel: 3, boosterLevel: 4, medicalLevel: 0,
      unreadMessages: 2, newEvents: 5, money: 13_423_708, racing: .none,
      educationEnd: now + 4 * 86400 + 21 * 3600, bankEnd: now + 67 * 86400, bankAmount: 2_409_000_000
    )
  }
}

extension PdaShortcut {
  static var previews: [PdaShortcut] {
    ["Gym", "Crimes", "Faction", "Items", "Travel", "Bazaar"].enumerated().map {
      PdaShortcut(id: $0.offset, name: $0.element, url: "https://www.torn.com", iconBase64: "", iconTint: "")
    }
  }
}
