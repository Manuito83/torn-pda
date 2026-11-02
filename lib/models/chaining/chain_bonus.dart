const List<int> chainBonuses = [10, 25, 50, 100, 250, 500, 1000, 2500, 5000, 10000, 25000, 50000, 100000];

/// Largest bonus the hits reached
int? chainBonusReached(int hits) => chainBonuses.where((b) => b <= hits).lastOrNull;

/// Next bonus above the hits
int nextChainBonus(int hits) => chainBonuses.firstWhere((b) => b > hits, orElse: () => hits);
