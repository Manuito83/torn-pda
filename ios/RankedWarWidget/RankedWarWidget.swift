import AppIntents
import SwiftUI
import WidgetKit

struct RankedWarEntry: TimelineEntry {
  let date: Date
  let state: String
  let upcomingCountdown: String
  let upcomingDate: String
  let upcomingSoon: Bool
  let activePlayerScore: Int
  let activeEnemyScore: Int
  let activeTargetScore: Int
  let activePlayerTag: String
  let activeEnemyName: String
  let lastUpdated: String
  let reloading: Bool
  let widgetVisible: Bool
  let darkMode: Bool
  let finishedWinner: String
  let finishedPlayerScore: Int
  let finishedEnemyScore: Int
  let finishedPlayerTag: String
  let finishedEnemyName: String
  let finishedEndDate: String
}

struct RankedWarProvider: AppIntentTimelineProvider {
  func placeholder(in context: Context) -> RankedWarEntry {
    RankedWarEntry(
      date: Date(), state: "active", upcomingCountdown: "Loading...", upcomingDate: "",
      upcomingSoon: false, activePlayerScore: 1234, activeEnemyScore: 567, activeTargetScore: 2500,
      activePlayerTag: "[ME]", activeEnemyName: "The Enemy", lastUpdated: "Just now",
      reloading: false, widgetVisible: true, darkMode: false,
      finishedWinner: "", finishedPlayerScore: 1234, finishedEnemyScore: 567,
      finishedPlayerTag: "[ME]", finishedEnemyName: "The Enemy", finishedEndDate: ""
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
        upcomingSoon: false,
        activePlayerScore: 0,
        activeEnemyScore: 0,
        activeTargetScore: 0,
        activePlayerTag: "N/A",
        activeEnemyName: "",
        lastUpdated: "Now",
        reloading: false,
        widgetVisible: true,
        darkMode: false,
        finishedWinner: "", finishedPlayerScore: 0, finishedEnemyScore: 0,
        finishedPlayerTag: "", finishedEnemyName: "", finishedEndDate: ""
      )
    }

    let state = prefs.string(forKey: "rw_state") ?? "none"
    let upcomingCountdown = prefs.string(forKey: "rw_countdown_string") ?? "Loading..."
    let upcomingDate = prefs.string(forKey: "rw_date_string") ?? ""
    let upcomingSoon = prefs.bool(forKey: "rw_upcoming_soon")
    let activePlayerScore = prefs.integer(forKey: "rw_player_score")
    let activeEnemyScore = prefs.integer(forKey: "rw_enemy_score")
    let activeTargetScore = prefs.integer(forKey: "rw_target_score")
    let activePlayerTag = (prefs.string(forKey: "rw_player_faction_tag") ?? "")
      .decodingHTMLEntities()
    let activeEnemyName = (prefs.string(forKey: "rw_enemy_faction_name") ?? "")
      .decodingHTMLEntities()

    let lastUpdated = prefs.string(forKey: "last_updated") ?? "Updating..."
    let reloading = prefs.bool(forKey: "reloading")
    let widgetVisible = prefs.bool(forKey: "rw_widget_visibility")
    let darkMode = prefs.bool(forKey: "darkMode")

    let finishedWinner = (prefs.string(forKey: "rw_winner") ?? "").decodingHTMLEntities()
    let finishedPlayerScore = prefs.integer(forKey: "rw_player_score")
    let finishedEnemyScore = prefs.integer(forKey: "rw_enemy_score")
    let finishedPlayerTag = (prefs.string(forKey: "rw_player_faction_tag") ?? "")
      .decodingHTMLEntities()
    let finishedEnemyName = (prefs.string(forKey: "rw_enemy_faction_name") ?? "")
      .decodingHTMLEntities()
    let finishedEndDate = prefs.string(forKey: "rw_end_date_string") ?? ""

    return RankedWarEntry(
      date: Date(), state: state, upcomingCountdown: upcomingCountdown, upcomingDate: upcomingDate,
      upcomingSoon: upcomingSoon, activePlayerScore: activePlayerScore,
      activeEnemyScore: activeEnemyScore,
      activeTargetScore: activeTargetScore, activePlayerTag: activePlayerTag,
      activeEnemyName: activeEnemyName, lastUpdated: lastUpdated, reloading: reloading,
      widgetVisible: widgetVisible, darkMode: darkMode,
      finishedWinner: finishedWinner, finishedPlayerScore: finishedPlayerScore,
      finishedEnemyScore: finishedEnemyScore, finishedPlayerTag: finishedPlayerTag,
      finishedEnemyName: finishedEnemyName, finishedEndDate: finishedEndDate
    )
  }
}

struct RankedWarWidgetEntryView: View {
  var entry: RankedWarProvider.Entry

