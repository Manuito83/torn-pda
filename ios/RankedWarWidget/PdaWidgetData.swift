import Foundation

struct PdaBar: Codable {
  var current: Int
  var maximum: Int
  var increment: Int
  var interval: Int
  var firstTick: Date
  var fullAt: Date?

  func value(at date: Date) -> Int {
    guard current < maximum, increment > 0, interval > 0, date >= firstTick else { return current }
    let ticks = 1 + Int(date.timeIntervalSince(firstTick)) / interval
    return min(maximum, current + ticks * increment)
  }

  func fullCaption(at date: Date) -> String {
    guard value(at: date) < maximum, let duration = compactDuration(from: date, to: fullAt) else { return "Full" }
    return "Full in \(duration)"
  }

  func fraction(at date: Date) -> Double {
    maximum > 0 ? min(1, Double(value(at: date)) / Double(maximum)) : 0
  }

  func tickDates(until horizon: Date) -> [Date] {
    guard current < maximum, interval > 0 else { return [] }
    let end = min(horizon, fullAt ?? horizon)
    var dates: [Date] = []
    var tick = firstTick
    while tick <= end {
      dates.append(tick)
      tick += TimeInterval(interval)
    }
    return dates
  }
}

struct PdaShortcut: Codable, Identifiable {
  var id: Int
  var name: String
  var url: String
  var iconBase64: String
  var iconTint: String
}

struct PdaSnapshot: Codable {
  var fetchedAt: Date
  var energy: PdaBar
  var nerve: PdaBar
  var happy: PdaBar
  var life: PdaBar
  var chainCurrent: Int
  var chainTimeoutAt: Date?
  var chainOnCooldown: Bool
  var statusState: String
  var statusDescription: String
  var statusUntil: Date?
  var travelDestination: String
  var travelArrival: Date?
  var drugEnd: Date?
  var boosterEnd: Date?
  var medicalEnd: Date?
  var drugLevel: Int
  var boosterLevel: Int
  var medicalLevel: Int
  var unreadMessages: Int
  var newEvents: Int
  var money: Int
  var racing: PdaRacing
  var educationEnd: Date?
  var bankEnd: Date?
  var bankAmount: Int
}

enum PdaRacing: String, Codable {
  case none, inProgress, completed
}

enum PdaApiError: Error {
  case noKey
  case torn(code: Int, reason: String)
  case network
}

func parseSnapshot(from json: [String: Any], fetchedAt: Date) throws -> PdaSnapshot {
  if let error = json["error"] as? [String: Any] {
    throw PdaApiError.torn(code: (error["code"] as? NSNumber)?.intValue ?? 0, reason: error["error"] as? String ?? "")
  }

  func int(_ dict: [String: Any]?, _ key: String) -> Int {
    (dict?[key] as? NSNumber)?.intValue ?? 0
  }

  func after(_ seconds: Int) -> Date? {
    seconds > 0 ? fetchedAt + TimeInterval(seconds) : nil
  }

  func epoch(_ seconds: Int) -> Date? {
    seconds > 0 ? Date(timeIntervalSince1970: TimeInterval(seconds)) : nil
  }

  func bar(_ key: String) -> PdaBar {
    let raw = json[key] as? [String: Any]
    return PdaBar(
      current: int(raw, "current"),
      maximum: int(raw, "maximum"),
      increment: int(raw, "increment"),
      interval: int(raw, "interval"),
      firstTick: fetchedAt + TimeInterval(int(raw, "ticktime")),
      fullAt: after(int(raw, "fulltime"))
    )
  }

  let status = json["status"] as? [String: Any]
  let travel = json["travel"] as? [String: Any]
  let chain = json["chain"] as? [String: Any]
  let cooldowns = json["cooldowns"] as? [String: Any]
  let icons = json["icons"] as? [String: Any] ?? [:]
  let bank = json["city_bank"] as? [String: Any]

  // Torn shows the cooldown level as icons
  func level(firstIcon: Int) -> Int {
    (0..<5).first { icons["icon\(firstIcon + $0)"] != nil }.map { $0 + 1 } ?? 0
  }
  let messages = json["messages"] as? [String: Any] ?? [:]
  let events = json["events"] as? [String: Any] ?? [:]

  let unread = messages.values.filter { (($0 as? [String: Any])?["seen"] as? NSNumber)?.intValue == 0 }

  return PdaSnapshot(
    fetchedAt: fetchedAt,
    energy: bar("energy"),
    nerve: bar("nerve"),
    happy: bar("happy"),
    life: bar("life"),
    chainCurrent: int(chain, "current"),
    chainTimeoutAt: after(int(chain, "timeout")),
    chainOnCooldown: int(chain, "cooldown") > 0,
    statusState: status?["state"] as? String ?? "Okay",
    statusDescription: status?["description"] as? String ?? "",
    statusUntil: epoch(int(status, "until")),
    travelDestination: travel?["destination"] as? String ?? "Torn",
    travelArrival: int(travel, "time_left") > 0 ? epoch(int(travel, "timestamp")) : nil,
    drugEnd: after(int(cooldowns, "drug")),
    boosterEnd: after(int(cooldowns, "booster")),
    medicalEnd: after(int(cooldowns, "medical")),
    drugLevel: level(firstIcon: 49),
    boosterLevel: level(firstIcon: 39),
    medicalLevel: level(firstIcon: 44),
    unreadMessages: unread.count,
    newEvents: events.count,
    money: (json["money_onhand"] as? NSNumber)?.intValue ?? 0,
    racing: icons["icon17"] != nil ? .inProgress : icons["icon18"] != nil ? .completed : .none,
    educationEnd: after(int(json, "education_timeleft")),
    bankEnd: after(int(bank, "time_left")),
    bankAmount: int(bank, "amount")
  )
}

