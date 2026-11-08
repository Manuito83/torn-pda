import SwiftUI
import WidgetKit

struct PdaSmallView: View {
  var entry: PdaEntry
  var snapshot: PdaSnapshot

  var body: some View {
    VStack(alignment: .leading, spacing: 5) {
      HStack {
        PdaStatusLine(snapshot: snapshot, date: entry.date, size: 12)
        Spacer(minLength: 0)
      }
      PdaBarRow(style: snapshot.energyStyle, date: entry.date)
      PdaBarRow(style: snapshot.nerveStyle, date: entry.date)
      PdaBarRow(style: snapshot.happyStyle, date: entry.date)
      PdaBarRow(style: snapshot.lifeStyle, date: entry.date)
      Spacer(minLength: 0)
      HStack {
        PdaInboxBadges(snapshot: snapshot)
        Spacer(minLength: 0)
        PdaFooter(entry: entry)
      }
    }
    .widgetURL(pdaLink("open:app"))
  }
}

struct PdaMediumView: View {
  var entry: PdaEntry
  var snapshot: PdaSnapshot

  var body: some View {
    if entry.configuration.showShortcuts {
      HStack(spacing: 10) {
        VStack(alignment: .leading, spacing: 5) {
          PdaStatusLine(snapshot: snapshot, date: entry.date, size: 12)
          PdaCompactBarRow(style: snapshot.energyStyle, date: entry.date)
          PdaCompactBarRow(style: snapshot.nerveStyle, date: entry.date)
          PdaCompactBarRow(style: snapshot.happyStyle, date: entry.date)
          PdaCompactBarRow(style: snapshot.lifeStyle, date: entry.date)
          Spacer(minLength: 0)
          HStack(spacing: 4) {
            PdaCooldownRow(snapshot: snapshot, date: entry.date, showsDurations: false)
            PdaInboxBadges(snapshot: snapshot)
          }
          HStack {
            if entry.configuration.showMoney {
              PdaMoneyText(money: snapshot.money)
            }
            Spacer(minLength: 0)
            PdaFooter(entry: entry)
          }
        }
        .frame(maxWidth: .infinity)
        PdaShortcutGrid(shortcuts: entry.shortcuts, columns: 2, limit: 6)
          .frame(maxWidth: .infinity)
      }
    } else {
      VStack(alignment: .leading, spacing: 6) {
        HStack {
          PdaStatusLine(snapshot: snapshot, date: entry.date)
          Spacer(minLength: 4)
          PdaInboxBadges(snapshot: snapshot)
        }
        HStack(spacing: 12) {
          PdaBarRow(style: snapshot.energyStyle, date: entry.date)
          PdaBarRow(style: snapshot.nerveStyle, date: entry.date)
        }
        HStack(spacing: 12) {
          PdaBarRow(style: snapshot.happyStyle, date: entry.date)
          PdaBarRow(style: snapshot.lifeStyle, date: entry.date)
        }
        Spacer(minLength: 0)
        PdaCooldownRow(snapshot: snapshot, date: entry.date)
        HStack(spacing: 10) {
          PdaChainChip(snapshot: snapshot, date: entry.date)
          if entry.configuration.showMoney {
            PdaMoneyText(money: snapshot.money)
          }
          Spacer(minLength: 0)
          PdaFooter(entry: entry)
        }
      }
    }
  }
}

struct PdaLargeView: View {
  var entry: PdaEntry
  var snapshot: PdaSnapshot

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        PdaStatusLine(snapshot: snapshot, date: entry.date, size: 15)
        Spacer(minLength: 4)
        PdaInboxBadges(snapshot: snapshot)
      }
      HStack(spacing: 14) {
        PdaBarCell(style: snapshot.energyStyle, date: entry.date)
        PdaBarCell(style: snapshot.nerveStyle, date: entry.date)
      }
      HStack(spacing: 14) {
        PdaBarCell(style: snapshot.happyStyle, date: entry.date)
        PdaBarCell(style: snapshot.lifeStyle, date: entry.date)
      }
      Divider()
      PdaCooldownRow(snapshot: snapshot, date: entry.date)
      PdaTimersRow(snapshot: snapshot, date: entry.date)
      Spacer(minLength: 0)
      PdaShortcutGrid(shortcuts: entry.shortcuts, columns: 3, limit: 9)
      HStack(spacing: 10) {
        PdaChainChip(snapshot: snapshot, date: entry.date)
        if entry.configuration.showMoney {
          PdaMoneyText(money: snapshot.money)
        }
        Spacer(minLength: 0)
        PdaFooter(entry: entry)
      }
    }
  }
}

