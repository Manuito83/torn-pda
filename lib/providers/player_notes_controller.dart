// Flutter imports:
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Project imports:
import 'package:torn_pda/utils/player_notes_migration.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class PlayerNote {
  final String playerId;
  String note;
  String? color;
  String? playerName;
  DateTime? createdAt;
  DateTime? updatedAt;

  PlayerNote({
    required this.playerId,
    required this.note,
    this.color,
    this.playerName,
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'note': note,
      'color': color,
      'playerName': playerName,
      'createdAt': createdAt?.millisecondsSinceEpoch,
      'updatedAt': updatedAt?.millisecondsSinceEpoch,
    };
  }

  factory PlayerNote.fromJson(Map<String, dynamic> json) {
    return PlayerNote(
      playerId: json['playerId'] as String,
      note: json['note'] as String,
      color: json['color'] as String?,
      playerName: json['playerName'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int) : null,
    );
  }

  /// True when the note has a color selected but no text content
  bool get hasColorOnly => note.isEmpty && !PlayerNoteColor.isNone(color);

  /// Text to display inline (blank if it's a pure color-only note)
  String get effectiveDisplayText => hasColorOnly ? '' : note;

  /// Fallback name for display purposes when playerName is null/empty
  String get displayNameFallback =>
      (playerName == null || playerName!.trim().isEmpty) ? 'Player $playerId' : playerName!;
}

/// Centralized color sentinel definitions for player notes
/// 'z' represents "no color" (legacy)
class PlayerNoteColor {
  static const String none = 'z';
  static const String red = 'red';
  static const String orange = 'orange';
  static const String green = 'green';

  static const List<String> all = [none, red, orange, green];

  static bool isNone(String? v) => v == none || v == null; // treat null
  static bool isValid(String? v) => v != null && all.contains(v);

  /// Map stored color code to a base [Color]
  static Color toColor(String? code) {
    switch (code) {
      case red:
        return Colors.red;
      case orange:
        return Colors.orange;
      case green:
        return Colors.green;
      case none:
      default:
        return Colors.transparent;
    }
  }

  /// Map stored color code to a color safe for text on dark backgrounds
  /// If none, returns [fallback] (themeProvider's mainText)
  static Color toTextColor({required String? code, required Color fallback}) {
    if (isNone(code)) return fallback;
    final base = toColor(code);
    return base;
  }
}

class PlayerNotesController extends GetxController {
  Map<String, PlayerNote> _notes = {};

  Map<String, PlayerNote> get notes => _notes;

  @override
  Future<void> onInit() async {
    super.onInit();
    await _loadNotes();
  }

  // TODO: remove after migration
  Future<void> initializeMigration() async {
    try {
      await PlayerNotesMigrationService.migrateNotesIfNeeded();
    } catch (e) {
      debugPrint('Could not perform notes migration: $e');
    }
  }

  /// Get note for a specific player
  PlayerNote? getNoteForPlayer(String playerId) {
    return _notes[playerId];
  }

  Future<void> setPlayerNote({
    required String playerId,
    required String note,
    String? color,
    String? playerName,
  }) async {
    final existingNote = _notes[playerId];
    // Null => clear color; sentinel or null collapse to none
    final String finalColor = (color == null || PlayerNoteColor.isNone(color)) ? PlayerNoteColor.none : color;

    // Removal check: both empty text AND no color after resolution
    if (note.isEmpty && PlayerNoteColor.isNone(finalColor)) {
      if (existingNote != null) {
        await removePlayerNote(playerId);
      }
      return;
    }

    final now = DateTime.now();
    final effectivePlayerName =
        (playerName != null && playerName.trim().isNotEmpty) ? playerName.trim() : existingNote?.playerName;

    _notes[playerId] = PlayerNote(
      playerId: playerId,
      note: note,
      color: finalColor,
      playerName: effectivePlayerName,
      createdAt: existingNote?.createdAt ?? now,
      updatedAt: now,
    );

    await _saveNotes();
    update();
  }

  Future<void> removePlayerNote(String playerId) async {
    _notes.remove(playerId);
    await _saveNotes();
    update();
  }

  List<PlayerNote> getAllNotes() {
    return _notes.values.toList();
  }

  Future<void> clearAllNotes() async {
    _notes.clear();
    await _saveNotes();
    update();
  }

  Future<void> _saveNotes() async {
    final notesJson = _notes.values.map((note) => note.toJson()).toList();
    await Prefs().setPlayerNotes(notesJson);
  }

  Future<void> _loadNotes() async {
    final notesJson = await Prefs().getPlayerNotes();
    _notes = {};
    bool needsResave = false;

    for (final noteJson in notesJson) {
      final note = PlayerNote.fromJson(noteJson);

      // Migration: null color to sentinel 'z'
      String? migratedColor = note.color;
      if (migratedColor == null) {
        migratedColor = PlayerNoteColor.none;
        needsResave = true;
      }

      if (note.createdAt == null || note.updatedAt == null) {
        final now = DateTime.now();
        final migratedNote = PlayerNote(
          playerId: note.playerId,
          note: note.note,
          color: migratedColor,
          playerName: note.playerName,
          createdAt: note.createdAt ?? now,
          updatedAt: note.updatedAt ?? now,
        );
        _notes[note.playerId] = migratedNote;
        needsResave = true;
      } else {
        if (note.color != migratedColor) {
          _notes[note.playerId] = PlayerNote(
            playerId: note.playerId,
            note: note.note,
            color: migratedColor,
            playerName: note.playerName,
            createdAt: note.createdAt,
            updatedAt: note.updatedAt,
          );
          needsResave = true;
        } else {
          _notes[note.playerId] = note;
        }
      }
    }

    if (needsResave) {
      await _saveNotes();
    }

    update();
  }

  Color getDisplayColor(String? colorString) {
    return PlayerNoteColor.toColor(colorString);
  }
}
