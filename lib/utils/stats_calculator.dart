class StatsCalculator {
  static final statsLevelTriggers = [2, 6, 11, 26, 31, 50, 71, 100];
  static final statsCrimesTriggers = [100, 5000, 10000, 20000, 30000, 50000];
  static final statsNetworthTriggers = [5000000, 50000000, 500000000, 5000000000, 50000000000];

  static final statsRanksTriggers = {
    "Absolute beginner": 1,
    "Beginner": 2,
    "Inexperienced": 3,
    "Rookie": 4,
    "Novice": 5,
    "Below average": 6,
    "Average": 7,
    "Reasonable": 8,
    "Above average": 9,
    "Competent": 10,
    "Highly competent": 11,
    "Veteran": 12,
    "Distinguished": 13,
    "Highly distinguished": 14,
    "Professional": 15,
    "Star": 16,
    "Master": 17,
    "Outstanding": 18,
    "Celebrity": 19,
    "Supreme": 20,
    "Idolized": 21,
    "Champion": 22,
    "Heroic": 23,
    "Legendary": 24,
    "Elite": 25,
    "Invincible": 26,
  };

  static final statsResults = [
    "< 2k",
    "2k - 25k",
    "20k - 250k",
    "200k - 2.5M",
    "2M - 25M",
    "20M - 250M",
    "> 200M",
  ];

  static String calculateStats({
    required int? level,
    required int? criminalRecordTotal,
    required int? networth,
    required String? rank,
  }) {
    var levelIndex = statsLevelTriggers.lastIndexWhere((x) => x <= level!) + 1;
    var crimeIndex = statsCrimesTriggers.lastIndexWhere((x) => x <= criminalRecordTotal!) + 1;
    var networthIndex = statsNetworthTriggers.lastIndexWhere((x) => x <= networth!) + 1;
    var rankIndex = 0;
    statsRanksTriggers.forEach((tornRank, index) {
      if (rank!.contains(tornRank)) {
        rankIndex = index;
      }
    });

    var finalIndex = rankIndex - levelIndex - crimeIndex - networthIndex - 1;
    if (finalIndex >= 0 && finalIndex <= 6) {
      return statsResults[finalIndex];
    }
    return "unk";
  }
}