struct PdaLockCircularView: View {
  var entry: PdaEntry
  var snapshot: PdaSnapshot

  var body: some View {
    let style = snapshot.style(for: entry.configuration.lockBar)
    Gauge(value: style.bar.fraction(at: entry.date)) {
      Image(systemName: style.symbol)
    } currentValueLabel: {
      Text(verbatim: "\(style.bar.value(at: entry.date))").monospacedDigit()
    }
    .gaugeStyle(.accessoryCircular)
    .widgetURL(pdaLink(style.action))
  }
}

struct PdaLockRectangularView: View {
  var entry: PdaEntry
  var snapshot: PdaSnapshot

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      PdaStatusLine(snapshot: snapshot, date: entry.date, size: 12)
      lockBar(snapshot.energyStyle)
      lockBar(snapshot.nerveStyle)
    }
    .widgetURL(pdaLink("open:app"))
  }

  private func lockBar(_ style: PdaBarStyle) -> some View {
    Gauge(value: style.bar.fraction(at: entry.date)) {
      EmptyView()
    } currentValueLabel: {
      EmptyView()
    } minimumValueLabel: {
      Text(Image(systemName: style.symbol)).font(.system(size: 9))
    } maximumValueLabel: {
      Text(verbatim: "\(style.bar.value(at: entry.date))").font(.system(size: 10).monospacedDigit())
    }
    .gaugeStyle(.accessoryLinearCapacity)
  }
}

struct PdaLockInlineView: View {
  var entry: PdaEntry
  var snapshot: PdaSnapshot

  var body: some View {
    let status = snapshot.status(at: entry.date)
    let energy = snapshot.energy.value(at: entry.date)

    if let until = status.until {
      Text("\(status.title) \(until, style: .timer)")
    } else {
      Text("\(Image(systemName: "bolt.fill")) \(String(energy))/\(String(snapshot.energy.maximum)) - \(status.title)")
    }
  }
}

struct PdaBarsEntryView: View {
  @Environment(\.widgetFamily) private var family
  var entry: PdaEntry

  var body: some View {
    if let snapshot = entry.snapshot {
      switch family {
      case .systemSmall: PdaSmallView(entry: entry, snapshot: snapshot)
      case .systemMedium: PdaMediumView(entry: entry, snapshot: snapshot)
      case .accessoryCircular: PdaLockCircularView(entry: entry, snapshot: snapshot)
      case .accessoryRectangular: PdaLockRectangularView(entry: entry, snapshot: snapshot)
      case .accessoryInline: PdaLockInlineView(entry: entry, snapshot: snapshot)
      default: PdaLargeView(entry: entry, snapshot: snapshot)
      }
    } else {
      PdaMessageView(message: entry.error ?? "Loading...", isError: entry.error != nil)
    }
  }
}

struct PdaBarsWidget: Widget {
  var body: some WidgetConfiguration {
    if #available(iOS 26.0, *) {
      return configuration.pushHandler(PdaWidgetPushHandler.self)
    } else {
      return configuration
    }
  }

  private var configuration: some WidgetConfiguration {
    AppIntentConfiguration(kind: "HomeWidgetTornPda", intent: PdaBarsIntent.self, provider: PdaBarsProvider()) {
      entry in
      PdaBarsEntryView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("Torn PDA")
    .description("Bars, status, cooldowns and shortcuts.")
    .supportedFamilies([
      .systemSmall, .systemMedium, .systemLarge, .accessoryCircular, .accessoryRectangular, .accessoryInline,
    ])
  }
}
