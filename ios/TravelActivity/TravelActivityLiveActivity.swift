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

// MARK: - Live Activity Widget Configuration
@available(iOS 16.2, *)
struct TravelActivityLiveActivity: Widget {

  var body: some WidgetConfiguration {
    ActivityConfiguration(for: TravelActivityAttributes.self) { context in
      // Lock screen
      LockScreenLiveActivityView(context: context, currentDate: Date())
        .padding()
        .activityBackgroundTint(Color.black.opacity(0.7))
        .activitySystemActionForegroundColor(Color.white)
    } dynamicIsland: { context in
      // Dynamic Island
      let isReturningDI = isReturningToTorn(context: context)
      let arrivalDateDI = getArrivalDate(context: context)
      let earliestReturnDateDI = getEarliestReturnDate(context: context)
      let departureDateDI = getDepartureDate(context: context)

      return DynamicIsland(
        // Expanded regions
        expanded: {
          // Leading: origin or destination flag
          DynamicIslandExpandedRegion(.leading) {
            LocationPinViewForDI(
              flagAsset: isReturningDI
                ? context.state.currentDestinationFlagAsset
                : context.state.originFlagAsset,
              locationName: isReturningDI
                ? context.state.currentDestinationDisplayName
                : context.state.originDisplayName
            )
          }
          // Trailing: flipped flag
          DynamicIslandExpandedRegion(.trailing) {
            LocationPinViewForDI(
              flagAsset: isReturningDI
                ? context.state.originFlagAsset
                : context.state.currentDestinationFlagAsset,
              locationName: isReturningDI
                ? context.state.originDisplayName
                : context.state.currentDestinationDisplayName
            )
          }
          // Center: vehicle or checkmark
          DynamicIslandExpandedRegion(.center) {
            if !context.state.hasArrived {
              VehicleView(context: context, size: 24)
            } else {
              Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
                .font(.title3)
            }
          }
          // Bottom: ETA, Earliest Return, Countdown + flag
          DynamicIslandExpandedRegion(.bottom) {
            VStack(alignment: HorizontalAlignment.trailing, spacing: 2) {
              ProgressView(
                timerInterval: departureDateDI...arrivalDateDI,
                countsDown: false,
                label: { EmptyView() },
                currentValueLabel: { EmptyView() }
              )
              .if(isReturningDI) { $0.scaleEffect(x: -1, y: 1, anchor: .center) }
              .frame(height: 4)
              .padding(.vertical, 4)

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

                if let returnDate = earliestReturnDateDI {
                  VStack(alignment: HorizontalAlignment.center, spacing: 2) {
                    Text("EARLIEST\nRETURN")
                      .multilineTextAlignment(.center)
                      .font(.system(size: 9))
                      .foregroundColor(.white.opacity(0.7))
                    Text("\(timeString(from: Int(returnDate.timeIntervalSince1970))) LT")
                      .font(.caption)
                      .foregroundColor(.white)
                  }
                  .frame(maxWidth: .infinity, alignment: .center)
                } else {
                  Spacer().frame(maxWidth: .infinity)
                }

                if !context.state.hasArrived {
                  VStack(alignment: HorizontalAlignment.trailing, spacing: 2) {
                    Text("REMAINING")
                      .font(.caption2)
                      .foregroundColor(.white.opacity(0.7))
                    Text(
                      timerInterval: Date()...arrivalDateDI,
                      countsDown: true,
                      showsHours: arrivalDateDI.timeIntervalSinceNow >= 3600
                    )
                    .multilineTextAlignment(.trailing)
                    .font(.caption2)
                    .foregroundColor(.white)
                  }
                  .frame(maxWidth: .infinity, alignment: .center)
                } else {
                  Text("Arrived")
                    .font(.caption2)
                    .foregroundColor(.green)
                }
              }
              .frame(maxWidth: .infinity)
              .padding(.horizontal, 10)
              .padding(.bottom, 4)
            }
          }
        },
        // Compact regions
        compactLeading: {
          if isReturningDI {
            Image(context.state.currentDestinationFlagAsset)
              .resizable()
              .scaledToFit()
              .frame(width: 20, height: 20)
          } else {
            if context.state.hasArrived {
              Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            } else {
              VehicleView(context: context, size: 20)
                .padding(2)
            }
          }
        },
        compactTrailing: {
          if isReturningDI {
            HStack(spacing: 1) {
              Text("00:00")
                .hidden()
                .overlay(alignment: .leading) {
                  Text(
                    timerInterval: Date()...arrivalDateDI,
                    countsDown: true,
                    showsHours: arrivalDateDI.timeIntervalSinceNow >= 3600
                  ).font(.caption)
                }

              VehicleView(context: context, size: 20)
                .padding(2)
            }
          } else {
            if context.state.hasArrived {
              Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
            } else {
              HStack(spacing: 1) {
                Text("00:00")
                  .hidden()
                  .overlay(alignment: .leading) {
                    Text(
                      timerInterval: Date()...arrivalDateDI,
                      countsDown: true,
                      showsHours: arrivalDateDI.timeIntervalSinceNow >= 3600
                    ).font(.caption)
                  }

                Image(context.state.currentDestinationFlagAsset)
                  .resizable()
                  .scaledToFit()
                  .frame(width: 20, height: 20)
              }
            }
          }
        },
        // Minimal region
        minimal: {
          if context.state.hasArrived {
            Image(systemName: "checkmark.circle.fill")
              .foregroundColor(.green)
          } else {
            Image(context.state.currentDestinationFlagAsset)
              .resizable()
              .scaledToFit()
              .frame(width: 12, height: 12)
          }
        }
      )
      .widgetURL(URL(string: "tornpda://www.torn.com"))
      .keylineTint(Color.orange)
    }
  }
}

