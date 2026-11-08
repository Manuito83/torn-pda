import AppIntents
import SwiftUI
import WidgetKit

enum PdaColors {
  static let energy = Color(red: 0.271, green: 0.757, blue: 0.271)
  static let nerve = Color(red: 0.776, green: 0.012, blue: 0.012)
  static let happy = Color(red: 0.902, green: 0.678, blue: 0.008)
  static let life = Color(red: 0.012, green: 0.663, blue: 0.957)
  static let chain = Color(red: 0.404, green: 0.227, blue: 0.718)
  static let green = Color(red: 0.004, green: 0.765, blue: 0.004)
}

func pdaLink(_ action: String) -> URL {
  var components = URLComponents()
  components.scheme = "pdaWidget"
  components.host = "widget"
  components.queryItems = [URLQueryItem(name: "action", value: "pdaWidget://\(action)")]
  components.percentEncodedQuery = components.percentEncodedQuery?.replacingOccurrences(of: "+", with: "%2B")
  return components.url!
}

struct PdaIcon: View {
  var name: String
  var size: CGFloat
  var template = false

  var body: some View {
    Image(name)
      .renderingMode(template ? .template : .original)
      .resizable()
      .scaledToFit()
      .frame(width: size, height: size)
  }
}

struct PdaTimersRow: View {
  var snapshot: PdaSnapshot
  var date: Date

  var body: some View {
    HStack(spacing: 14) {
      if snapshot.educationEnd != nil {
        timer(symbol: "graduationcap.fill", name: "Education", end: snapshot.educationEnd, action: "education:clicked")
      }
      if snapshot.bankAmount > 0 {
        timer(symbol: "building.columns.fill", name: "Bank", end: snapshot.bankEnd, action: "bank:clicked")
      }
      Spacer(minLength: 0)
    }
  }

  private func timer(symbol: String, name: String, end: Date?, action: String) -> some View {
    Link(destination: pdaLink(action)) {
      HStack(spacing: 4) {
        Image(systemName: symbol).font(.system(size: 11)).foregroundStyle(.secondary)
        Text(name).font(.system(size: 11))
        Text(compactDuration(from: date, to: end) ?? "Done")
          .font(.system(size: 11, weight: .medium).monospacedDigit())
          .foregroundStyle(end.map { $0 > date } == true ? Color.primary : PdaColors.green)
          .lineLimit(1)
          .fixedSize()
      }
    }
  }
}

struct PdaTimerText: View {
  var until: Date
  var date: Date
  var size: CGFloat
  var weight: Font.Weight = .regular
  var color: Color

  // Timer text reserves a huge width otherwise
  var body: some View {
    let seconds = max(0, Int(until.timeIntervalSince(date)))
    let digits = seconds >= 36000 ? 6 : seconds >= 3600 ? 5 : seconds >= 600 ? 4 : 3
    let colons = seconds >= 3600 ? 2 : 1
    Text(until, style: .timer)
      .font(.system(size: size, weight: weight).monospacedDigit())
      .foregroundStyle(color)
      .lineLimit(1)
      .frame(width: CGFloat(digits) * size * 0.7 + CGFloat(colons) * size * 0.4 + 4, alignment: .leading)
  }
}

struct PdaStatusLine: View {
  var snapshot: PdaSnapshot
  var date: Date
  var size: CGFloat = 13

  var body: some View {
    let status = snapshot.status(at: date)
    let color = statusColor(status.kind)

    Link(destination: pdaLink(statusAction(status.kind))) {
      HStack(spacing: 4) {
        ForEach(status.icons, id: \.self) { PdaIcon(name: $0, size: 14) }
        Text(status.title)
          .font(.system(size: size, weight: .bold))
          .foregroundStyle(color)
          .lineLimit(1)
        if let until = status.until {
          PdaTimerText(until: until, date: date, size: size, weight: .bold, color: color)
        }
      }
    }
  }

  private func statusAction(_ kind: PdaStatusKind) -> String {
    switch kind {
    case .hospital: return "hospital:status:icon:clicked"
    case .jail: return "jail:status:icon:clicked"
    default: return "blue:status:clicked"
    }
  }
}

func statusColor(_ kind: PdaStatusKind) -> Color {
  switch kind {
  case .okay: return .primary
  case .hospital, .jail: return PdaColors.nerve
  case .traveling, .abroad: return PdaColors.life
  case .other: return .orange
  }
}

struct PdaInboxBadges: View {
  var snapshot: PdaSnapshot

  var body: some View {
    HStack(spacing: 8) {
      badge(icon: "new_messages", count: snapshot.unreadMessages, action: "messages:clicked")
      badge(icon: "new_events", count: snapshot.newEvents, action: "events:clicked")
    }
    .fixedSize()
    .layoutPriority(1)
  }

