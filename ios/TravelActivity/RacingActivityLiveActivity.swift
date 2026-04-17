import ActivityKit
import SwiftUI
import WidgetKit

@available(iOS 16.2, *)
private func racingTargetDate(context: ActivityViewContext<RacingActivityAttributes>) -> Date? {
  guard let timestamp = context.state.targetTimeTimestamp, timestamp > 0 else { return nil }
  return Date(timeIntervalSince1970: TimeInterval(timestamp))
}

@available(iOS 16.2, *)
private func racingStartDate(context: ActivityViewContext<RacingActivityAttributes>) -> Date? {
  guard let timestamp = context.state.startTimeTimestamp, timestamp > 0 else { return nil }
  return Date(timeIntervalSince1970: TimeInterval(timestamp))
}

@available(iOS 16.2, *)
private func racingCountdownLabel(for phase: String) -> String {
  switch phase {
  case "waiting":
    return "STARTS IN"
  case "racing":
    return "ENDS IN"
  default:
    return "STATUS"
  }
}

@available(iOS 16.2, *)
private func racingTint(for phase: String, isStale: Bool) -> Color {
  switch phase {
  case "finished":
    return isStale ? .green.opacity(0.7) : .green
  case "waiting", "waitingUnknown":
    return isStale ? .orange.opacity(0.7) : .orange
  default:
    return isStale ? .blue.opacity(0.7) : .blue
  }
}

@available(iOS 16.2, *)
private struct RacingTimerView: View {
  let targetDate: Date
  let isStale: Bool

  var body: some View {
    if isStale || targetDate.timeIntervalSinceNow <= 0 {
      Text("NOW")
        .font(.caption.weight(.semibold))
        .foregroundColor(.white.opacity(isStale ? 0.7 : 1.0))
    } else {
      Text(
        timerInterval: Date()...targetDate,
        countsDown: true,
        showsHours: targetDate.timeIntervalSinceNow >= 3600
      )
      .multilineTextAlignment(.center)
      .frame(maxWidth: .infinity)
      .monospacedDigit()
    }
  }
}

@available(iOS 16.2, *)
struct RacingActivityLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: RacingActivityAttributes.self) { context in
      RacingLockScreenLiveActivityView(context: context)
        .activityBackgroundTint(Color.black.opacity(0.7))
        .activitySystemActionForegroundColor(Color.white)
    } dynamicIsland: { context in
      racingDynamicIsland(context: context)
    }
  }
}

@available(iOS 16.2, *)
private struct RacingLockScreenLiveActivityView: View {
  let context: ActivityViewContext<RacingActivityAttributes>

  private var targetDate: Date? { racingTargetDate(context: context) }
  private var startDate: Date? { racingStartDate(context: context) }
  private var phase: String { context.state.phase }
  private var tint: Color { racingTint(for: phase, isStale: context.isStale) }

