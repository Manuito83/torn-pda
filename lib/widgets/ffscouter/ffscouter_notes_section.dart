import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_notes_model.dart';
import 'package:torn_pda/providers/ffscouter_notes_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/ffscouter_note_text.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/user_helper.dart';
import 'package:torn_pda/widgets/stats/ffscouter_info.dart';

bool ffScouterNotesVisible(BuildContext context) {
  final settings = context.read<SettingsProvider>();
  final notes = Get.find<FFScouterNotesController>();
  return settings.ffScouterEnabledStatusRemoteConfig &&
      settings.ffScouterEnabledStatus == 1 &&
      notes.enabled &&
      notes.remoteConfigEnabled;
}

String ffScouterNoteAge(int createdAt) {
  final seconds = DateTime.now().millisecondsSinceEpoch ~/ 1000 - createdAt;
  if (seconds < 60) return "now";
  if (seconds < 3600) return "${seconds ~/ 60}m ago";
  if (seconds < 86400) return "${seconds ~/ 3600}h ago";
  final date = DateTime.fromMillisecondsSinceEpoch(createdAt * 1000);
  final format = date.year == DateTime.now().year ? 'd MMM' : 'd MMM yyyy';
  return "${seconds ~/ 86400}d ago, ${DateFormat(format).format(date)}";
}

String ffScouterNoteWithAuthor(FFScouterNote note) {
  if (note.isPersonal) return note.content;
  return "${note.authorName ?? (note.isTeam ? "FFScouter" : "Faction")}: ${note.content}";
}

class FFScouterNotesSection extends StatefulWidget {
  final int playerId;
  final String Function() readPdaNote;
  final void Function(String text) onCopyToPda;

  const FFScouterNotesSection({
    super.key,
    required this.playerId,
    required this.readPdaNote,
    required this.onCopyToPda,
  });

  @override
  State<FFScouterNotesSection> createState() => _FFScouterNotesSectionState();
}

class _FFScouterNotesSectionState extends State<FFScouterNotesSection> {
  final _notesController = Get.find<FFScouterNotesController>();
  final _composer = TextEditingController();
  final _scroll = ScrollController();

  String _scope = "personal";
  bool _sending = false;
  String? _error;

  bool get _isSelf => widget.playerId == UserHelper.playerId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    _notesController.loadInfo();
    final error = await _notesController.loadPlayer(widget.playerId);
    if (mounted) setState(() => _error = error);
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.read<ThemeProvider>();
    final muted = Colors.grey[600];