  var body: some View {
    if !entry.widgetVisible {
      NoWarView(
        message: "No ranked war data", lastUpdated: entry.lastUpdated, reloading: entry.reloading
      )
    } else {
      VStack(spacing: 8) {
        HeaderView(lastUpdated: entry.lastUpdated, reloading: entry.reloading)
        switch entry.state {
        case "upcoming":
          UpcomingWarView(
            countdown: entry.upcomingCountdown,
            date: entry.upcomingDate,
            playerTag: entry.activePlayerTag,
            enemyName: entry.activeEnemyName,
            isUpcomingSoon: entry.upcomingSoon
          )
        case "active":
          ActiveWarView(
            playerScore: entry.activePlayerScore, enemyScore: entry.activeEnemyScore,
            targetScore: entry.activeTargetScore, playerTag: entry.activePlayerTag,
            enemyName: entry.activeEnemyName
          )
        case "finished":
          FinishedWarView(
            winner: entry.finishedWinner,
            playerScore: entry.finishedPlayerScore,
            enemyScore: entry.finishedEnemyScore,
            playerTag: entry.finishedPlayerTag,
            enemyName: entry.finishedEnemyName,
            endDate: entry.finishedEndDate
          )
        default:
          Spacer()
          Text("No ranked war data")
            .padding()
          Spacer()
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
        SpinningReloadIcon(trigger: reloading)
          .font(.headline)
      }
      .buttonStyle(.plain)

    }
    .padding(.horizontal)
  }
}

struct UpcomingWarView: View {
  let countdown: String
  let date: String
  let playerTag: String
  let enemyName: String
  let isUpcomingSoon: Bool

  var body: some View {
    VStack(spacing: 8) {
      HStack {
        Image(systemName: "swords")
          .foregroundColor(.orange)
          .font(.title3)
        Text("Upcoming War")
          .font(.headline)
          .fontWeight(.semibold)
        Spacer()
      }

      VStack(spacing: 4) {
        Text(countdown)
          .font(isUpcomingSoon ? .title : .title2)
          .fontWeight(isUpcomingSoon ? .bold : .semibold)
          .foregroundColor(isUpcomingSoon ? .orange : .primary)

        if !date.isEmpty {
          Text(date)
            .font(.caption)
            .foregroundColor(.secondary)
        }
      }

      if !playerTag.isEmpty && !enemyName.isEmpty {
        VStack(spacing: 2) {
          HStack {
            Text(playerTag)
              .font(.caption)
              .fontWeight(.bold)
              .foregroundColor(.blue)
            Text("vs")
              .font(.caption2)
              .foregroundColor(.secondary)
            Text(enemyName.prefix(15))
              .font(.caption)
              .fontWeight(.bold)
              .foregroundColor(.red)
              .lineLimit(1)
          }
        }
      }
    }
    .padding()
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(isUpcomingSoon ? Color.orange : Color.clear, lineWidth: isUpcomingSoon ? 2 : 0)
    )
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

struct FinishedWarView: View {
  let winner: String
  let playerScore: Int
  let enemyScore: Int
  let playerTag: String
  let enemyName: String
  let endDate: String

  var body: some View {
    let playerWon = playerScore >= enemyScore

    VStack(spacing: 8) {
      HStack {
        Image(systemName: "trophy.fill")
          .foregroundColor(playerWon ? .green : .red)
          .font(.headline)

        Text(winner)
          .font(.headline)
          .fontWeight(.bold)
          .foregroundColor(playerWon ? .green : .red)
          .lineLimit(1)

        Spacer()

        if !endDate.isEmpty {
          Text(endDate)
            .font(.caption)
            .foregroundColor(.secondary)
            .lineLimit(1)
        }
      }

      HStack {
        VStack {
          Text(playerTag)
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.blue)
          Text("\(playerScore)")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(playerWon ? .green : .red)
        }
        Spacer()
        VStack {
          Text(enemyName.prefix(15))
            .font(.caption)
            .fontWeight(.bold)
            .foregroundColor(.red)
          Text("\(enemyScore)")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(!playerWon ? .green : .red)
        }
      }
    }
    .padding()
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(playerWon ? Color.green : Color.red, lineWidth: 2)
    )
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
  let trigger: Bool

  @State private var isRotating = false

  var body: some View {
    Image(systemName: "arrow.clockwise")
      .rotationEffect(Angle.degrees(isRotating ? 360 : 0))
      .foregroundColor(isRotating ? .accentColor : .gray)
      .onAppear {
        if trigger { spinOnce() }
      }
      .onChange(of: trigger) { newValue in
        if newValue {
          spinOnce()
        } else {
          withAnimation(nil) {
            isRotating = false
          }
        }
      }
  }

  private func spinOnce() {
    guard !isRotating else { return }

    withAnimation(.linear(duration: 0.7)) {
      isRotating = true
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
      withAnimation(.easeOut(duration: 0.1)) {
        isRotating = false
      }
    }
  }
}

extension String {
  func decodingHTMLEntities() -> String {
    guard let data = self.data(using: .utf8) else {
      return self
    }

    let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
      .documentType: NSAttributedString.DocumentType.html,
      .characterEncoding: String.Encoding.utf8.rawValue,
    ]

    guard
      let attributedString = try? NSAttributedString(
        data: data, options: options, documentAttributes: nil)
    else {
      return self
    }

    return attributedString.string
  }
}
