import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_targets_model.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/ffscouter_notes_controller.dart';
import 'package:torn_pda/providers/player_notes_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/utils/number_formatter.dart';
import 'package:torn_pda/widgets/ffscouter/ffscouter_notes_badge.dart';
import 'package:torn_pda/widgets/player_notes_dialog.dart';
import 'package:torn_pda/widgets/profile_check/profile_check_add_button.dart';

class FFScouterTargetCard extends StatefulWidget {
  const FFScouterTargetCard({super.key, required this.target, required this.onAttack, this.onChanged});

  final FFScouterTarget target;
  final void Function(bool shortTap) onAttack;

  /// After a status refresh
  final VoidCallback? onChanged;

  @override
  State<FFScouterTargetCard> createState() => _FFScouterTargetCardState();
}

class _FFScouterTargetCardState extends State<FFScouterTargetCard> {
  final UserController _u = Get.find<UserController>();
  late ThemeProvider _themeProvider;
  bool _refreshing = false;

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    return _buildTargetCard(widget.target);
  }

  Widget _buildTargetCard(FFScouterTarget target) {
    final lastActionText = _formatLastAction(target.lastAction);
    final bsText = target.bsEstimateHuman ?? (target.bsEstimate != null ? formatBigNumbers(target.bsEstimate!) : "N/A");
    final ffText = target.fairFight?.toStringAsFixed(2) ?? "N/A";
    final pid = target.playerId ?? 0;

    // Green border when just updated
    final borderColor = target.justUpdated ? Colors.green : Colors.transparent;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: borderColor, width: 1.5),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        onTap: () => widget.onAttack(true),
        onLongPress: () => widget.onAttack(false),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Name + Level + Action buttons
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            target.name ?? "Unknown",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text("[${target.playerId}]", style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        const SizedBox(width: 4),
                        _buildFactionIcon(target),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: _themeProvider.currentTheme == AppTheme.light ? Colors.grey[300] : Colors.grey[700],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "Lv ${target.level ?? '?'}",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _themeProvider.mainText),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Refresh status
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: _refreshing
                        ? const Padding(padding: EdgeInsets.all(7), child: CircularProgressIndicator(strokeWidth: 2))
                        : IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(Icons.refresh, size: 20, color: Colors.blueGrey[400]),
                            tooltip: "Refresh status",
                            onPressed: () => _refreshTargetStatus(target),
                          ),
                  ),
                  const SizedBox(width: 4),
                  // Notes
                  _buildNotesIcon(target),
                  const SizedBox(width: 4),
                  // Add to targets
                  ProfileCheckAddButton(
                    profileId: pid,
                    playerName: target.name,
                    factionId: target.factionId,
                    icon: Icons.add_circle_outline,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Row 2: Stats + last action
              Row(
                children: [
                  _statChip("BS", bsText, Colors.blue[700]!),
                  const SizedBox(width: 8),
                  _statChip("FF", ffText, _ffColor(target.fairFight)),
                  const Spacer(),
                  if (lastActionText != null)
                    Text(lastActionText, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
                ],
              ),
              // Row 3: Live status (if has been refreshed)
              if (target.hasStatus) _buildStatusRow(target),
              // Row 4: Player note (if any)
              _buildNoteRow(target),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFactionIcon(FFScouterTarget target) {
    final List<Widget> icons = [];

    // Faction icon
    if (target.factionName != null &&
        target.factionName!.isNotEmpty &&
        target.factionId != null &&
        target.factionId != 0) {
      final bool sameFaction = target.factionId == _u.factionId && _u.factionId != 0;
      final Color iconColor = sameFaction ? Colors.red : _themeProvider.mainText;
      final Color borderColor = sameFaction ? Colors.red : Colors.transparent;
      icons.add(
        Tooltip(
          message: target.factionName!,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: borderColor, width: 1.5),
              shape: BoxShape.circle,
            ),
            padding: const EdgeInsets.all(2),
            child: ImageIcon(const AssetImage('images/icons/faction.png'), size: 12, color: iconColor),
          ),
        ),
      );
    }

    // Company icon
    if (target.companyId != null && target.companyId != 0) {
      final bool sameCompany = target.companyId == _u.companyId && _u.companyId != 0;
      if (sameCompany) {
        if (icons.isNotEmpty) icons.add(const SizedBox(width: 2));
        icons.add(
          Tooltip(
            message: target.companyName ?? "Company",
            child: const Icon(Icons.work, size: 14, color: Colors.red),
          ),
        );
      }
    }

    if (icons.isEmpty) return const SizedBox.shrink();
    return Row(mainAxisSize: MainAxisSize.min, children: icons);
  }

  Widget _buildNotesIcon(FFScouterTarget target) {
    return GetBuilder<PlayerNotesController>(
      builder: (ctrl) {
        final note = ctrl.getNoteForPlayer(target.playerId.toString());
        Color iconColor = _themeProvider.mainText;
        if (note != null && !PlayerNoteColor.isNone(note.color)) {
          iconColor = PlayerNoteColor.toColor(note.color);
        }
        final hasNote = note != null && (note.note.isNotEmpty || !PlayerNoteColor.isNone(note.color));
        return SizedBox(
          width: 32,
          height: 32,
          child: IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              hasNote ? Icons.sticky_note_2 : Icons.sticky_note_2_outlined,
              size: 20,
              color: hasNote ? iconColor : Colors.blueGrey[400],
            ),
            tooltip: "Notes",
            onPressed: () {
              showPlayerNotesDialog(
                context: context,
                playerId: target.playerId.toString(),
                playerName: target.name ?? '',
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildNoteRow(FFScouterTarget target) {
    return GetBuilder<PlayerNotesController>(
      builder: (ctrl) => GetBuilder<FFScouterNotesController>(
        builder: (ffsCtrl) {
          final note = ctrl.getNoteForPlayer(target.playerId.toString());
          final hasPdaNote = note != null && (note.note.isNotEmpty || !PlayerNoteColor.isNone(note.color));
          final hasFFScouterNotes = target.playerId != null && ffsCtrl.notesFor(target.playerId!).isNotEmpty;
          if (!hasPdaNote && !hasFFScouterNotes) return const SizedBox.shrink();
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                if (hasPdaNote && !PlayerNoteColor.isNone(note.color))
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.circle, size: 8, color: PlayerNoteColor.toColor(note.color)),
                  ),
                if (hasPdaNote)
                  Flexible(
                    child: PdaNoteUnlessFFScouter(
                      playerId: target.playerId,
                      child: Text(
                        note.effectiveDisplayText,
                        style: TextStyle(fontSize: 11, color: Colors.grey[500], fontStyle: FontStyle.italic),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                Flexible(
                  child: FFScouterLatestNote(
                    playerId: target.playerId,
                    fontSize: 11,
                    padding: EdgeInsets.only(left: hasPdaNote ? 5 : 0),
                    onTap: () => _openNotes(target),
                  ),
                ),
                if (target.playerId != null)
                  FFScouterNotesBadge(
                    playerId: target.playerId!,
                    fontSize: 11,
                    padding: const EdgeInsets.only(left: 5),
                    onTap: () => _openNotes(target),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _openNotes(FFScouterTarget target) {
    return showPlayerNotesDialog(
      context: context,
      playerId: target.playerId.toString(),
      playerName: target.name ?? '',
      openFFScouter: true,
    );
  }

  Widget _buildStatusRow(FFScouterTarget target) {
    final state = target.statusState ?? "";
    final color = target.statusColor ?? "";
    final lastActionStatus = target.lastActionStatus ?? "Offline";

    // Online status icon
    Widget onlineIcon;
    if (lastActionStatus == "Online") {
      onlineIcon = const Icon(Icons.circle, size: 10, color: Colors.green);
    } else if (lastActionStatus == "Idle") {
      onlineIcon = const Icon(Icons.adjust, size: 10, color: Colors.orange);
    } else {
      onlineIcon = const Icon(Icons.remove_circle, size: 10, color: Colors.grey);
    }

    // State text
    String stateText = "OK";
    Color stateColor = Colors.green;
    if (state.contains("Hospital")) {
      stateText = "Hospital";
      stateColor = Colors.red;
      if (target.statusUntil != null && target.statusUntil! > 0) {
        final until = DateTime.fromMillisecondsSinceEpoch(target.statusUntil! * 1000);
        final diff = until.difference(DateTime.now());
        if (diff.isNegative) {
          stateText = "Out of hospital";
          stateColor = Colors.green;
        } else {
          final m = diff.inMinutes;
          final h = diff.inHours;
          stateText = h > 0 ? "Hospital (${h}h ${m % 60}m)" : "Hospital (${m}m)";
        }
      }
    } else if (state.contains("Jail")) {
      stateText = "Jail";
      stateColor = Colors.orange;
      if (target.statusUntil != null && target.statusUntil! > 0) {
        final until = DateTime.fromMillisecondsSinceEpoch(target.statusUntil! * 1000);
        final diff = until.difference(DateTime.now());
        if (!diff.isNegative) {
          final m = diff.inMinutes;
          stateText = "Jail (${m}m)";
        }
      }
    } else if (state.contains("Federal") || state.contains("Fallen")) {
      stateText = state;
      stateColor = Colors.red[800]!;
    } else if (color == "blue") {
      stateText = target.statusDescription ?? "Traveling";
      stateColor = Colors.blue;
    }

    // Updated ago text
    String updatedAgo = "";
    if (target.statusLastUpdated != null) {
      final dt = DateTime.fromMillisecondsSinceEpoch(target.statusLastUpdated! * 1000);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1) {
        updatedAgo = "just now";
      } else if (diff.inMinutes < 60) {
        updatedAgo = "${diff.inMinutes}m ago";
      } else if (diff.inHours < 24) {
        updatedAgo = "${diff.inHours}h ago";
      } else {
        updatedAgo = "${diff.inDays}d ago";
      }
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          onlineIcon,
          const SizedBox(width: 4),
          Text(lastActionStatus, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          const SizedBox(width: 8),
          Icon(Icons.circle, size: 8, color: stateColor),
          const SizedBox(width: 3),
          Flexible(
            child: Text(
              stateText,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: stateColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (updatedAgo.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(updatedAgo, style: TextStyle(fontSize: 10, color: Colors.grey[500])),
          ],
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("$label: ", style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Color _ffColor(double? ff) {
    if (ff == null) return Colors.grey;
    if (ff >= 2.5) return Colors.green[700]!;
    if (ff >= 2.0) return Colors.green;
    if (ff >= 1.5) return Colors.orange;
    return Colors.red;
  }

  String? _formatLastAction(int? timestamp) {
    if (timestamp == null) return null;
    final dt = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 30) return "${diff.inDays ~/ 30}mo ago";
    if (diff.inDays > 0) return "${diff.inDays}d ago";
    if (diff.inHours > 0) return "${diff.inHours}h ago";
    return "${diff.inMinutes}m ago";
  }

  Future<void> _refreshTargetStatus(FFScouterTarget target) async {
    if (target.playerId == null) return;
    final pid = target.playerId!;

    setState(() => _refreshing = true);

    try {
      final result = await ApiCallsV1.getTarget(playerId: pid.toString());
      if (result is TargetModel && mounted) {
        target.updateFromTargetModel(result);
        target.justUpdated = true;
        setState(() => _refreshing = false);
        widget.onChanged?.call();
        // Clear green border after delay
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => target.justUpdated = false);
          }
        });
      } else {
        if (mounted) setState(() => _refreshing = false);
        BotToast.showText(
          text: "Could not fetch status for ${target.name}",
          contentColor: Colors.red[800]!,
          textStyle: const TextStyle(fontSize: 13, color: Colors.white),
          duration: const Duration(seconds: 2),
        );
      }
    } catch (_) {
      if (mounted) setState(() => _refreshing = false);
    }
  }
}
