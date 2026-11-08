import Foundation
import WidgetKit

@available(iOS 26.0, *)
struct PdaWidgetPushHandler: WidgetPushHandler {
  func pushTokenDidChange(_ pushInfo: WidgetPushInfo, widgets: [WidgetInfo]) {
    let token = pushInfo.token.map { String(format: "%02x", $0) }.joined()
    UserDefaults(suiteName: pdaAppGroup)?.set(widgets.isEmpty ? "" : token, forKey: "widget_push_token")
  }
}
