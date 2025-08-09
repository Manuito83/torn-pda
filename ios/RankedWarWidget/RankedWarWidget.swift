import AppIntents
import SwiftUI
import WidgetKit

struct RankedWarEntry: TimelineEntry {
  let date: Date
  let state: String
  let upcomingCountdown: String
  let upcomingDate: String
  let activePlayerScore: Int
  let activeEnemyScore: Int
  let activeTargetScore: Int
  let activePlayerTag: String
  let activeEnemyName: String
  let lastUpdated: String
  let reloading: Bool
  let widgetVisible: Bool
  let darkMode: Bool
}

struct RankedWarProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> RankedWarEntry {
    RankedWarEntry(
      date: Date(), state: "active", upcomingCountdown: "Loading...", upcomingDate: "",
      activePlayerScore: 1234, activeEnemyScore: 567, activeTargetScore: 2500,
      activePlayerTag: "[ME]", activeEnemyName: "The Enemy", lastUpdated: "Just now",
      reloading: false, widgetVisible: true, darkMode: false
    )
  }

  func snapshot(
    for configuration: PdaWidgetMainIntent, in context: Context
  ) async -> RankedWarEntry {
    loadData()
  }

  func timeline(
    for configuration: PdaWidgetMainIntent, in context: Context
  ) async -> Timeline<RankedWarEntry> {
    let entry = loadData()
    let nextUpdateDate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
    return Timeline(entries: [entry], policy: .after(nextUpdateDate))
  }

  private func loadData() -> RankedWarEntry {
    guard let prefs = UserDefaults(suiteName: "group.com.manuito.tornpda") else {
      return RankedWarEntry(
        date: Date(),
        state: "error",
        upcomingCountdown: "Config Error",
        upcomingDate: "",
        activePlayerScore: 0,
        activeEnemyScore: 0,
        activeTargetScore: 0,
        activePlayerTag: "N/A",
        activeEnemyName: "",
        lastUpdated: "Now",
        reloading: false,
        widgetVisible: true,
        darkMode: false
      )
    }

    let state = prefs.string(forKey: "rw_state") ?? "none"
    let upcomingCountdown = prefs.string(forKey: "rw_countdown_string") ?? "Loading..."
    let upcomingDate = prefs.string(forKey: "rw_date_string") ?? ""
    let activePlayerScore = prefs.integer(forKey: "rw_player_score")
    let activeEnemyScore = prefs.integer(forKey: "rw_enemy_score")
    let activeTargetScore = prefs.integer(forKey: "rw_target_score")
    let activePlayerTag = prefs.string(forKey: "rw_player_faction_tag") ?? ""
    let activeEnemyName = prefs.string(forKey: "rw_enemy_faction_name") ?? ""
    let lastUpdated = prefs.string(forKey: "last_updated") ?? "Updating..."
    let reloading = prefs.bool(forKey: "reloading")
    let widgetVisible = prefs.bool(forKey: "rw_widget_visibility")
    let darkMode = prefs.bool(forKey: "darkMode")

    return RankedWarEntry(
      date: Date(), state: state, upcomingCountdown: upcomingCountdown, upcomingDate: upcomingDate,
      activePlayerScore: activePlayerScore, activeEnemyScore: activeEnemyScore,
      activeTargetScore: activeTargetScore, activePlayerTag: activePlayerTag,
      activeEnemyName: activeEnemyName, lastUpdated: lastUpdated, reloading: reloading,
      widgetVisible: widgetVisible, darkMode: darkMode
    )
  }
}

struct RankedWarWidgetEntryView: View {
  var entry: RankedWarProvider.Entry

  var body: some View {
    if !entry.widgetVisible {
      NoWarView(
        message: "No war data available", lastUpdated: entry.lastUpdated, reloading: entry.reloading
      )
    } else {
      VStack(spacing: 0) {
        HeaderView(lastUpdated: entry.lastUpdated, reloading: entry.reloading)
        switch entry.state {
        case "upcoming":
          UpcomingWarView(countdown: entry.upcomingCountdown, date: entry.upcomingDate)
        case "active":
          ActiveWarView(
            playerScore: entry.activePlayerScore, enemyScore: entry.activeEnemyScore,
            targetScore: entry.activeTargetScore, playerTag: entry.activePlayerTag,
            enemyName: entry.activeEnemyName
          )
        case "error":
          NoWarView(message: entry.upcomingCountdown, lastUpdated: "", reloading: false)
        default:
          NoWarView(
            message: "No active war", lastUpdated: entry.lastUpdated, reloading: entry.reloading)
        }
      }
    }
  }
}

