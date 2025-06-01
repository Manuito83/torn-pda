// TravelActivityLiveActivity.swift
import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Global Helper Functions
@available(iOS 16.2, *)
private func timeString(from timestamp: Int) -> String {
  guard timestamp > 0 else { return "--:--" }
  let date = Date(timeIntervalSince1970: TimeInterval(timestamp))
  let formatter = DateFormatter()
  formatter.dateFormat = "HH:mm"
  return formatter.string(from: date)
}

@available(iOS 16.2, *)
private func getDepartureDate(context: ActivityViewContext<TravelActivityAttributes>) -> Date {
  Date(timeIntervalSince1970: TimeInterval(context.state.departureTimeTimestamp))
}

@available(iOS 16.2, *)
private func getArrivalDate(context: ActivityViewContext<TravelActivityAttributes>) -> Date {
  Date(timeIntervalSince1970: TimeInterval(context.state.arrivalTimeTimestamp))
}

@available(iOS 16.2, *)
private func getEarliestReturnDate(context: ActivityViewContext<TravelActivityAttributes>) -> Date?
{
  guard let ts = context.state.earliestReturnTimestamp, ts > 0 else { return nil }
  return Date(timeIntervalSince1970: TimeInterval(ts))
}

@available(iOS 16.2, *)
private func isReturningToTorn(context: ActivityViewContext<TravelActivityAttributes>) -> Bool {
  context.state.currentDestinationDisplayName == "Torn"
}

// MARK: - View Extension for Conditional Modifiers
extension View {
  @ViewBuilder
  func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
    if condition {
      transform(self)
    } else {
      self
    }
  }
}

// MARK: - Formatted Remaining Time View
@available(iOS 16.2, *)
struct FormattedRemainingTimeView: View {
  let arrivalDate: Date
  let isStale: Bool

  @ViewBuilder
  var body: some View {
    if isStale || arrivalDate.timeIntervalSinceNow <= 0 {
      Text("ARRIVED")
        .font(.caption2)
        .foregroundColor(.green.opacity(isStale ? 0.7 : 1.0))

    } else {
      Text(
        timerInterval: Date()...arrivalDate,
        countsDown: true,
        showsHours: arrivalDate.timeIntervalSinceNow >= 3600
      )
    }
  }
}

// MARK: - Live Activity Widget Configuration
@available(iOS 16.2, *)
struct TravelActivityLiveActivity: Widget {

  var body: some WidgetConfiguration {
    ActivityConfiguration(for: TravelActivityAttributes.self) { context in
      // Lock screen
      let effectiveHasArrivedForLockScreen = context.state.hasArrived || context.isStale
      LockScreenLiveActivityView(
        context: context,
        displayAsArrived: effectiveHasArrivedForLockScreen
      )
      .activityBackgroundTint(Color.black.opacity(0.7))
      .activitySystemActionForegroundColor(Color.white)
    } dynamicIsland: { context in
      dynamicIslandContent(context: context)
    }
  }
}

// MARK: - Lock Screen Live Activity View
@available(iOS 16.2, *)
struct LockScreenLiveActivityView: View {
  let context: ActivityViewContext<TravelActivityAttributes>
  let displayAsArrived: Bool

  private var isReturningLS: Bool { isReturningToTorn(context: context) }
  private var departureDateLS: Date { getDepartureDate(context: context) }
  private var arrivalDateLS: Date { getArrivalDate(context: context) }
  private var earliestReturnDateLS: Date? { getEarliestReturnDate(context: context) }

