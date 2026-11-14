import SwiftUI
import WidgetKit

@main
struct RankedWarWidgetBundle: WidgetBundle {
  var body: some Widget {
    RankedWarWidget()
    PdaBarsWidget()
    if #available(iOS 18.0, *) {
      PdaShortcutControl()
    }
  }
}