struct HeaderView: View {
  let lastUpdated: String
  let reloading: Bool

  var body: some View {
    HStack {

      Text(lastUpdated == "Updating..." ? "" : lastUpdated)
        .font(.caption2)
        .foregroundColor(.gray)

      Spacer()

      Button(intent: ReloadWidgetActionIntent()) {
        SpinningReloadIcon(reloading: reloading)
          .font(.caption)
          .foregroundColor(reloading ? .accentColor : .gray)
      }
      .buttonStyle(.plain)
      .disabled(reloading)

    }
    .padding([.horizontal, .top])
  }
}

struct UpcomingWarView: View {
  let countdown: String
  let date: String
  var body: some View {
    VStack {
      Text(countdown).font(.largeTitle).fontWeight(.bold)
      Text(date).font(.caption)
    }
    .padding()
    .widgetURL(URL(string: "pdaWidget://open:app"))
  }
}

struct ActiveWarView: View {
  let playerScore: Int
  let enemyScore: Int
  let targetScore: Int
  let playerTag: String
  let enemyName: String

  var body: some View {
    let progress = abs(playerScore - enemyScore)
    let percentageValue = targetScore > 0 ? (Double(progress) * 100.0) / Double(targetScore) : 0.0
    VStack {
      HStack {
        Text(playerTag).fontWeight(.bold)
        Spacer()
        Text(enemyName).fontWeight(.bold)
      }
      HStack {
        Text("\(playerScore)").foregroundColor(playerScore >= enemyScore ? .green : .red)
        Spacer()
        Text("\(enemyScore)").foregroundColor(enemyScore > playerScore ? .green : .red)
      }
      ProgressView(value: Double(progress), total: Double(targetScore)).progressViewStyle(
        LinearProgressViewStyle())
      HStack {
        Text("\(progress) / \(targetScore)")
        Spacer()
        Text(String(format: "%.1f%%", percentageValue))
      }.font(.caption)
    }
    .padding()
    .widgetURL(URL(string: "pdaWidget://open:app"))
  }
}

struct NoWarView: View {
  let message: String
  let lastUpdated: String
  let reloading: Bool

  var body: some View {
    VStack(spacing: 0) {
      HeaderView(lastUpdated: lastUpdated, reloading: reloading)
      Spacer()
      Text(message).padding()
      Spacer()
    }
    .widgetURL(URL(string: "pdaWidget://open:app"))
  }
}

struct RankedWarWidget: Widget {
  let kind: String = "HomeWidgetRankedWar"

  var body: some WidgetConfiguration {
    AppIntentConfiguration(
      kind: kind, intent: PdaWidgetMainIntent.self, provider: RankedWarProvider()
    ) { entry in
      RankedWarWidgetEntryView(entry: entry)
        .containerBackground(.fill.tertiary, for: .widget)
    }
    .configurationDisplayName("Ranked War")
    .description("Displays information about the current ranked war.")
    .supportedFamilies([.systemMedium])
  }
}

@available(iOSApplicationExtension 17.0, *)
private struct _WidgetContainerBackground: ViewModifier {
  func body(content: Content) -> some View {
    content.containerBackground(.fill.tertiary, for: .widget)
  }
}

extension View {
  func widgetContainerBackgroundIfAvailable() -> some View {
    if #available(iOSApplicationExtension 17.0, *) {
      return AnyView(self.modifier(_WidgetContainerBackground()))
    } else {
      return AnyView(self)
    }
  }
}

struct SpinningReloadIcon: View {
  let reloading: Bool

  @State private var isRotating = false

  var body: some View {
    Image(systemName: "arrow.clockwise")
      .rotationEffect(Angle.degrees(isRotating ? 360 : 0))
      .onAppear(perform: updateRotation)
      .onChange(of: reloading) { _ in updateRotation() }
  }

  private func updateRotation() {
    if reloading {
      withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
        isRotating = true
      }
    } else {
      withAnimation(nil) {
        isRotating = false
      }
    }
  }
}