  var body: some View {
    VStack(alignment: .center, spacing: 8) {
      Text(
        displayAsArrived
          ? "\(context.state.activityStateTitle) \(context.state.currentDestinationDisplayName) at \(timeString(from: context.state.arrivalTimeTimestamp))"
          : "\(context.state.activityStateTitle) \(context.state.currentDestinationDisplayName)"
      )
      .font(.headline)
      .foregroundColor(context.isStale ? .white.opacity(0.7) : .white)
      .multilineTextAlignment(.center)

      if !displayAsArrived && context.state.showProgressBar {
        HStack(spacing: 0) {
          LocationPinView(
            flagAsset: isReturningLS
              ? context.state.currentDestinationFlagAsset
              : context.state.originFlagAsset,
            locationName: isReturningLS
              ? context.state.currentDestinationDisplayName
              : context.state.originDisplayName
          )
          Spacer(minLength: 4)
          VehicleView(context: context, size: 30)
          Spacer(minLength: 4)
          LocationPinView(
            flagAsset: isReturningLS
              ? context.state.originFlagAsset
              : context.state.currentDestinationFlagAsset,
            locationName: isReturningLS
              ? context.state.originDisplayName
              : context.state.currentDestinationDisplayName
          )
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 8)

        VStack(alignment: HorizontalAlignment.trailing, spacing: 2) {
          if !context.isStale {
            ProgressView(
              timerInterval: departureDateLS...arrivalDateLS,
              countsDown: false,
              label: { EmptyView() },
              currentValueLabel: { EmptyView() }
            )
            .if(isReturningLS) { $0.scaleEffect(x: -1, y: 1, anchor: .center) }
            .frame(height: 4)
            .padding(.vertical, 4)
          } else {
            // Stale "progress bar"
            Rectangle()
              .frame(height: 4)
              .foregroundColor(Color.gray.opacity(0.5))
              .padding(.vertical, 4)
          }

          HStack(alignment: .bottom, spacing: 8) {

            VStack(alignment: HorizontalAlignment.leading, spacing: 2) {
              Text("ETA")
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
              Text("\(timeString(from: context.state.arrivalTimeTimestamp))")
                .font(.caption)
                .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .opacity(context.isStale ? 0.7 : 1.0)

            if let returnDate = earliestReturnDateLS {
              VStack(alignment: HorizontalAlignment.center, spacing: 2) {
                Text("EARLIEST RETURN")
                  .multilineTextAlignment(.center)
                  .font(.system(size: 9))
                  .foregroundColor(.white.opacity(0.7))
                Text("\(timeString(from: Int(returnDate.timeIntervalSince1970))) LT")
                  .font(.caption)
                  .foregroundColor(.white)
              }
              .frame(maxWidth: .infinity, alignment: .center)
              .opacity(context.isStale ? 0.7 : 1.0)
            } else {
              Spacer().frame(maxWidth: .infinity)
            }

            if !displayAsArrived {
              VStack(alignment: HorizontalAlignment.trailing, spacing: 2) {
                Text("REMAINING")
                  .font(.caption2)
                  .foregroundColor(.white.opacity(0.7))
                FormattedRemainingTimeView(arrivalDate: arrivalDateLS, isStale: context.isStale)
                  .multilineTextAlignment(.trailing)
                  .font(.caption2)
                  .foregroundColor(.white)
              }
              .frame(maxWidth: .infinity, alignment: .center)
            } else {
              Text("Arrived")
                .font(.caption2)
                .foregroundColor(context.isStale ? .green.opacity(0.7) : .green)
            }
          }
          .frame(maxWidth: .infinity)
          .padding(.horizontal, 10)
          .padding(.vertical, 4)
        }
      } else if displayAsArrived {
        Image(systemName: "checkmark.circle.fill")
          .foregroundColor(context.isStale ? .green.opacity(0.7) : .green)
          .font(.largeTitle)
          .padding(.top)
      }
    }
    .padding()
  }
}

// MARK: - Dynamic Island Content Helper
@available(iOS 16.2, *)
private func dynamicIslandContent(context: ActivityViewContext<TravelActivityAttributes>)
  -> DynamicIsland
{
  let effectiveHasArrivedForDI = context.state.hasArrived || context.isStale
  let isReturningDI = isReturningToTorn(context: context)
  let arrivalDateDI = getArrivalDate(context: context)
  let earliestReturnDateDI = getEarliestReturnDate(context: context)
  let departureDateDI = getDepartureDate(context: context)

  return DynamicIsland(
    expanded: {
      DynamicIslandExpandedRegion(.leading) {
        LocationPinViewForDI(
          flagAsset: isReturningDI
            ? context.state.currentDestinationFlagAsset
            : context.state.originFlagAsset,
          locationName: isReturningDI
            ? context.state.currentDestinationDisplayName
            : context.state.originDisplayName
        )
        .opacity(context.isStale ? 0.7 : 1.0)
      }
      DynamicIslandExpandedRegion(.trailing) {
        LocationPinViewForDI(
          flagAsset: isReturningDI
            ? context.state.originFlagAsset
            : context.state.currentDestinationFlagAsset,
          locationName: isReturningDI
            ? context.state.originDisplayName
            : context.state.currentDestinationDisplayName
        )
        .opacity(context.isStale ? 0.7 : 1.0)
      }
      DynamicIslandExpandedRegion(.center) {
        if !effectiveHasArrivedForDI {
          VehicleView(context: context, size: 24)
        } else {
          Image(systemName: "checkmark.circle.fill")
            .foregroundColor(context.isStale ? .green.opacity(0.7) : .green)
            .font(.title3)
        }
      }
      DynamicIslandExpandedRegion(.bottom) {
        VStack(alignment: HorizontalAlignment.trailing, spacing: 2) {
          if !context.isStale {
            ProgressView(
              timerInterval: departureDateDI...arrivalDateDI,
              countsDown: false,
              label: { EmptyView() },
              currentValueLabel: { EmptyView() }
            )
            .if(isReturningDI) { $0.scaleEffect(x: -1, y: 1, anchor: .center) }
            .frame(height: 4)
            .padding(.vertical, 4)
          } else {
            Rectangle()
              .frame(height: 4)
              .foregroundColor(Color.gray.opacity(0.5))
              .padding(.vertical, 4)
          }

          HStack(alignment: .bottom, spacing: 8) {
            VStack(alignment: HorizontalAlignment.leading, spacing: 2) {
              Text("ETA")
                .font(.caption2)
                .foregroundColor(.white.opacity(context.isStale ? 0.5 : 0.7))
              Text("\(timeString(from: context.state.arrivalTimeTimestamp))")
                .font(.caption)
                .foregroundColor(.white.opacity(context.isStale ? 0.7 : 1.0))
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let returnDate = earliestReturnDateDI {
              VStack(alignment: HorizontalAlignment.center, spacing: 2) {
                Text("EARLIEST\nRETURN")
                  .multilineTextAlignment(.center)
                  .font(.system(size: 9))
                  .foregroundColor(.white.opacity(context.isStale ? 0.5 : 0.7))
                Text("\(timeString(from: Int(returnDate.timeIntervalSince1970))) LT")
                  .font(.caption)
                  .foregroundColor(.white.opacity(context.isStale ? 0.7 : 1.0))
              }
              .frame(maxWidth: .infinity, alignment: .center)
            } else {
              Spacer().frame(maxWidth: .infinity)
            }

            if !effectiveHasArrivedForDI {
              VStack(alignment: HorizontalAlignment.trailing, spacing: 2) {
                Text("REMAINING")
                  .font(.caption2)
                  .foregroundColor(.white.opacity(context.isStale ? 0.5 : 0.7))
                FormattedRemainingTimeView(arrivalDate: arrivalDateDI, isStale: context.isStale)
                  .multilineTextAlignment(.trailing)
                  .font(.caption2)
                  .foregroundColor(.white.opacity(context.isStale ? 0.7 : 1.0))
              }
              .frame(maxWidth: .infinity, alignment: .center)
            } else {
              Text("Arrived")
                .font(.caption2)
                .foregroundColor(context.isStale ? .green.opacity(0.7) : .green)
            }
          }
          .frame(maxWidth: .infinity)
          .padding(.horizontal, 10)
          .padding(.bottom, 4)
        }
      }
    },
    compactLeading: {
      if isReturningDI {
        Image(context.state.currentDestinationFlagAsset)
          .resizable().scaledToFit().frame(width: 20, height: 20)
          .opacity(context.isStale ? 0.7 : 1.0)
      } else {
        if effectiveHasArrivedForDI {
          Image(systemName: "checkmark.circle.fill")
            .foregroundColor(context.isStale ? .green.opacity(0.7) : .green)
        } else {
          VehicleView(context: context, size: 20).padding(2)
        }
      }
    },
    compactTrailing: {
      if isReturningDI {
        if effectiveHasArrivedForDI {
          Image(systemName: "checkmark.circle.fill")
            .foregroundColor(context.isStale ? .green.opacity(0.7) : .green)
        } else {
          HStack(spacing: 1) {
            Text("00h00m")
              .font(.caption)
              .hidden()
              .overlay(alignment: .leading) {
                FormattedRemainingTimeView(arrivalDate: arrivalDateDI, isStale: context.isStale)
                  .font(.caption)
              }
            VehicleView(context: context, size: 20).padding(2)
          }
        }
      } else {
        if effectiveHasArrivedForDI {
          Image(systemName: "checkmark.circle.fill")
            .foregroundColor(context.isStale ? .green.opacity(0.7) : .green)
        } else {
          HStack(spacing: 1) {
            Text("00h00m")
              .font(.caption)
              .hidden()
              .overlay(alignment: .leading) {
                FormattedRemainingTimeView(arrivalDate: arrivalDateDI, isStale: context.isStale)
                  .font(.caption)
              }
            Image(context.state.currentDestinationFlagAsset)
              .resizable().scaledToFit().frame(width: 20, height: 20)
          }
        }
      }
    },
    minimal: {
      if effectiveHasArrivedForDI {
        Image(systemName: "checkmark.circle.fill")
          .foregroundColor(context.isStale ? .green.opacity(0.7) : .green)
      } else {
        Image(context.state.currentDestinationFlagAsset)
          .resizable().scaledToFit().frame(width: 12, height: 12)
          .opacity(context.isStale ? 0.7 : 1.0)
      }
    }
  )
  .widgetURL(URL(string: "tornpda://www.torn.com"))
  .keylineTint(context.isStale ? Color.gray : Color.orange)
}

// MARK: - Supporting Views
@available(iOS 16.2, *)
struct LocationPinView: View {
  let flagAsset: String
  let locationName: String

  var body: some View {
    VStack(spacing: 2) {
      Image(flagAsset)
        .resizable()
        .scaledToFit()
        .frame(width: 24, height: 24)
      Text(locationName)
        .font(.caption.weight(.medium))
        .foregroundColor(.white)
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }
    .frame(width: 75)
  }
}

@available(iOS 16.2, *)
struct LocationPinViewForDI: View {
  let flagAsset: String
  let locationName: String

  var body: some View {
    VStack(spacing: 1) {
      Image(flagAsset)
        .resizable()
        .scaledToFit()
        .frame(width: 18, height: 18)
      Text(locationName)
        .font(.system(size: 10))
        .foregroundColor(.white.opacity(0.8))
        .lineLimit(1)
    }
    .frame(width: 55)
  }
}

@available(iOS 16.2, *)
struct VehicleView: View {
  let context: ActivityViewContext<TravelActivityAttributes>
  let size: CGFloat

  private var vehicleName: String { context.state.vehicleAssetName }
  private var isActuallyReturning: Bool { isReturningToTorn(context: context) }
  private var shouldFlip: Bool {
    vehicleName.contains("sleigh") && isActuallyReturning
  }

  var body: some View {
    Image(vehicleName)
      .resizable()
      .scaledToFit()
      .frame(width: size, height: size)
      .rotation3DEffect(
        shouldFlip ? .degrees(180) : .degrees(0),
        axis: (x: 0, y: 1, z: 0)
      )
  }
}
