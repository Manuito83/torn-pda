// Package imports:
import 'package:flutter/material.dart';
import 'package:flutter_font_icons/flutter_font_icons.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

enum DrawerSection {
  profile,
  travel,
  chaining,
  loot,
  friends,
  stakeouts,
  awards,
  items,
  rankedWars,
  stockMarket,
  wiki,
  alerts,
  divider1,
  settings,
  about,
  tips,
  divider2;

  bool get isDivider {
    return this == DrawerSection.divider1 || this == DrawerSection.divider2;
  }

  String get title {
    switch (this) {
      case DrawerSection.profile:
        return 'Profile';
      case DrawerSection.travel:
        return 'Travel';
      case DrawerSection.chaining:
        return 'Chaining';
      case DrawerSection.loot:
        return 'Loot';
      case DrawerSection.friends:
        return 'Friends';
      case DrawerSection.stakeouts:
        return 'Stakeouts';
      case DrawerSection.awards:
        return 'Awards';
      case DrawerSection.items:
        return 'Items';
      case DrawerSection.rankedWars:
        return 'Ranked Wars';
      case DrawerSection.stockMarket:
        return 'Stock Market';
      case DrawerSection.wiki:
        return 'Wiki';
      case DrawerSection.alerts:
        return 'Alerts';
      case DrawerSection.settings:
        return 'Settings';
      case DrawerSection.about:
        return 'About';
      case DrawerSection.tips:
        return 'Tips';
      case DrawerSection.divider1:
      case DrawerSection.divider2:
        return 'Divider';
    }
  }

  IconData get icon {
    switch (this) {
      case DrawerSection.profile:
        return Icons.person;
      case DrawerSection.travel:
        return Icons.local_airport;
      case DrawerSection.chaining:
        return MdiIcons.linkVariant;
      case DrawerSection.loot:
        return MdiIcons.knifeMilitary;
      case DrawerSection.friends:
        return Icons.people;
      case DrawerSection.stakeouts:
        return MdiIcons.cctv;
      case DrawerSection.awards:
        return MdiIcons.trophy;
      case DrawerSection.items:
        return MdiIcons.packageVariantClosed;
      case DrawerSection.rankedWars:
        return MaterialCommunityIcons.sword_cross;
      case DrawerSection.stockMarket:
        return MdiIcons.bankTransfer;
      case DrawerSection.wiki:
        return Icons.menu_book;
      case DrawerSection.alerts:
        return Icons.notifications_active;
      case DrawerSection.settings:
        return Icons.settings;
      case DrawerSection.about:
        return Icons.info_outline;
      case DrawerSection.tips:
        return Icons.question_answer_outlined;
      case DrawerSection.divider1:
      case DrawerSection.divider2:
        return Icons.horizontal_rule;
    }
  }

  bool get canHide {
    switch (this) {
      case DrawerSection.settings:
      case DrawerSection.about:
        return false;
      default:
        return true;
    }
  }

  bool get isFixed {
    switch (this) {
      case DrawerSection.settings:
      case DrawerSection.about:
        return true;
      default:
        return false;
    }
  }

  static DrawerSection? fromId(String id) {
    try {
      return DrawerSection.values.byName(id);
    } catch (_) {
      return null;
    }
  }

  static DrawerSection fromIndex(int index) {
    // Legacy numeric defaultSection mapping (0-14)
    // divider1 and divider2 shifted the enum indices, so old numeric values
    // must be mapped to their original sections
    const legacyToNew = [
      DrawerSection.profile, // 0
      DrawerSection.travel, // 1
      DrawerSection.chaining, // 2
      DrawerSection.loot, // 3
      DrawerSection.friends, // 4
      DrawerSection.stakeouts, // 5
      DrawerSection.awards, // 6
      DrawerSection.items, // 7
      DrawerSection.rankedWars, // 8
      DrawerSection.stockMarket, // 9
      DrawerSection.wiki, // 10
      DrawerSection.alerts, // 11
      DrawerSection.settings, // 12
      DrawerSection.about, // 13
      DrawerSection.tips, // 14
    ];
    if (index < 0 || index >= legacyToNew.length) {
      return DrawerSection.profile;
    }
    return legacyToNew[index];
  }
}
