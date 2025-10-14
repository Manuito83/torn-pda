import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'other_profile_pda.dart';

class OtherProfileAdapter {
  /// Detects API version and converts to OtherProfilePDA
  static OtherProfilePDA fromJson(Map<String, dynamic> json) {
    final isV2 = json.containsKey('profile') && json['profile'] != null;

    if (kDebugMode) {
      log('🔍 [OtherProfileAdapter] API Version: ${isV2 ? "V2" : "V1"}');
    }

    return isV2 ? _fromV2(json) : _fromV1(json);
  }

  // ========== V1 MAPPING ==========

  static OtherProfilePDA _fromV1(Map<String, dynamic> json) {
    OtherProfilePDA v1 = OtherProfilePDA(
      // Basic
      id: _parsePositiveInt(json['player_id']) ?? 0,
      name: _parseString(json['name']),
      level: _parsePositiveInt(json['level']) ?? 1,
      rank: _parseString(json['rank']),
      gender: _parseString(json['gender']),
      age: _parsePositiveInt(json['age']) ?? 0,
      role: _parseString(json['role']),
      awards: _parsePositiveInt(json['awards']) ?? 0,
      friends: _parsePositiveInt(json['friends']) ?? 0,
      enemies: _parsePositiveInt(json['enemies']) ?? 0,
      forumPosts: _parsePositiveInt(json['forum_posts']) ?? 0,
      karma: _parsePositiveInt(json['karma']) ?? 0,
      propertyName: _parseString(json['property']),
      propertyId: _parsePositiveInt(json['property_id']),
      revivable: json['revivable'] == 1,
      profileImage: json['profile_image'],
      donatorStatus: json['donator'] != null && json['donator'] > 0 ? 'Donator' : null,

      // Faction (in V1: faction_id, faction_name, faction_tag, position, days_in_faction)
      factionId: _parsePositiveInt(json['faction']?['id']),
      factionName: json['faction']?['name'],
      factionPosition: json['faction']?['position'],
      factionTag: json['faction']?['tag'],
      daysInFaction: _parsePositiveInt(json['faction']?['days_in_faction']),

      // Job
      jobId: _parsePositiveInt(json['job']?['id']),
      jobName: json['job']?['name'],
      jobPosition: json['job']?['position'],

      // Life
      lifeCurrent: _parsePositiveInt(json['life']?['current']),
      lifeMaximum: _parsePositiveInt(json['life']?['maximum']),

      // Status
      statusDescription: json['status']?['description'],
      statusDetails: json['status']?['details'],
      statusState: json['status']?['state'],
      statusColor: json['status']?['color'],
      statusUntil: _parsePositiveInt(json['status']?['until']),

      // Spouse
      spouseId: _parsePositiveInt(json['married']?['spouse_id']),
      spouseName: json['married']?['spouse_name'],
      daysMarried: _parsePositiveInt(json['married']?['duration']),

      // Last Action
      lastActionStatus: json['last_action']?['status'],
      lastActionTimestamp: _parsePositiveInt(json['last_action']?['timestamp']),
      lastActionRelative: json['last_action']?['relative'],

      // Bounty (basicicons)
      hasBounty: json['basicicons']?['icon13'] != null,
      bountyDescription: json['basicicons']?['icon13'],

      // Complex - convert to typed classes
      personalstats: json['personalstats'] != null ? PersonalStats.fromJson(json['personalstats']) : null,
      bazaar:
          json['bazaar'] != null ? (json['bazaar'] as List).map((item) => BazaarItem.fromJson(item)).toList() : null,
    );

    return v1;
  }

  // ========== V2 MAPPING ==========