// MARK: - Lock Screen Live Activity View
@available(iOS 16.2, *)
struct LockScreenLiveActivityView: View {
  let context: ActivityViewContext<TravelActivityAttributes>
  let currentDate: Date

  private var isReturningLS: Bool { isReturningToTorn(context: context) }
  private var departureDateLS: Date { getDepartureDate(context: context) }
  private var arrivalDateLS: Date { getArrivalDate(context: context) }
  private var earliestReturnDateLS: Date? { getEarliestReturnDate(context: context) }

  var body: some View {
    VStack(alignment: .center, spacing: 8) {
      Text(
        context.state.hasArrived
          ? "\(context.state.activityStateTitle) \(context.state.currentDestinationDisplayName) at \(timeString(from: context.state.arrivalTimeTimestamp))"
          : "\(context.state.activityStateTitle) \(context.state.currentDestinationDisplayName)"
      )
      .font(.headline)
      .foregroundColor(.white)
      .multilineTextAlignment(.center)

      if !context.state.hasArrived && context.state.showProgressBar {
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
          ProgressView(
            timerInterval: departureDateLS...arrivalDateLS,
            countsDown: false,
            label: { EmptyView() },
            currentValueLabel: { EmptyView() }
          )
          .if(isReturningLS) { $0.scaleEffect(x: -1, y: 1, anchor: .center) }
          .frame(height: 4)
          .padding(.vertical, 4)

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
            } else {
              Spacer().frame(maxWidth: .infinity)
            }

            if !context.state.hasArrived {
              VStack(alignment: HorizontalAlignment.trailing, spacing: 2) {
                Text("REMAINING")
                  .font(.caption2)
                  .foregroundColor(.white.opacity(0.7))
                Text(
                  timerInterval: Date()...arrivalDateLS,
                  countsDown: true,
                  showsHours: arrivalDateLS.timeIntervalSinceNow >= 3600
                )
                .multilineTextAlignment(.trailing)
                .font(.caption2)
                .foregroundColor(.white)
              }
              .frame(maxWidth: .infinity, alignment: .center)
            } else {
              Text("Arrived")
                .font(.caption2)
                .foregroundColor(.green)
            }
          }
          .frame(maxWidth: .infinity)
          .padding(.horizontal, 10)
          .padding(.vertical, 4)
        }
      }
    }
    .padding(.horizontal)
  }
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
