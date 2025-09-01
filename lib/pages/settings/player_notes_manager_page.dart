// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:get/get.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/providers/friends_provider.dart';
import 'package:torn_pda/providers/player_notes_controller.dart';
import 'package:torn_pda/providers/stakeouts_controller.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/war_controller.dart';
import 'package:torn_pda/widgets/player_notes_dialog.dart';

class PlayerNotesManagerPage extends StatefulWidget {
  const PlayerNotesManagerPage({super.key});

  @override
  State<PlayerNotesManagerPage> createState() => _PlayerNotesManagerPageState();
}

class _PlayerNotesManagerPageState extends State<PlayerNotesManagerPage> {
  late ThemeProvider _themeProvider;
  late PlayerNotesController _playerNotesController;
  late TargetsProvider _targetsProvider;
  late FriendsProvider _friendsProvider;
  late StakeoutsController _stakeoutsController;
  late WarController _warController;

  @override
  void initState() {
    super.initState();
    _targetsProvider = Provider.of<TargetsProvider>(context, listen: false);
    _friendsProvider = Provider.of<FriendsProvider>(context, listen: false);
    _stakeoutsController = Get.find<StakeoutsController>();
    _warController = Get.find<WarController>();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    _playerNotesController = Get.find<PlayerNotesController>();

    final allNotes = _playerNotesController.getAllNotes();
    allNotes.sort((a, b) => a.playerId.compareTo(b.playerId));

    return Scaffold(
      backgroundColor: _themeProvider.canvas,
      appBar: AppBar(
        backgroundColor: _themeProvider.statusBar,
        elevation: 0,
        title: const Text(
          'Player Notes Manager',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: allNotes.isEmpty
          ? Center(
              child: Text(
                'No player notes found',
                style: TextStyle(
                  fontSize: 16,
                  color: _themeProvider.mainText,
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: allNotes.length,
              itemBuilder: (context, index) {
                final note = allNotes[index];
                return _buildNoteCard(note);
              },
            ),
    );
  }

  Widget _buildNoteCard(PlayerNote note) {
    final noteColor = _playerNotesController.getDisplayColor(note.color);

    final List<String> playerTypes = [];

    if (_targetsProvider.isPlayerInTargets(note.playerId)) {
      playerTypes.add('Target');
    }

    if (_friendsProvider.isPlayerInFriends(note.playerId)) {
      playerTypes.add('Friend');
    }

    if (_stakeoutsController.isPlayerInStakeouts(note.playerId)) {
      playerTypes.add('Stakeout');
    }

    if (_warController.isPlayerInWarFactions(note.playerId)) {
      playerTypes.add('War Member');
    }

    return Card(
      color: _themeProvider.secondBackground,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: noteColor == Colors.transparent ? _themeProvider.mainText.withValues(alpha: 0.3) : noteColor,
          child: Text(
            note.playerId.length > 2 ? note.playerId.substring(note.playerId.length - 2) : note.playerId,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          note.playerName != null ? "${note.playerName} [${note.playerId}]" : "Player [${note.playerId}]",
          style: TextStyle(
            color: _themeProvider.mainText,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (playerTypes.isNotEmpty)
              Text(
                'Types: ${playerTypes.join(', ')}',
                style: TextStyle(
                  color: _themeProvider.mainText.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              note.note,
              style: TextStyle(
                color: _themeProvider.mainText,
                fontSize: 14,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                Icons.sticky_note_2,
                color: _themeProvider.mainText,
                size: 20,
              ),
              onPressed: () => _editNote(note),
            ),
            IconButton(
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
                size: 20,
              ),
              onPressed: () => _deleteNote(note),
            ),
          ],
        ),
        onTap: () => _editNote(note),
      ),
    );
  }

  void _editNote(PlayerNote note) async {
    final playerName = note.playerName ?? "Player [${note.playerId}]";
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          content: SingleChildScrollView(
            child: PlayerNotesDialog(
              playerId: note.playerId,
              playerName: playerName,
            ),
          ),
        );
      },
    );
  }

  void _deleteNote(PlayerNote note) {
    final displayText = note.playerName != null ? "${note.playerName} [${note.playerId}]" : "Player [${note.playerId}]";

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: _themeProvider.secondBackground,
          title: Text(
            'Delete Note',
            style: TextStyle(color: _themeProvider.mainText),
          ),
          content: Text(
            'Are you sure you want to delete the note for $displayText?',
            style: TextStyle(color: _themeProvider.mainText),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                await _playerNotesController.removePlayerNote(note.playerId);
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
}
