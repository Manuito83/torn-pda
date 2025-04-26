import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:torn_pda/providers/sendbird_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/external/tsc_comm.dart';
import 'package:torn_pda/utils/number_formatter.dart';

import '../../models/faction/faction_model.dart';

class ShareAttackDialog extends StatefulWidget {
  final Member member;

  const ShareAttackDialog({
    super.key,
    required this.member,
  });

  @override
  ShareAttackDialogState createState() => ShareAttackDialogState();
}

class ShareAttackDialogState extends State<ShareAttackDialog> {
  late final SettingsProvider _settingsProvider;

  bool includeEstimates = false;
  bool includeSpied = false;
  bool includeTsc = false;
  bool isLoading = true;

  late String attackUrl;
  late String estStats;
  String? spiedText;
  String? tscDetails;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    includeEstimates = _settingsProvider.shareOptions.contains('estimates');
    includeSpied = _settingsProvider.shareOptions.contains('spies');
    includeTsc = _settingsProvider.shareOptions.contains('tsc');
    _prepareData();
  }

  Future<void> _prepareData() async {
    final id = widget.member.memberId.toString();
    attackUrl = 'https://www.torn.com/loader.php?sid=attack&user2ID=$id';
    estStats = widget.member.statsEstimated ?? '';

    if (widget.member.statsExactTotalKnown != -1 && widget.member.statsExactTotalUpdated != null) {
      final exact = formatBigNumbers(widget.member.statsExactTotalKnown!);
      final updatedTs = DateTime.fromMillisecondsSinceEpoch(widget.member.statsExactTotalUpdated! * 1000);
      final months = DateTime.now().difference(updatedTs).inDays ~/ 30;
      spiedText = 'Spied: $exact ($months month${months == 1 ? '' : 's'} ago)';
    }

    if (_settingsProvider.tscEnabledStatus != 0 && _settingsProvider.tscEnabledStatusRemoteConfig) {
      final apiKey = Get.find<UserController>().alternativeTSCKey;
      final response = await TSCComm.checkIfUserExists(
        targetId: id,
        ownApiKey: apiKey,
      );
      if (response.success) {
        final data = int.tryParse(response.spy?.estimate?.stats ?? '');
        final dateStr = response.spy?.statInterval?.lastUpdated;
        final last = DateTime.tryParse(dateStr ?? '');
        if (data != null && last != null) {
          final diff = DateTime.now().difference(last);
          final text = diff.inDays < 31
              ? '${diff.inDays} day${diff.inDays == 1 ? '' : 's'} ago'
              : '${diff.inDays ~/ 30} month${diff.inDays ~/ 30 == 1 ? '' : 's'} ago';
          tscDetails = 'TSC: ${formatBigNumbers(data)} ($text)';
        }
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  void _saveSettings() {
    final opts = <String>[];
    if (includeEstimates) opts.add('estimates');
    if (includeSpied) opts.add('spies');
    if (includeTsc) opts.add('tsc');
    _settingsProvider.shareOptions = opts;
  }

  String _buildShareText() {
    final buffer = StringBuffer();
    buffer.writeln('Attack: ${widget.member.name} [${widget.member.memberId}]');
    if (includeEstimates && estStats.isNotEmpty && estStats != "unk") buffer.writeln('Estimated: $estStats');
    if (includeSpied && spiedText != null) buffer.writeln(spiedText);
    if (includeTsc && tscDetails != null) buffer.writeln(tscDetails);
    buffer.writeln('URL: $attackUrl');
    return buffer.toString();
  }

  void _saveShareOption(String key, bool enabled) {
    final opts = List<String>.from(_settingsProvider.shareOptions);
    if (enabled) {
      if (!opts.contains(key)) opts.add(key);
    } else {
      opts.remove(key);
    }
    _settingsProvider.shareOptions = opts;
  }

  @override
  Widget build(BuildContext context) {
    final buttonStyle = ElevatedButton.styleFrom(
      minimumSize: const Size(80, 75),
      padding: const EdgeInsets.symmetric(vertical: 4),
    );
    return AlertDialog(
      title: const Text('Share attack details'),
      content: isLoading
          ? const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select what to include in the message:',
                    style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  Text(
                    'Attack: ${widget.member.name} [${widget.member.memberId}]',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  if ((estStats.isEmpty || estStats == "unk") && spiedText == null && tscDetails == null)
                    const Text(
                      "There's no estimated stats, nor spied stats, nor TSC stats available. "
                      "You will only be able to share the player name, ID and attack URL.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.red,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  if (estStats != "unk" || estStats.isEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            color: Colors.grey[200],
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Estimated: $estStats',
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                        Checkbox(
                          value: includeEstimates,
                          onChanged: (v) {
                            setState(() {
                              includeEstimates = v!;
                            });
                            _saveShareOption('estimates', includeEstimates);
                          },
                        ),
                      ],
                    ),
                  if (spiedText != null)
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            color: Colors.grey[200],
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                spiedText!,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                        Checkbox(
                          value: includeSpied,
                          onChanged: (v) {
                            setState(() {
                              includeSpied = v!;
                            });
                            _saveShareOption('spies', includeEstimates);
                          },
                        ),
                      ],
                    ),
                  if (tscDetails != null)
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            color: Colors.grey[200],
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                tscDetails!,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                        Checkbox(
                          value: includeTsc,
                          onChanged: (v) {
                            setState(() {
                              includeTsc = v!;
                            });
                            _saveShareOption('tsc', includeEstimates);
                          },
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  const Text(
                    '+ Attack URL',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                ],
              ),
            ),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            Row(
              children: [
                ElevatedButton(
                  style: buttonStyle,
                  onPressed: () {
                    _saveSettings();
                    Clipboard.setData(ClipboardData(text: _buildShareText()));
                    Navigator.of(context).pop();
                  },
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy),
                        SizedBox(height: 2),
                        Text(
                          'COPY',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: buttonStyle,
                  onPressed: () {
                    _saveSettings();
                    final text = _buildShareText();
                    final sb = Get.find<SendbirdController>();
                    final userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
                    final faction = userProvider.basic?.faction?.factionId;
                    if (faction != null) {
                      sb.sendMessage(channelUrl: 'faction-$faction', message: text);
                      debugPrint(text);
                    }
                    Navigator.of(context).pop();
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.chat),
                        SizedBox(height: 2),
                        Text(
                          'FACTION\nCHAT',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
