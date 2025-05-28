// TravelActivityAttributes.swift
import ActivityKit
import SwiftUI

@available(iOS 16.2, *)
public struct TravelActivityAttributes: ActivityAttributes {

  public struct ContentState: Codable, Hashable {
    public var currentDestinationDisplayName: String
    public var currentDestinationFlagAsset: String
    public var originDisplayName: String
    public var originFlagAsset: String
    public var arrivalTimeTimestamp: Int
    public var departureTimeTimestamp: Int
    public var currentServerTimestamp: Int
    public var vehicleAssetName: String
    public var earliestReturnTimestamp: Int?
    public var activityStateTitle: String
    public var showProgressBar: Bool
    public var hasArrived: Bool

    public init(
      currentDestinationDisplayName: String,
      currentDestinationFlagAsset: String,
      originDisplayName: String,
      originFlagAsset: String,
      arrivalTimeTimestamp: Int,
      departureTimeTimestamp: Int,
      currentServerTimestamp: Int,
      vehicleAssetName: String,
      earliestReturnTimestamp: Int?,
      activityStateTitle: String,
      showProgressBar: Bool = true,
      hasArrived: Bool = false
    ) {
      self.currentDestinationDisplayName = currentDestinationDisplayName
      self.currentDestinationFlagAsset = currentDestinationFlagAsset
      self.originDisplayName = originDisplayName
      self.originFlagAsset = originFlagAsset
      self.arrivalTimeTimestamp = arrivalTimeTimestamp
      self.departureTimeTimestamp = departureTimeTimestamp
      self.currentServerTimestamp = currentServerTimestamp
      self.vehicleAssetName = vehicleAssetName
      self.earliestReturnTimestamp = earliestReturnTimestamp
      self.activityStateTitle = activityStateTitle
      self.showProgressBar = showProgressBar
      self.hasArrived = hasArrived
    }
  }

  public var activityName: String

  public init(activityName: String = "Torn PDA Travel") {
    self.activityName = activityName
  }
}
