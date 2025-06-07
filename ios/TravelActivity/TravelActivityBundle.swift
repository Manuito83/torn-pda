import SwiftUI
import WidgetKit

@main
struct TravelActivityBundle: WidgetBundle {
  var body: some Widget {
    if #available(iOS 16.2, *) {
      TravelActivityLiveActivity()
    }
  }
}
