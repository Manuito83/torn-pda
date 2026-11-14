import SwiftUI
import WidgetKit

struct PdaBarStyle {
  var bar: PdaBar
  var icon: String
  var symbol: String
  var color: Color
  var action: String
  var showsMaximum: Bool

  func label(at date: Date) -> String {
    let value = bar.value(at: date)
    return showsMaximum ? "\(value)/\(bar.maximum)" : "\(value)"
  }
}

extension PdaSnapshot {
  var energyStyle: PdaBarStyle {
    PdaBarStyle(
      bar: energy, icon: "energy_mini", symbol: "bolt.fill", color: PdaColors.energy,
      action: "energy:box:clicked", showsMaximum: true)
  }
  var nerveStyle: PdaBarStyle {
    PdaBarStyle(
      bar: nerve, icon: "nerve_mini", symbol: "flame.fill", color: PdaColors.nerve,
      action: "nerve:box:clicked", showsMaximum: true)
  }
  var happyStyle: PdaBarStyle {
    PdaBarStyle(
      bar: happy, icon: "happy_mini", symbol: "face.smiling.inverse", color: PdaColors.happy,
      action: "happy:box:clicked", showsMaximum: false)
  }
  var lifeStyle: PdaBarStyle {
    PdaBarStyle(
      bar: life, icon: "life_mini", symbol: "heart.fill", color: PdaColors.life,
      action: "life:box:clicked", showsMaximum: false)
  }

  func style(for lockBar: PdaLockBar) -> PdaBarStyle {
    switch lockBar {
    case .energy: return energyStyle
    case .nerve: return nerveStyle
    case .happy: return happyStyle
    case .life: return lifeStyle
    }
  }
}

struct PdaProgressBar: View {
  var fraction: Double
  var color: Color
  var height: CGFloat

  var body: some View {
    Capsule()
      .fill(.quaternary)
      .overlay(alignment: .leading) {
        Rectangle()
          .fill(color)
          .scaleEffect(x: fraction.isFinite ? min(max(fraction, 0), 1) : 0, y: 1, anchor: .leading)
          .widgetAccentable()
      }
      .clipShape(Capsule())
      .frame(height: height)
  }
}

struct PdaBarRow: View {
  var style: PdaBarStyle
  var date: Date
  var height: CGFloat = 6

  var body: some View {
    Link(destination: pdaLink(style.action)) {
      VStack(alignment: .leading, spacing: 2) {
        HStack(spacing: 4) {
          PdaIcon(name: style.icon, size: 12)
          Spacer(minLength: 2)
          Text(verbatim: style.label(at: date))
            .font(.system(size: 11, weight: .medium).monospacedDigit())
            .lineLimit(1)
        }
        PdaProgressBar(fraction: style.bar.fraction(at: date), color: style.color, height: height)
      }
    }
  }
}

struct PdaBarCell: View {
  var style: PdaBarStyle
  var date: Date

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      PdaBarRow(style: style, date: date)
      Text(style.bar.fullCaption(at: date))
        .font(.system(size: 9))
        .foregroundStyle(.secondary)
        .lineLimit(1)
    }
  }
}

struct PdaCompactBarRow: View {
  var style: PdaBarStyle
  var date: Date

  var body: some View {
    Link(destination: pdaLink(style.action)) {
      HStack(spacing: 4) {
        PdaIcon(name: style.icon, size: 11)
        PdaProgressBar(fraction: style.bar.fraction(at: date), color: style.color, height: 5)
        Text(verbatim: style.label(at: date))
          .font(.system(size: 10, weight: .medium).monospacedDigit())
          .lineLimit(1)
          .fixedSize()
      }
    }
  }
}
