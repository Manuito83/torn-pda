import ActivityKit
import SwiftUI

@available(iOS 16.2, *)
public struct RacingActivityAttributes: ActivityAttributes {

  public struct ContentState: Codable, Hashable {
    public var stateIdentifier: String
    public var phase: String
    public var titleText: String
    public var bodyText: String
    public var targetTimeTimestamp: Int?
    public var currentServerTimestamp: Int
    public var showTimer: Bool

    public init(
      stateIdentifier: String,
      phase: String,
      titleText: String,
      bodyText: String,
      targetTimeTimestamp: Int?,
      currentServerTimestamp: Int,
      showTimer: Bool
    ) {
      self.stateIdentifier = stateIdentifier
      self.phase = phase
      self.titleText = titleText
      self.bodyText = bodyText
      self.targetTimeTimestamp = targetTimeTimestamp
      self.currentServerTimestamp = currentServerTimestamp
      self.showTimer = showTimer
    }
  }

  public var activityName: String

  public init(activityName: String = "Torn PDA Racing") {
    self.activityName = activityName
  }
}
