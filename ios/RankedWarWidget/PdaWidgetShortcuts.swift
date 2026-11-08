import AppIntents
import SwiftUI
import WidgetKit

struct PdaShortcutButton: View {
  var shortcut: PdaShortcut

  private var tintColor: Color? {
    guard let argb = UInt32(shortcut.iconTint, radix: 16) else { return nil }
    return Color(
      red: Double((argb >> 16) & 0xFF) / 255, green: Double((argb >> 8) & 0xFF) / 255,
      blue: Double(argb & 0xFF) / 255)
  }

  var body: some View {
    Link(destination: pdaLink("shortcut:\(shortcut.url)")) {
      HStack(spacing: 4) {
        if shortcut.name.count <= 10 {
          icon
        }
        Text(shortcut.name.uppercased())
          .font(.system(size: 10, weight: .semibold))
          .lineLimit(2)
          .multilineTextAlignment(.center)
          .minimumScaleFactor(0.7)
      }
      .padding(.horizontal, 4)
      .frame(maxWidth: .infinity, minHeight: 26, maxHeight: 34)
      .background(RoundedRectangle(cornerRadius: 8).fill(.quaternary))
    }
  }

  @ViewBuilder
  private var icon: some View {
    if let data = Data(base64Encoded: shortcut.iconBase64), let image = UIImage(data: data) {
      if shortcut.iconTint == "full" {
        Image(uiImage: image).resizable().scaledToFit().frame(width: 14, height: 14)
      } else {
        Image(uiImage: image)
          .renderingMode(.template)
          .resizable()
          .scaledToFit()
          .frame(width: 14, height: 14)
          .foregroundStyle(tintColor ?? .primary)
      }
    }
  }
}

struct PdaShortcutGrid: View {
  var shortcuts: [PdaShortcut]
  var columns: Int
  var limit: Int

  var body: some View {
    let visible = Array(shortcuts.prefix(limit))

    if visible.isEmpty {
      Link(destination: pdaLink("empty:shortcuts:clicked")) {
        VStack(spacing: 6) {
          PdaIcon(name: "shortcut_icon", size: 22)
          Text("No shortcuts configured, add some?")
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    } else {
      VStack(spacing: 4) {
        ForEach(0..<((visible.count + columns - 1) / columns), id: \.self) { row in
          HStack(spacing: 4) {
            ForEach(0..<columns, id: \.self) { column in
              let index = row * columns + column
              if index < visible.count {
                PdaShortcutButton(shortcut: visible[index])
              } else {
                Color.clear.frame(minHeight: 26, maxHeight: 34)
              }
            }
          }
        }
      }
    }
  }
}

struct PdaShortcutEntity: AppEntity {
  var id: String
  var name: String

  static let typeDisplayRepresentation: TypeDisplayRepresentation = "Shortcut"
  static let defaultQuery = PdaShortcutQuery()

  var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(name)") }
}

struct PdaShortcutQuery: EntityQuery {
  func entities(for identifiers: [String]) async throws -> [PdaShortcutEntity] {
    try await suggestedEntities().filter { identifiers.contains($0.id) }
  }

  func suggestedEntities() async throws -> [PdaShortcutEntity] {
    PdaWidgetStore.shortcuts().map { PdaShortcutEntity(id: $0.url, name: $0.name) }
  }
}

@available(iOS 18.0, *)
struct PdaShortcutControlIntent: ControlConfigurationIntent {
  static let title: LocalizedStringResource = "Torn PDA shortcut"

  @Parameter(title: "Shortcut")
  var shortcut: PdaShortcutEntity?
}

@available(iOS 18.0, *)
struct PdaOpenShortcutIntent: AppIntent {
  static let title: LocalizedStringResource = "Open Torn PDA shortcut"
  static let isDiscoverable = false

  @Parameter(title: "Shortcut")
  var shortcut: PdaShortcutEntity?

  init() {}

  init(shortcut: PdaShortcutEntity?) {
    self.shortcut = shortcut
  }

  func perform() async throws -> some IntentResult & OpensIntent {
    let action = shortcut.map { "shortcut:\($0.id)" } ?? "open:app"
    return .result(opensIntent: OpenURLIntent(pdaLink(action)))
  }
}

@available(iOS 18.0, *)
struct PdaShortcutControl: ControlWidget {
  var body: some ControlWidgetConfiguration {
    AppIntentControlConfiguration(kind: "PdaShortcutControl", intent: PdaShortcutControlIntent.self) { configuration in
      ControlWidgetButton(action: PdaOpenShortcutIntent(shortcut: configuration.shortcut)) {
        Label(configuration.shortcut?.name ?? "Torn PDA", systemImage: "bolt.fill")
      }
    }
    .displayName("Torn PDA shortcut")
    .description("Opens one of your Torn PDA shortcuts.")
  }
}
