// LiveActivityManager.swift
import ActivityKit
import Foundation

@available(iOS 16.2, *)
class LiveActivityManager {

  // MARK: - Properties

  /// The currently managed Live Activity instance.
  private var currentActivity: Activity<TravelActivityAttributes>?

  /// The most recent push token for the current Live Activity.
  public private(set) var activityPushToken: String?

  /// Callback to notify when a new push token is obtained or invalidated.
  var onNewActivityPushToken: ((String?) -> Void)?

  // MARK: - Errors

  enum LiveActivityError: Error, LocalizedError {
    case notEnabledByUser
    case activityRequestFailed(String)
    case noActiveActivityToUpdateOrUserDismissed
    case updateFailed(String)

    var errorDescription: String? {
      switch self {
      case .notEnabledByUser:
        return "Live Activities are not enabled by the user in system settings"
      case .activityRequestFailed(let msg): return "Failed to request Live Activity: \(msg)"
      case .noActiveActivityToUpdateOrUserDismissed:
        return "No active Live Activity to update, or it was dismissed by the user"
      case .updateFailed(let msg): return "Failed to update Live Activity: \(msg)"
      }
    }
  }

  // MARK: - START ACTIVITY
  func startTravelActivity(
    currentDestinationDisplayName: String, currentDestinationFlagAsset: String,
    originDisplayName: String, originFlagAsset: String,
    arrivalTimeTimestamp: Int, departureTimeTimestamp: Int, currentServerTimestamp: Int,
    vehicleAssetName: String, earliestReturnTimestamp: Int?,
    activityStateTitle: String, showProgressBar: Bool,
    hasArrived: Bool,
    defaultStaleOffsetEnRoute: TimeInterval = 2 * 60,
    staleOffsetArrived: TimeInterval = 10 * 60
  ) async throws {
    // First, check if Live Activities are enabled by the user in system settings.
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      throw LiveActivityError.notEnabledByUser
    }

    // If an activity is already managed by this instance, end it before starting a new one.
    // This ensures we only manage one travel activity at a time.
    if let existingActivity = currentActivity {
      await endActivityInternal(activity: existingActivity, isBeingReplaced: true)
    }
    // Clear any old push token; the new activity will get a new one.
    self.activityPushToken = nil
    self.onNewActivityPushToken?(nil)

    // Define the static attributes of the Live Activity (data that doesn't change during the activity's life).
    let attributes = TravelActivityAttributes(activityName: "Torn PDA Travel")

    // Define the initial state of the Live Activity's dynamic content.
    let initialState = TravelActivityAttributes.ContentState(
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

    let staleDateForDismissal: Date
    let relevanceScore: Double

    if hasArrived {
      staleDateForDismissal = Date().addingTimeInterval(staleOffsetArrived)
      relevanceScore = 50.0
    } else {
      let arrivalDate = Date(timeIntervalSince1970: TimeInterval(arrivalTimeTimestamp))
      staleDateForDismissal = arrivalDate.addingTimeInterval(defaultStaleOffsetEnRoute)
      relevanceScore = 100.0
    }

    // Prepare the full activity content, including state, stale date, and relevance score.
    let activityContent = ActivityContent(
      state: initialState,
      staleDate: staleDateForDismissal,
      relevanceScore: relevanceScore
    )

    do {
      // Request the system to start the Live Activity.
      let activity = try Activity<TravelActivityAttributes>.request(
        attributes: attributes,
        content: activityContent,
        pushType: .token  // Indicate that this activity will receive updates via push tokens.
      )
      // If successful, store the new activity and start observing its state and token changes.
      self.currentActivity = activity
      observeActivity(activity: activity)
      print(
        "LiveActivityManager: Started LA. hasArrived=\(hasArrived), staleDate=\(staleDateForDismissal)"
      )
    } catch {
      // If the request fails, ensure the push token state is clean and propagate the error.
      self.activityPushToken = nil
      self.onNewActivityPushToken?(nil)
      throw LiveActivityError.activityRequestFailed(error.localizedDescription)
    }
  }