  var body: some View {
    VStack(alignment: .center, spacing: 10) {
      HStack(spacing: 8) {
        Image(systemName: phase == "finished" ? "flag.checkered" : "car.fill")
          .foregroundColor(tint)
          .font(.title3)
        Text(context.state.titleText)
          .font(.headline)
          .foregroundColor(.white.opacity(context.isStale ? 0.7 : 1.0))
          .multilineTextAlignment(.center)
      }

      if phase == "finished" {
        Text(context.state.bodyText)
          .font(.caption)
          .foregroundColor(.white.opacity(context.isStale ? 0.65 : 0.85))
          .multilineTextAlignment(.center)
          .lineLimit(2)
      }

      if context.state.showTimer, let targetDate {
        if targetDate.timeIntervalSinceNow <= 0 {
          Text("FINISHED")
            .font(.caption.weight(.semibold))
            .foregroundColor(.white.opacity(0.85))
        } else {
          VStack(spacing: 4) {
            Text(racingCountdownLabel(for: phase))
              .font(.caption2)
              .foregroundColor(.white.opacity(0.7))
            RacingTimerView(targetDate: targetDate, isStale: context.isStale)
              .font(.system(size: 24, weight: .bold, design: .rounded))
              .foregroundColor(.white)
          }
        }

        if phase == "racing", let startDate {
          if !context.isStale {
            ProgressView(
              timerInterval: startDate...targetDate,
              countsDown: false,
              label: { EmptyView() },
              currentValueLabel: { EmptyView() }
            )
            .frame(height: 4)
            .padding(.horizontal, 8)
          } else {
            Rectangle()
              .frame(height: 4)
              .foregroundColor(Color.gray.opacity(0.5))
              .padding(.horizontal, 8)
          }
        }
      } else if phase == "waitingUnknown" {
        Text("Start time pending")
          .font(.caption.weight(.semibold))
          .foregroundColor(.white.opacity(context.isStale ? 0.65 : 0.85))
      } else if phase == "finished" {
        Image(systemName: "checkmark.circle.fill")
          .foregroundColor(tint)
          .font(.title)
      }
    }
    .padding()
  }
}

@available(iOS 16.2, *)
private func racingDynamicIsland(context: ActivityViewContext<RacingActivityAttributes>)
  -> DynamicIsland
{
  let phase = context.state.phase
  let tint = racingTint(for: phase, isStale: context.isStale)
  let targetDate = racingTargetDate(context: context)

  return DynamicIsland(
    expanded: {
      DynamicIslandExpandedRegion(.leading) {
        Image(systemName: phase == "finished" ? "flag.checkered" : "car.fill")
          .foregroundColor(tint)
      }
      DynamicIslandExpandedRegion(.trailing) {
        if context.state.showTimer, let targetDate {
          RacingTimerView(targetDate: targetDate, isStale: context.isStale)
            .font(.caption.weight(.semibold))
            .foregroundColor(.white.opacity(context.isStale ? 0.7 : 1.0))
        } else {
          Image(systemName: phase == "finished" ? "checkmark.circle.fill" : "clock")
            .foregroundColor(tint)
        }
      }
      DynamicIslandExpandedRegion(.bottom) {
        VStack(spacing: 4) {
          Text(context.state.titleText)
            .font(.caption.weight(.semibold))
            .foregroundColor(.white)
          if phase == "finished" {
            Text(context.state.bodyText)
              .font(.caption2)
              .foregroundColor(.white.opacity(context.isStale ? 0.65 : 0.85))
              .lineLimit(2)
              .multilineTextAlignment(.center)
          }

          if phase == "racing", let startDate = racingStartDate(context: context), let targetDate {
            if !context.isStale {
              ProgressView(
                timerInterval: startDate...targetDate,
                countsDown: false,
                label: { EmptyView() },
                currentValueLabel: { EmptyView() }
              )
              .frame(height: 4)
            } else {
              Rectangle()
                .frame(height: 4)
                .foregroundColor(Color.gray.opacity(0.5))
            }
          }
        }
      }
    },
    compactLeading: {
      Image(systemName: phase == "finished" ? "flag.checkered" : "car.fill")
        .foregroundColor(tint)
    },
    compactTrailing: {
      if context.state.showTimer, let targetDate {
        Text("00m00s")
          .font(.caption2)
          .hidden()
          .overlay(alignment: .leading) {
            RacingTimerView(targetDate: targetDate, isStale: context.isStale)
              .font(.caption2)
          }
      } else {
        Image(systemName: phase == "finished" ? "checkmark.circle.fill" : "clock")
          .foregroundColor(tint)
      }
    },
    minimal: {
      Image(systemName: phase == "finished" ? "flag.checkered" : "car.fill")
        .foregroundColor(tint)
    }
  )
  .widgetURL(URL(string: "tornpda://www.torn.com/page.php?sid=racing"))
  .keylineTint(tint)
}