enum PdaStatusKind {
  case okay, hospital, jail, traveling, abroad, other
}

struct PdaStatus {
  var kind: PdaStatusKind
  var title: String
  var until: Date?
  var icons: [String] = []
}

extension PdaSnapshot {
  func status(at date: Date) -> PdaStatus {
    let abroad = travelDestination != "Torn" && !travelDestination.isEmpty
    let flying = travelArrival.map { $0 > date } ?? false
    let lockedUntil = statusUntil.flatMap { $0 > date ? $0 : nil }
    let place = shortCountry(travelDestination)
    let flag = "ball_\(countryAsset(travelDestination))"

    if statusState == "Jail", let until = lockedUntil {
      return PdaStatus(kind: .jail, title: "Jail for", until: until, icons: ["jail"])
    }
    if statusState == "Hospital", flying, !abroad {
      return PdaStatus(kind: .hospital, title: "Repatriated in", until: travelArrival, icons: ["plane_left"])
    }
    if statusState == "Hospital", let until = lockedUntil {
      if abroad {
        return PdaStatus(kind: .hospital, title: "Hospital in \(place):", until: until, icons: [flag, "hospital"])
      }
      return PdaStatus(kind: .hospital, title: "Hospital for", until: until, icons: ["hospital"])
    }
    if flying {
      return abroad
        ? PdaStatus(kind: .traveling, title: "\(place) in", until: travelArrival, icons: ["plane_right", flag])
        : PdaStatus(kind: .traveling, title: "Torn in", until: travelArrival, icons: ["plane_left"])
    }
    if abroad {
      return PdaStatus(kind: .abroad, title: "Visiting \(place)", until: nil, icons: [flag])
    }
    switch statusState {
    case "Okay", "Hospital", "Jail", "Traveling", "Abroad":
      return PdaStatus(kind: .okay, title: "Okay", until: nil)
    default:
      return PdaStatus(kind: .other, title: statusDescription.isEmpty ? statusState : statusDescription, until: nil)
    }
  }

  var chainTier: Int {
    let tiers = [10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000, 25000, 50000, 100_000]
    return tiers.first { chainCurrent < $0 } ?? 100_000
  }

  func changeDates(until horizon: Date) -> [Date] {
    var dates = [energy, nerve, happy, life].flatMap { $0.tickDates(until: horizon) }
    dates += [statusUntil, travelArrival, drugEnd, boosterEnd, medicalEnd, chainTimeoutAt, educationEnd, bankEnd]
      .compactMap { $0 }
      .filter { $0 <= horizon }
    return Set(dates).filter { $0 > fetchedAt }.sorted()
  }
}

private func countryAsset(_ name: String) -> String {
  switch name {
  case "United Kingdom": return "uk"
  case "Cayman Islands": return "cayman"
  case "United Arab Emirates", "UAE": return "uae"
  default: return name.lowercased().replacingOccurrences(of: " ", with: "-")
  }
}

private func shortCountry(_ name: String) -> String {
  switch name {
  case "Cayman Islands": return "Cayman"
  case "South Africa": return "S. Africa"
  case "United Kingdom": return "UK"
  default: return name
  }
}

func compactDuration(from start: Date, to end: Date?) -> String? {
  guard let end, end > start else { return nil }
  let minutes = Int(end.timeIntervalSince(start)) / 60
  let days = minutes / 1440
  let hours = (minutes % 1440) / 60
  if days > 0 { return "\(days)d \(hours)h" }
  if hours > 0 { return "\(hours)h \(String(format: "%02d", minutes % 60))m" }
  return "\(max(1, minutes % 60))m"
}

func compactMoney(_ value: Int) -> String {
  let amount = Double(value)
  switch value {
  case 999_950_000_000...: return String(format: "$%.1fT", amount / 1e12)
  case 999_950_000...: return String(format: "$%.1fB", amount / 1e9)
  case 999_500...: return String(format: "$%.1fM", amount / 1e6)
  case 9_950...: return String(format: "$%.0fK", amount / 1e3)
  case 1_000...: return String(format: "$%.1fK", amount / 1e3)
  default: return "$\(value)"
  }
}
