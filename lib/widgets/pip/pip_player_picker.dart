import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/pip_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';

class PipCandidate {
  const PipCandidate({required this.id, required this.name, this.state, this.until = 0, this.faction});

  final int id;
  final String name;
  final String? state;
  final int until;
  final String? faction;
}

class PipPlayersButton extends StatelessWidget {
  final List<PipCandidate> Function() candidates;

  const PipPlayersButton({super.key, required this.candidates});

  @override
  Widget build(BuildContext context) {
    final enabled = context.select<SettingsProvider, bool>((s) => s.pipEnabled && s.pipPlayerButtons);
    if (!enabled || !Get.find<PipController>().supported) return const SizedBox.shrink();
    return IconButton(
      tooltip: 'Watch players in a floating window',
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      padding: EdgeInsets.zero,
      style: const ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      icon: const Icon(Icons.picture_in_picture_alt_outlined, color: Colors.white),
      onPressed: () {
        final list = candidates();
        if (list.isEmpty) {
          BotToast.showText(
            text: 'No players to watch here',
            textStyle: const TextStyle(fontSize: 14, color: Colors.white),
            contentColor: Colors.grey[800]!,
            contentPadding: const EdgeInsets.all(10),
          );
          return;
        }
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          builder: (_) => PipPlayerPicker(candidates: list),
        );
      },
    );
  }
}

class PipPlayerPicker extends StatefulWidget {
  final List<PipCandidate> candidates;

  const PipPlayerPicker({super.key, required this.candidates});

  @override
  State<PipPlayerPicker> createState() => _PipPlayerPickerState();
}

class _PipPlayerPickerState extends State<PipPlayerPicker> {
  final _picked = <PipCandidate>[];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final full = _picked.length >= PipController.maxPlayers;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.75),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Watch in floating window', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text(
                'Up to ${PipController.maxPlayers} players',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 6),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: widget.candidates.length,
                  itemBuilder: (context, index) {
                    final candidate = widget.candidates[index];
                    final picked = _picked.contains(candidate);
                    final remaining = candidate.until - now;
                    final confined = const ['Hospital', 'Jail', 'Federal'].contains(candidate.state);
                    var state = candidate.state ?? '';
                    if (confined && remaining > 0) {
                      final d = Duration(seconds: remaining);
                      final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
                      final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
                      state = '$state ${d.inHours > 0 ? '${d.inHours}:$minutes:$secs' : '$minutes:$secs'}';
                    }
                    Color? stateColor = Colors.grey[600];
                    if (candidate.state == 'Hospital') {
                      stateColor = Colors.red[300];
                    } else if (confined) {
                      stateColor = Colors.brown[300];
                    } else if (candidate.state == 'Okay') {
                      stateColor = Colors.green[400];
                    }
                    return CheckboxListTile(
                      value: picked,
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      controlAffinity: ListTileControlAffinity.leading,
                      title: Text(
                        candidate.name.isEmpty ? '#${candidate.id}' : candidate.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: candidate.faction == null
                          ? null
                          : Text(candidate.faction!, maxLines: 1, overflow: TextOverflow.ellipsis),
                      secondary: Text(state, style: TextStyle(fontSize: 13, color: stateColor)),
                      onChanged: !picked && full
                          ? null
                          : (on) => setState(() => on! ? _picked.add(candidate) : _picked.remove(candidate)),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(44)),
                onPressed: _picked.isEmpty
                    ? null
                    : () {
                        Navigator.of(context).pop();
                        Get.find<PipController>().watchPlayers([
                          for (final candidate in _picked)
                            PipPlayer(
                              id: candidate.id,
                              name: candidate.name.isEmpty ? '#${candidate.id}' : candidate.name,
                            ),
                        ]);
                      },
                child: Text(
                  _picked.length == 1
                      ? 'Watch 1 player'
                      : 'Watch ${_picked.isEmpty ? '' : '${_picked.length} '}players',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