  private func badge(icon: String, count: Int, action: String) -> some View {
    Link(destination: pdaLink(action)) {
      HStack(spacing: 2) {
        if count > 0 {
          Text(verbatim: "\(count)")
            .font(.system(size: 11, weight: .bold).monospacedDigit())
            .foregroundStyle(PdaColors.green)
          PdaIcon(name: "\(icon)_green", size: 14)
        } else {
          PdaIcon(name: icon, size: 14, template: true)
        }
      }
      .widgetAccentable()
    }
  }
}

struct PdaCooldownRow: View {
  var snapshot: PdaSnapshot
  var date: Date
  var showsDurations = true

  var body: some View {
    HStack(spacing: showsDurations ? 14 : 8) {
      chip("drug", level: snapshot.drugLevel, end: snapshot.drugEnd)
      chip("medical", level: snapshot.medicalLevel, end: snapshot.medicalEnd)
      chip("booster", level: snapshot.boosterLevel, end: snapshot.boosterEnd)
      if snapshot.racing != .none {
        Link(destination: pdaLink("racing:clicked")) {
          PdaIcon(name: snapshot.racing == .completed ? "racing_completed" : "racing_progress", size: 15)
        }
      }
      Spacer(minLength: 0)
    }
  }

  @ViewBuilder
  private func chip(_ name: String, level: Int, end: Date?) -> some View {
    if let duration = compactDuration(from: date, to: end) {
      Link(destination: pdaLink("\(name):clicked")) {
        HStack(spacing: 4) {
          PdaIcon(name: "\(name)\(min(max(level, 1), 5))", size: 15)
          if showsDurations {
            Text(duration)
              .font(.system(size: 11, weight: .medium).monospacedDigit())
              .lineLimit(1)
              .fixedSize()
          }
        }
      }
    }
  }
}

struct PdaChainChip: View {
  var snapshot: PdaSnapshot
  var date: Date

  var body: some View {
    Link(destination: pdaLink("chain:box:clicked")) {
      HStack(spacing: 4) {
        PdaIcon(name: "chain_mini", size: 12, template: true)
        if snapshot.chainOnCooldown {
          Text("COOLDOWN").font(.system(size: 10, weight: .semibold))
        } else {
          Text(verbatim: "\(snapshot.chainCurrent)")
            .font(.system(size: 11, weight: .medium).monospacedDigit())
            .lineLimit(1)
            .fixedSize()
          PdaProgressBar(
            fraction: Double(snapshot.chainCurrent) / Double(snapshot.chainTier), color: PdaColors.chain, height: 4
          )
          .frame(width: 34)
          if let timeout = snapshot.chainTimeoutAt, timeout > date, snapshot.chainCurrent > 0 {
            PdaTimerText(until: timeout, date: date, size: 11, color: .orange)
          }
        }
      }
    }
  }
}

struct PdaMoneyText: View {
  var money: Int

  var body: some View {
    Text(compactMoney(money))
      .font(.system(size: 11, weight: .bold).monospacedDigit())
      .foregroundStyle(PdaColors.green)
  }
}

struct PdaFooter: View {
  var entry: PdaEntry

  var body: some View {
    HStack(spacing: 4) {
      if entry.error != nil {
        Image(systemName: "exclamationmark.triangle.fill")
          .font(.system(size: 10))
          .foregroundStyle(.orange)
      }
      Button(intent: PdaRefreshIntent()) {
        HStack(spacing: 4) {
          if let fetchedAt = entry.snapshot?.fetchedAt {
            Text(fetchedTime(fetchedAt, entry: entry))
              .font(.system(size: 10).monospacedDigit())
              .invalidatableContent()
          }
          Image(systemName: "arrow.clockwise").font(.system(size: 11, weight: .semibold))
        }
        .foregroundStyle(.secondary)
        .padding(.vertical, 4)
        .padding(.leading, 6)
        .contentShape(Rectangle())
      }
      .buttonStyle(.plain)
    }
  }
}

func fetchedTime(_ date: Date, entry: PdaEntry) -> String {
  let formatter = DateFormatter()
  formatter.locale = Locale(identifier: "en_US_POSIX")
  formatter.dateFormat = entry.use24h ? "HH:mm" : "hh:mm a"
  if entry.tornTime { formatter.timeZone = TimeZone(identifier: "UTC") }
  return formatter.string(from: date) + (entry.tornTime ? " TCT" : " LT")
}

struct PdaMessageView: View {
  var message: String
  var isError: Bool

  var body: some View {
    VStack(spacing: 8) {
      if isError {
        Image(systemName: "exclamationmark.triangle.fill").foregroundStyle(.orange)
      }
      Text(message)
        .font(.system(size: 12))
        .multilineTextAlignment(.center)
      Button(intent: PdaRefreshIntent()) {
        Label("Reload", systemImage: "arrow.clockwise").font(.system(size: 12, weight: .semibold))
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .widgetURL(pdaLink("open:app"))
  }
}