  // MARK: - UPDATE ACTIVITY
  func updateTravelActivity(
    currentDestinationDisplayName: String, currentDestinationFlagAsset: String,
    originDisplayName: String, originFlagAsset: String,
    arrivalTimeTimestamp: Int, departureTimeTimestamp: Int, currentServerTimestamp: Int,
    vehicleAssetName: String, earliestReturnTimestamp: Int?,
    activityStateTitle: String, showProgressBar: Bool,
    hasArrived: Bool,
    defaultStaleOffsetEnRoute: TimeInterval = 2 * 60,
    staleOffsetArrived: TimeInterval = 10 * 60
  ) async throws {
    // Ensure there is an active activity managed by this instance to update.
    // Cannot update an activity that doesn't exist or was already dismissed by the user.
    guard let activityToUpdate = self.currentActivity, activityToUpdate.activityState == .active
    else {
      throw LiveActivityError.noActiveActivityToUpdateOrUserDismissed
    }

    // Determine if we have arrived arrived based on timestamps.
    let hasArrived = currentServerTimestamp >= arrivalTimeTimestamp
    // Prepare the new content state for the update.
    let newState = TravelActivityAttributes.ContentState(
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

    let staleDateForDismissal: Date
    let relevanceScore: Double

    if hasArrived {
      staleDateForDismissal = Date().addingTimeInterval(staleOffsetArrived)
      relevanceScore = 50.0
    } else {
      let arrivalDate = Date(timeIntervalSince1970: TimeInterval(arrivalTimeTimestamp))
      staleDateForDismissal = arrivalDate.addingTimeInterval(defaultStaleOffsetEnRoute)
      relevanceScore = 100.0
    }

    let updatedActivityContent = ActivityContent(
      state: newState,
      staleDate: staleDateForDismissal,
      relevanceScore: relevanceScore
    )

    // Update the Live Activity with the new content.
    await activityToUpdate.update(updatedActivityContent)
    print(
      "LiveActivityManager: Updated LA. hasArrived=\(hasArrived), staleDate=\(staleDateForDismissal)"
    )
  }

  // MARK: - END ACTIVITY
  func endCurrentTravelActivity() async {
    // Ensure there is a currently managed activity to end.
    guard let activityToEnd = currentActivity else {
      return  // Do nothing if there's no activity.
    }
    // Call the internal method to perform the end operation.
    await endActivityInternal(activity: activityToEnd)
  }

  func checkAndAdoptExistingActivities() {
    // Perform these checks asynchronously to avoid blocking the main thread.
    Task {
      // Variable to track if an activity has been adopted during this specific check.
      // This helps handle the case of multiple (undesired) active activities of the same type.
      var adoptedActivityThisCheck: Activity<TravelActivityAttributes>? = nil

      // Iterate over all Live Activities of type `TravelActivityAttributes`
      // that the system currently knows about (they might be from previous app sessions).
      for systemActivity in Activity<TravelActivityAttributes>.activities {
        switch systemActivity.activityState {
        case .active:
          // If we are not currently tracking any activity...
          if self.currentActivity == nil {
            // ...and we haven't adopted one yet in this check pass...
            if adoptedActivityThisCheck == nil {
              // ...adopt this active system activity.
              self.currentActivity = systemActivity
              observeActivity(activity: systemActivity)  // Start observing it.
              adoptedActivityThisCheck = systemActivity  // Mark it as adopted.
            } else {
              // ...but we have already adopted one in this pass, this is a duplicate active one. End it.
              await systemActivity.end(nil, dismissalPolicy: .immediate)
            }
            // If the system activity is the same one we are already tracking...
          } else if self.currentActivity?.id == systemActivity.id {
            // ...re-confirm observation to be safe (might be needed if the app restarted).
            observeActivity(activity: systemActivity)
            adoptedActivityThisCheck = systemActivity  // Mark it as (re)adopted.
          } else {
            // If we are tracking a different activity, then this active system activity
            // is one we are not tracking and is active. It should be ended to avoid duplicates.
            await systemActivity.end(nil, dismissalPolicy: .immediate)
          }
        case .ended, .dismissed:
          // If a system activity matching the ID of our tracked activity
          // is now ended or dismissed, clear our local reference.
          if self.currentActivity?.id == systemActivity.id {
            self.currentActivity = nil
          }
        case .stale:
          await systemActivity.end(nil, dismissalPolicy: .immediate)
        @unknown default:
          // Unknown state
          break
        }
      }

      // After iterating through all system activities:
      // If the activity we were previously tracking was not found/readopted in the system list,
      // it means it's no longer valid (e.g., the system cleaned it up). Clear our reference.
      if let tracked = self.currentActivity, adoptedActivityThisCheck?.id != tracked.id {
        self.currentActivity = nil
      }

      // Final push token state management after all checks:
      if self.currentActivity == nil {
        // If there's no current activity after checks, and we had a token, clear it.
        if self.activityPushToken != nil {
          self.activityPushToken = nil
          self.onNewActivityPushToken?(nil)
        }
      } else {  // There is a `currentActivity`.
        // If the current activity has a push token...
        if let currentTokenData = self.currentActivity?.pushToken {
          let tokenString = currentTokenData.map { String(format: "%02x", $0) }.joined()
          // ...and it's different from our stored token, update it and notify.
          if self.activityPushToken != tokenString {
            self.activityPushToken = tokenString
            self.onNewActivityPushToken?(tokenString)
          }
          // If the current activity exists but does NOT have a push token (e.g., error obtaining it),
          // and we DID have a stored token, clear it.
        } else if self.activityPushToken != nil {
          self.activityPushToken = nil
          self.onNewActivityPushToken?(nil)
        }
      }
    }
  }

  func getPushToStartToken(for activityType: String) -> String? {
    guard #available(iOS 17.2, *) else {
      NSLog("[LA_DEBUG_SWIFT] getPushToStartToken: iOS < 17.2")
      return nil
    }

    var tokenData: Data?

    switch activityType {
    case "travel":
      tokenData = Activity<TravelActivityAttributes>.pushToStartToken
    default:
      NSLog("Unsupported activity type for push-to-start: \(activityType)")
      return nil
    }

    guard let data = tokenData else {
      NSLog("[LA_DEBUG_SWIFT] pushToStartToken for type '\(activityType)' is nil.")
      return nil
    }

    let tokenString = data.map { String(format: "%02x", $0) }.joined()
    NSLog(
      "[LA_DEBUG_SWIFT] Returning token for type '\(activityType)': \(tokenString.prefix(10))...")
    return tokenString
  }

