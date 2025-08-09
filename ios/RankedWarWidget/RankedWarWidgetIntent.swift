import AppIntents
import Foundation
import home_widget  // Asegúrate de que este import está presente

// El appGroup se puede definir aquí para reusarlo
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
      prefs.setValue(true, forKey: "reloading")
    }

    await HomeWidgetBackgroundWorker.run(
      url: URL(string: "pdaWidget://reload_clicked"),
      appGroup: appGroup
    )

    print("ReloadWidgetActionIntent: Background task initiated to call pdaWidget_callback")

    return .result()
  }
}

@available(iOS 17, *)
@available(iOSApplicationExtension, unavailable)
extension ReloadWidgetActionIntent: ForegroundContinuableIntent {}
