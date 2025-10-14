import 'other_profile_adapter.dart';
// ignore: unused_import
import 'dart:convert';

/// Global model player profiles in Torn PDA
/// Independent of Torn API version
class OtherProfilePDA {
  // ========== BASIC INFO ==========
  final int? id;
  final String? name;
  final int? level;
  final String? rank;
  final String? gender;
  final int? age;
  final String? role;
  final int? awards;
  final int? friends;
  final int? enemies;
  final int? forumPosts;
  final int? karma;
  final String? propertyName;
  final int? propertyId;
  final bool? revivable;
  final String? profileImage;
  final String? donatorStatus;

  // ========== FACTION ==========
  final int? factionId;
  final String? factionName;
  final String? factionPosition;
  final String? factionTag;
  final int? daysInFaction;

  // ========== JOB ==========
  final int? jobId;
  final String? jobName;
  final String? jobPosition;

  // ========== LIFE ==========
  final int? lifeCurrent;
  final int? lifeMaximum;

  // ========== STATUS ==========
  final String? statusDescription;
  final String? statusDetails;
  final String? statusState;
  final String? statusColor;
  final int? statusUntil;

  // ========== SPOUSE ==========
  final int? spouseId;
  final String? spouseName;
  final int? daysMarried;

  // ========== LAST ACTION ==========
  final String? lastActionStatus;
  final int? lastActionTimestamp;
  final String? lastActionRelative;

  // ========== BOUNTY ==========
  final bool hasBounty;
  final String? bountyDescription;

  // ========== COMPLEX DATA ==========
  final PersonalStats? personalstats;
  final List<BazaarItem>? bazaar;

  const OtherProfilePDA({
    this.id,
    this.name,
    this.level,
    this.rank,
    this.gender,
    this.age,
    this.role,
    this.awards,
    this.friends,
    this.enemies,
    this.forumPosts,
    this.karma,
    this.revivable,
    this.propertyName,
    this.propertyId,
    this.profileImage,
    this.donatorStatus,
    this.factionId,
    this.factionName,
    this.factionPosition,
    this.factionTag,
    this.daysInFaction,
    this.jobId,
    this.jobName,
    this.jobPosition,
    this.lifeCurrent,
    this.lifeMaximum,
    this.statusDescription,
    this.statusDetails,
    this.statusState,
    this.statusColor,
    this.statusUntil,
    this.spouseId,
    this.spouseName,
    this.daysMarried,
    this.lastActionStatus,
    this.lastActionTimestamp,
    this.lastActionRelative,
    this.hasBounty = false,
    this.bountyDescription,
    this.personalstats,
    this.bazaar,
  });

  /// Factory that delegates to adapter to handle V1 and V2
  factory OtherProfilePDA.fromJson(Map<String, dynamic> json) {
    return OtherProfileAdapter.fromJson(json);
  }

  // ========== HELPERS ==========

  /// True if the player is in a faction
  bool get isInFaction => factionId != null && factionId! > 0;

  /// True if the player has a job
  bool get hasJob => jobId != null && jobId! > 0;

  /// True if the player is married
  bool get isMarried => spouseId != null && spouseId! > 0;

  /// Checks if the player is in my faction
  bool isInMyFaction(int? myFactionId) {
    if (myFactionId == null) return false;
    return isInFaction && factionId == myFactionId;
  }

  /// Checks if the player is my spouse
  bool isMySpouse(int? myPlayerId) {
    if (myPlayerId == null) return false;
    return isMarried && spouseId == myPlayerId;
  }

  /// True if the player is offline
  bool get isOffline => lastActionStatus?.toLowerCase() == 'offline';

  /// True if the player is idle
  bool get isIdle => lastActionStatus?.toLowerCase() == 'idle';

  /// Life percentage (0.0 - 1.0)
  double get lifePercentage {
    if (lifeCurrent == null || lifeMaximum == null || lifeMaximum == 0) {
      return 0.0;
    }
    return lifeCurrent! / lifeMaximum!;
  }

  /// Player's total networth
  int? get networth => personalstats?.networth;
}

// ========== PERSONAL STATS SUBSET ==========
/// Contains only the personal stats fields used by Torn PDA
/// Adapter extracts these from the full API response (both V1 and V2)
class PersonalStats {
  // Drugs
  final int? xanax;
  final int? ecstasy;
  final int? lsd;

  // Items
  final int? statEnhancers;
  final int? energyDrinks;

  // Other
  final int? energyRefills;

  // Networth
  final int? networth;

  // Crimes
  final int? criminalRecordTotal;

  PersonalStats({
    this.xanax,
    this.ecstasy,
    this.lsd,
    this.statEnhancers,
    this.energyDrinks,
    this.energyRefills,
    this.networth,
    this.criminalRecordTotal,
  });

  /// Extract from API response (works for both V1 and V2)
  factory PersonalStats.fromJson(Map<String, dynamic> json) {
    return PersonalStats(
      xanax: json['drugs']?['xanax'] ?? 0,
      ecstasy: json['drugs']?['ecstasy'] ?? 0,
      lsd: json['drugs']?['lsd'] ?? 0,
      statEnhancers: json['items']?['used']?['stat_enhancers'] ?? 0,
      energyDrinks: json['items']?['used']?['energy_drinks'] ?? 0,
      energyRefills: json['other']?['refills']?['energy'] ?? 0,
      networth: json['networth']?['total'] ?? 0,
      criminalRecordTotal: json['crimes']?['offenses']?['total'] ?? 0,
    );
  }
}

// ========== BAZAAR ITEM ==========
class BazaarItem {
  final int? id;
  final String? name;
  final String? type;
  final int? quantity;
  final int? price;
  final int? marketPrice;
  final int? uid;

  BazaarItem({
    this.id,
    this.name,
    this.type,
    this.quantity,
    this.price,
    this.marketPrice,
    this.uid,
  });

  /// Extract from API response (same structure in V1 and V2)
  factory BazaarItem.fromJson(Map<String, dynamic> json) {
    return BazaarItem(
      id: json['ID'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      quantity: json['quantity'] ?? 0,
      price: json['price'] ?? 0,
      marketPrice: json['market_price'] ?? 0,
      uid: json['UID'],
    );
  }

  /// Total value of this item stack
  int get totalValue => (marketPrice ?? 0) * (quantity ?? 0);
}