  // MARK: - Private Helpers
  func isAnyTravelActivityActive() -> Bool {
    return !Activity<TravelActivityAttributes>.activities.isEmpty
  }

  private func endActivityInternal(
    activity: Activity<TravelActivityAttributes>,
    isBeingReplaced: Bool = false  // Indicates if the activity is being ended to be replaced immediately.
  ) async {
    // Only attempt to end if the activity is actually active.
    guard activity.activityState == .active else {
      // If not active, but it was the one we had as `currentActivity`, clear the reference.
      if activity.id == self.currentActivity?.id {
        self.currentActivity = nil
        // Clear the token only if not being replaced (in which case, the new start will handle it).
        if !isBeingReplaced && self.activityPushToken != nil {
          self.activityPushToken = nil
          self.onNewActivityPushToken?(nil)
        }
      }
      return
    }

    // Request the system to end the activity immediately.
    // `nil` for content uses the last known state for the dismissal animation.
    await activity.end(nil, dismissalPolicy: .immediate)

    // If this was our tracked activity, clear the local reference.
    if activity.id == self.currentActivity?.id {
      self.currentActivity = nil
      // Clear the token only if not being replaced.
      if !isBeingReplaced && self.activityPushToken != nil {
        self.activityPushToken = nil
        self.onNewActivityPushToken?(nil)
      }
    }
  }

  private func observeActivity(activity activityToObserve: Activity<TravelActivityAttributes>) {
    // Only set up observers for the activity that is truly the `currentActivity`.
    // This prevents setting up multiple observers for the same activity or for old activities.
    guard activityToObserve.id == self.currentActivity?.id else {
      return
    }

    // Task to observe changes in the activity's state (e.g., active -> ended, active -> dismissed).
    Task { [weak self] in
      guard let self = self else { return }  // Avoid retain cycles.
      for await stateUpdate in activityToObserve.activityStateUpdates {
        // If this activity is no longer the `currentActivity`, stop observing for this task.
        guard activityToObserve.id == self.currentActivity?.id else {
          break
        }
        // If the activity reaches a terminal state (ended or dismissed)...
        if stateUpdate == .ended || stateUpdate == .dismissed {
          // ...and it's still our `currentActivity` (double-check)...
          if activityToObserve.id == self.currentActivity?.id {
            // ...clear the local state (activity reference and token).
            self.currentActivity = nil
            if self.activityPushToken != nil {
              self.activityPushToken = nil
              self.onNewActivityPushToken?(nil)
            }
          }
          break  // End this observation task as the activity is in a terminal state.
        }
      }
    }

    // Task to observe push token updates for the activity.
    Task { [weak self] in
      guard let self = self else { return }
      for await tokenData in activityToObserve.pushTokenUpdates {
        // If this activity is no longer the `currentActivity`, stop observing.
        guard activityToObserve.id == self.currentActivity?.id else {
          break
        }
        let newToken = tokenData.map { String(format: "%02x", $0) }.joined()
        // If the push token has changed, update local storage and notify observers.
        if self.activityPushToken != newToken {
          self.activityPushToken = newToken
          self.onNewActivityPushToken?(newToken)
        }
      }

    }
  }
}