    return GetBuilder<FFScouterNotesController>(
      builder: (ctrl) {
        final notes = ctrl.notesFor(widget.playerId);
        final loading = ctrl.isLoading(widget.playerId);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    "Saved in FFScouter as soon as you send them, and available on any device. Personal notes are "
                    "only visible to you, faction notes to your whole faction.",
                    style: TextStyle(fontSize: 11, color: muted, fontStyle: FontStyle.italic),
                  ),
                ),
                if (loading)
                  const Padding(
                    padding: EdgeInsets.all(4),
                    child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                else
                  SizedBox(
                    width: 30,
                    height: 24,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 18,
                      icon: const Icon(Icons.refresh),
                      onPressed: _load,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (ctrl.keyProblem)
              _keyProblem(themeProvider)
            else ...[
              if (notes.isEmpty && !loading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text("No FFScouter notes for this player", style: TextStyle(fontSize: 12, color: muted)),
                ),
              if (notes.isNotEmpty)
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 260),
                  child: Scrollbar(
                    controller: _scroll,
                    thumbVisibility: notes.length > 3,
                    child: ListView.builder(
                      controller: _scroll,
                      shrinkWrap: true,
                      padding: EdgeInsets.only(right: notes.length > 3 ? 8 : 0),
                      itemCount: notes.length,
                      itemBuilder: (_, i) => _noteTile(notes[i], themeProvider, "${i + 1}/${notes.length}"),
                    ),
                  ),
                ),
              if (!_isSelf) _composerWidget(ctrl, themeProvider),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(_error!, style: const TextStyle(fontSize: 12, color: Colors.red)),
              ),
          ],
        );
      },
    );
  }

  Widget _keyProblem(ThemeProvider themeProvider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Your API key needs to be registered with FFScouter to use shared notes",
          style: TextStyle(fontSize: 12, color: themeProvider.mainText),
        ),
        TextButton.icon(
          icon: const Icon(Icons.app_registration, size: 16),
          label: const Text("Register key"),
          onPressed: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FFScouterInfoPage(
                  settingsProvider: context.read<SettingsProvider>(),
                  themeProvider: themeProvider,
                  jumpToKeySetup: true,
                ),
              ),
            );
            _notesController.resetKeyProblem();
            if (mounted) _load();
          },
        ),
      ],
    );
  }

  Widget _noteTile(FFScouterNote note, ThemeProvider themeProvider, String position) {
    final (label, color) = switch (note.scope) {
      "faction" => ("Faction", Colors.green[700]!),
      "ffscouter" => ("FFScouter", Colors.pink[600]!),
      _ => ("Personal", Colors.blueGrey),
    };
    final author = note.isPersonal ? null : (note.authorName ?? (note.isTeam ? "FFScouter" : null));

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(8, 4, 2, 6),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 3)),
        color: color.withValues(alpha: 0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
              ),
              Expanded(
                child: Text(
                  "${author != null ? "  $author" : ""}  ${ffScouterNoteAge(note.createdAt)}",
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(position, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
              _smallIcon(
                icon: Icons.move_down,
                tooltip: "Copy to my Torn PDA note",
                onPressed: () => widget.onCopyToPda(ffScouterNoteWithAuthor(note)),
              ),
              if (note.canSoftDelete)
                _smallIcon(icon: Icons.delete_outline, tooltip: "Delete", onPressed: () => _delete(note)),
            ],
          ),
          Text(note.content, style: TextStyle(fontSize: 13, color: themeProvider.mainText)),
        ],
      ),
    );
  }

  Widget _smallIcon({required IconData icon, required String tooltip, required VoidCallback onPressed}) {
    return SizedBox(
      width: 30,
      height: 24,
      child: IconButton(
        padding: EdgeInsets.zero,
        iconSize: 17,
        tooltip: tooltip,
        icon: Icon(icon, color: Colors.grey[600]),
        onPressed: onPressed,
      ),
    );
  }

  Widget _composerWidget(FFScouterNotesController ctrl, ThemeProvider themeProvider) {
    final canPostFaction = ctrl.info?.canPostFaction ?? false;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _scopeChip("personal", "Personal", enabled: true),
              const SizedBox(width: 8),
              _scopeChip("faction", "Faction", enabled: canPostFaction),
            ],
          ),
          if (!canPostFaction && (ctrl.info?.inFaction ?? false))
            Text(
              "Your faction leaders can allow members to post faction notes on ffscouter.com",
              style: TextStyle(fontSize: 11, color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
          const SizedBox(height: 6),
          TextField(
            controller: _composer,
            style: TextStyle(fontSize: 13, color: themeProvider.mainText),
            minLines: 1,
            maxLines: 4,
            maxLength: kFFScouterNoteMaxLength,
            maxLengthEnforcement: MaxLengthEnforcement.none,
            inputFormatters: [FFScouterNoteInputFormatter()],
            smartQuotesType: SmartQuotesType.disabled,
            smartDashesType: SmartDashesType.disabled,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _send(),
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            decoration: InputDecoration(
              isDense: true,
              border: const OutlineInputBorder(),
              labelText: _scope == "faction" ? "New faction note" : "New personal note",
              suffixIcon: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : IconButton(icon: const Icon(Icons.send), onPressed: _send),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  ctrl.info != null ? "Personal notes: ${ctrl.info!.personalUsed}/${ctrl.info!.personalLimit}" : "",
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                icon: const Icon(Icons.move_up, size: 16),
                label: const Text("Use my Torn PDA note", style: TextStyle(fontSize: 12)),
                onPressed: _copyFromPda,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copyFromPda() {
    final text = toFFScouterNoteText(widget.readPdaNote());
    if (text.isEmpty) {
      setState(() => _error = "Your Torn PDA note is empty");
      return;
    }
    _composer.text = text;
    _composer.selection = TextSelection.collapsed(offset: text.length);
    setState(() => _error = null);
  }

  Widget _scopeChip(String scope, String label, {required bool enabled}) {
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      visualDensity: VisualDensity.compact,
      selected: _scope == scope,
      onSelected: enabled ? (_) => setState(() => _scope = scope) : null,
    );
  }

  Future<void> _send() async {
    if (_sending) return;
    final text = toFFScouterNoteText(_composer.text);
    if (!isValidFFScouterNoteText(text)) {
      setState(() => _error = text.isEmpty ? "Write something first" : "Notes can have up to 400 characters");
      return;
    }

    if (_scope == "faction" && !await Prefs().getFFScouterFactionNoteWarned()) {
      if (!mounted) return;
      final accepted = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text("Faction note", style: TextStyle(fontSize: 16)),
          content: const Text(
            "Faction notes are stored by FFScouter and every member of your faction can read them, also from "
            "the FFScouter website and scripts.",
            style: TextStyle(fontSize: 13),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Cancel")),
            TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Post")),
          ],
        ),
      );
      if (accepted != true) return;
      Prefs().setFFScouterFactionNoteWarned(true);
    }

    setState(() {
      _sending = true;
      _error = null;
    });
    final error = await _notesController.create(playerId: widget.playerId, scope: _scope, content: text);
    if (!mounted) return;
    setState(() {
      _sending = false;
      _error = error;
      if (error == null) _composer.clear();
    });
    if (error == null) {
      if (_scroll.hasClients) _scroll.jumpTo(0);
      BotToast.showText(
        text: "Saved in FFScouter",
        contentColor: Colors.green[800]!,
        textStyle: const TextStyle(fontSize: 13, color: Colors.white),
        duration: const Duration(seconds: 2),
      );
    }
  }

  Future<void> _delete(FFScouterNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete note", style: TextStyle(fontSize: 16)),
        content: Text(
          note.isFaction ? "This removes the note for your whole faction." : "Delete this note?",
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text("Delete")),
        ],
      ),
    );
    if (confirmed != true) return;
    final error = await _notesController.delete(note);
    if (!mounted) return;
    if (error != null) {
      BotToast.showText(
        text: error,
        contentColor: Colors.red[800]!,
        textStyle: const TextStyle(fontSize: 13, color: Colors.white),
        duration: const Duration(seconds: 3),
      );
    }
  }
}
