import AppIntents
import Foundation
import WidgetKit
import home_widget

private let appGroup = "group.com.manuito.tornpda"

@available(iOS 17, *)
public struct PdaWidgetMainIntent: WidgetConfigurationIntent {
  static public var title: LocalizedStringResource = "Ranked War Widget"
  static public var description = IntentDescription(
    "Displays the current status of the ranked war.")

  public init() {}
}

@available(iOS 17, *)
public struct ReloadWidgetActionIntent: AppIntent {

  static public var title: LocalizedStringResource = "Reload Widget Data"

  public init() {}

  public func perform() async throws -> some IntentResult {
    if let prefs = UserDefaults(suiteName: appGroup) {
      prefs.setValue("Updating...", forKey: "last_updated")
      prefs.setValue(true, forKey: "reloading")
      prefs.synchronize()
    }

    WidgetCenter.shared.reloadTimelines(ofKind: "HomeWidgetRankedWar")

    Task {
      await HomeWidgetBackgroundWorker.run(
        url: URL(string: "pdaWidget://reload_clicked"), appGroup: appGroup)
    }

    return .result()
  }
}

@available(iOS 17, *)
@available(iOSApplicationExtension, unavailable)
extension ReloadWidgetActionIntent: ForegroundContinuableIntent {}
