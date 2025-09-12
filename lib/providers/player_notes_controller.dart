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

  /// Set or update note for a player
  Future<void> setPlayerNote(String playerId, String note, [String? color, String? playerName]) async {
    if (note.isEmpty) {
      await removePlayerNote(playerId);
      return;
    }

    final now = DateTime.now();
    final existingNote = _notes[playerId];

    _notes[playerId] = PlayerNote(
      playerId: playerId,
      note: note,
      color: color ?? 'z',
      playerName: playerName,
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

      if (note.createdAt == null || note.updatedAt == null) {
        final now = DateTime.now();
        final migratedNote = PlayerNote(
          playerId: note.playerId,
          note: note.note,
          color: note.color,
          playerName: note.playerName,
          createdAt: note.createdAt ?? now,
          updatedAt: note.updatedAt ?? now,
        );
        _notes[note.playerId] = migratedNote;
        needsResave = true;
      } else {
        _notes[note.playerId] = note;
      }
    }

    if (needsResave) {
      await _saveNotes();
    }

    update();
  }

  Color getDisplayColor(String? colorString) {
    switch (colorString) {
      case 'red':
        return Colors.red;
      case 'orange':
        return Colors.orange;
      case 'green':
        return Colors.green;
      default:
        return Colors.transparent;
    }
  }
}