  static OtherProfilePDA _fromV2(Map<String, dynamic> json) {
    // In V2, data is inside 'profile'
    final profile = json['profile'] as Map<String, dynamic>;

    // Faction comes as separate object
    final dynamic factionData = json['faction'];
    final Map<String, dynamic>? faction = (factionData is Map<String, dynamic>) ? factionData : null;

    // Job comes as separate object
    final dynamic jobData = json['job'];
    final Map<String, dynamic>? job = (jobData is Map<String, dynamic>) ? jobData : null;

    // Spouse comes as separate object (V1 was "married")
    final dynamic spouse = json['profile']?['spouse'];

    // Icons come as array
    final List<dynamic>? icons = json['icons'] as List<dynamic>?;

    // Property in V2 is a Map with 'name' and 'property_id'
    final dynamic propertyData = profile['property'];

    // Find bounty icon (id: 13)
    String? bountyDesc;
    if (icons != null) {
      for (final icon in icons) {
        if (icon is Map<String, dynamic> && icon['id'] == 13) {
          bountyDesc = icon['description'];
          break;
        }
      }
    }

    // V2 splits rank into 'rank' + 'title', concatenate them
    final String rankV2 = profile['rank'] != null && profile['title'] != null
        ? '${profile['rank']} ${profile['title']}'
        : (profile['rank'] ?? '');

    OtherProfilePDA v2 = OtherProfilePDA(
      // Basic (inside profile)
      id: _parsePositiveInt(profile['id']) ?? 0,
      name: _parseString(profile['name']),
      level: _parsePositiveInt(profile['level']) ?? 1,
      rank: rankV2,
      gender: _parseString(profile['gender']),
      age: _parsePositiveInt(profile['age']) ?? 0,
      role: _parseString(profile['role']),
      awards: _parsePositiveInt(profile['awards']) ?? 0,
      friends: _parsePositiveInt(profile['friends']) ?? 0,
      enemies: _parsePositiveInt(profile['enemies']) ?? 0,
      forumPosts: _parsePositiveInt(profile['forum_posts']) ?? 0,
      karma: _parsePositiveInt(profile['karma']) ?? 0,
      propertyName: _parseString(propertyData['name']),
      propertyId: _parsePositiveInt(propertyData['id']),
      revivable: profile['revivable'] == 1 || profile['revivable'] == true,
      profileImage: profile['image'],
      donatorStatus: profile['donator_status'],

      // Faction (separate object in V2: id, name, tag, position, days_in_faction)
      factionId: _parsePositiveInt(faction?['id']),
      factionName: faction?['name'],
      factionPosition: faction?['position'],
      factionTag: faction?['tag'],
      daysInFaction: _parsePositiveInt(faction?['days_in_faction']),

      // Job (separate object in V2: id, name, position)
      jobId: _parsePositiveInt(job?['id']),
      jobName: job?['name'],
      jobPosition: job?['position'],

      // Life (inside profile)
      lifeCurrent: _parsePositiveInt(profile['life']?['current']),
      lifeMaximum: _parsePositiveInt(profile['life']?['maximum']),

      // Status (inside profile)
      statusDescription: _parseString(profile['status']?['description']),
      statusDetails: _parseString(profile['status']?['details']),
      statusState: _parseString(profile['status']?['state']),
      statusColor: _parseString(profile['status']?['color']),
      statusUntil: _parsePositiveInt(profile['status']?['until']),

      // Spouse (in V2: id, name, days_married - different from V1: spouse_id, spouse_name, duration)
      spouseId: _parsePositiveInt(spouse?['id']),
      spouseName: _parseString(spouse?['name']),
      daysMarried: _parsePositiveInt(spouse?['days_married']),

      // Last Action (inside profile)
      lastActionStatus: _parseString(profile['last_action']?['status']),
      lastActionTimestamp: _parsePositiveInt(profile['last_action']?['timestamp']),
      lastActionRelative: profile['last_action']?['relative'],

      // Bounty (icons array)
      hasBounty: bountyDesc != null,
      bountyDescription: bountyDesc,

      // Complex - convert to typed classes (same structure in V1 and V2)
      personalstats: json['personalstats'] != null ? PersonalStats.fromJson(json['personalstats']) : null,
      bazaar:
          json['bazaar'] != null ? (json['bazaar'] as List).map((item) => BazaarItem.fromJson(item)).toList() : null,
    );

    return v2;
  }

  // ========== PARSING HELPERS ==========

  /// Parses a positive integer, returns null if 0 or negative
  static int? _parsePositiveInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value > 0 ? value : null;
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed != null && parsed > 0 ? parsed : null;
    }
    return null;
  }

  /// Parses a string, returns empty string if null
  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }
}
