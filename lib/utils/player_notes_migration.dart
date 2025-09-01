// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:get/get.dart';

// Project imports:
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/models/faction/faction_model.dart';
import 'package:torn_pda/models/friends/friend_model.dart';
import 'package:torn_pda/models/stakeouts/stakeout_model.dart';
import 'package:torn_pda/providers/player_notes_controller.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class PlayerNotesMigrationService {
  /// Migrate all existing notes from different providers to the centralized notes system
  static Future<void> migrateNotesIfNeeded([BuildContext? context]) async {
    final migrationCompleted = await Prefs().getMigrationCompleted();
    if (migrationCompleted) {
      return;
    }

    try {
      final playerNotesController = Get.find<PlayerNotesController>();
      int migratedCount = 0;

      final List<String> targetsJson = await Prefs().getTargetsList();
      for (final targetJsonString in targetsJson) {
        try {
          final target = targetModelFromJson(targetJsonString);
          if (target.personalNote != null && target.personalNote!.isNotEmpty) {
            await playerNotesController.setPlayerNote(
              target.playerId.toString(),
              target.personalNote!,
              target.personalNoteColor,
              target.name,
            );
            migratedCount++;
          }
        } catch (e) {
          debugPrint('Error parsing target JSON: $e');
          continue;
        }
      }

      final List<String> friendsJson = await Prefs().getFriendsList();
      for (final friendJsonString in friendsJson) {
        try {
          final friend = friendModelFromJson(friendJsonString);
          if (friend.personalNote != null && friend.personalNote!.isNotEmpty) {
            final existingNote = playerNotesController.getNoteForPlayer(friend.playerId.toString());
            if (existingNote == null) {
              await playerNotesController.setPlayerNote(
                friend.playerId.toString(),
                friend.personalNote!,
                friend.personalNoteColor,
                friend.name,
              );
              migratedCount++;
            }
          }
        } catch (e) {
          debugPrint('Error parsing friend JSON: $e');
          continue;
        }
      }

      final List<String> stakeoutsJson = await Prefs().getStakeouts();
      for (final stakeoutJsonString in stakeoutsJson) {
        try {
          final stakeout = stakeoutFromJson(stakeoutJsonString);
          if (stakeout.id != null && stakeout.personalNote.isNotEmpty) {
            final existingNote = playerNotesController.getNoteForPlayer(stakeout.id!);
            if (existingNote == null) {
              await playerNotesController.setPlayerNote(
                stakeout.id!,
                stakeout.personalNote,
                stakeout.personalNoteColor,
                stakeout.name,
              );
              migratedCount++;
            }
          }
        } catch (e) {
          debugPrint('Error parsing stakeout JSON: $e');
          continue;
        }
      }

      final List<String> warFactionsJson = await Prefs().getWarFactions();
      for (final factionJsonString in warFactionsJson) {
        try {
          final faction = factionModelFromJson(factionJsonString);
          if (faction.members != null) {
            for (final member in faction.members!.values) {
              if (member != null &&
                  member.personalNote != null &&
                  member.personalNote!.isNotEmpty &&
                  member.memberId != null) {
                final existingNote = playerNotesController.getNoteForPlayer(member.memberId.toString());
                if (existingNote == null) {
                  await playerNotesController.setPlayerNote(
                    member.memberId.toString(),
                    member.personalNote!,
                    member.personalNoteColor,
                    member.name,
                  );
                  migratedCount++;
                }
              }
            }
          }
        } catch (e) {
          debugPrint('Error parsing faction JSON: $e');
          continue;
        }
      }

      await Prefs().setMigrationCompleted(true);

      debugPrint('Player notes migration completed. Migrated $migratedCount notes.');
    } catch (e) {
      debugPrint('Error during player notes migration: $e');
    }
  }
}
