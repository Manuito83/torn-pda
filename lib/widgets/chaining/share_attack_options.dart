import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import 'package:torn_pda/providers/sendbird_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/utils/external/tsc_comm.dart';
import 'package:torn_pda/utils/number_formatter.dart';
import 'package:torn_pda/utils/user_helper.dart';

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
  late final ThemeProvider _themeProvider;

  bool _includeEstimates = false;
  bool _includeSpied = false;
  bool _includeTsc = false;
  bool _isLoading = true;

  late String _attackUrl;
  late String _estStats;
  String? _spiedText;
  String? _tscDetails;
  String _tscError = "";

  @override
  void initState() {
    super.initState();
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _includeEstimates = _settingsProvider.shareOptions.contains('estimates');
    _includeSpied = _settingsProvider.shareOptions.contains('spies');
    _includeTsc = _settingsProvider.shareOptions.contains('tsc');
    _prepareData();
  }

  Future<void> _prepareData() async {
    final id = widget.member.memberId.toString();
    _attackUrl = 'https://www.torn.com/loader.php?sid=attack&user2ID=$id';
    _estStats = widget.member.statsEstimated ?? '';

    if (widget.member.statsExactTotalKnown != -1 && widget.member.statsExactTotalUpdated != null) {
      final exact = formatBigNumbers(widget.member.statsExactTotalKnown!);
      final updatedTs = DateTime.fromMillisecondsSinceEpoch(widget.member.statsExactTotalUpdated! * 1000);
      final months = DateTime.now().difference(updatedTs).inDays ~/ 30;
      _spiedText = 'Spied: $exact ($months month${months == 1 ? '' : 's'} ago)';
    }

    if (_settingsProvider.tscEnabledStatus != 0 && _settingsProvider.tscEnabledStatusRemoteConfig) {
      final apiKey = Get.find<UserController>().alternativeTSCKey;
      final response = await TSCComm.checkIfUserExists(
        targetId: id,
        ownApiKey: apiKey,
        timeout: 4,
      );

      if (response.success) {
        _tscDetails = "TSC:";
        final tscEstimate = int.tryParse(response.spy?.estimate?.stats ?? '');
        final tscIntervalMin = int.tryParse(response.spy?.statInterval?.min ?? '');
        final tscIntervalMax = int.tryParse(response.spy?.statInterval?.max ?? '');
        final tscDate = response.spy?.statInterval?.lastUpdated;
        final tscDateTime = DateTime.tryParse(tscDate ?? '');

        if (tscEstimate != null) {
          _tscDetails = "$_tscDetails Est ${formatBigNumbers(tscEstimate)}";
        }

        if (tscIntervalMin != null && tscIntervalMax != null && tscDateTime != null) {
          final dateDiff = DateTime.now().difference(tscDateTime);
          final dateDiffText = dateDiff.inDays < 31
              ? '${dateDiff.inDays} day${dateDiff.inDays == 1 ? '' : 's'} ago'
              : '${dateDiff.inDays ~/ 30} month${dateDiff.inDays ~/ 30 == 1 ? '' : 's'} ago';
          _tscDetails = "$_tscDetails, Spy Range ${formatBigNumbers(tscIntervalMin)}"
              " - ${formatBigNumbers(tscIntervalMax)} ($dateDiffText)";
        }
      } else {
        _tscError = "TSC details could not be retrieved: ${response.message}";
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _saveSettings() {
    final opts = <String>[];
    if (_includeEstimates) opts.add('estimates');
    if (_includeSpied) opts.add('spies');
    if (_includeTsc) opts.add('tsc');
    _settingsProvider.shareOptions = opts;
  }

  String _buildShareText() {
    final buffer = StringBuffer();
    buffer.writeln('Target: ${widget.member.name} [${widget.member.memberId}]');
    if (_includeEstimates && _estStats.isNotEmpty && _estStats != "unk") buffer.writeln('Estimated: $_estStats');
    if (_includeSpied && _spiedText != null) buffer.writeln(_spiedText);
    if (_includeTsc && _tscDetails != null) buffer.writeln(_tscDetails);
    buffer.writeln('URL: $_attackUrl');
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
      backgroundColor: _themeProvider.canvas,
      content: _isLoading
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
                    'Target: ${widget.member.name} [${widget.member.memberId}]',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  if ((_estStats.isEmpty || _estStats == "unk") && _spiedText == null && _tscDetails == null)
                    Text(
                      "There's no estimated stats, nor spied stats, nor TSC stats available. "
                      "You will only be able to share the player name, ID and attack URL.",
                      style: TextStyle(
                        fontSize: 13,
                        color: _themeProvider.getTextColor(Colors.red),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  if (_estStats != "unk" || _estStats.isEmpty)
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            color: Colors.grey[200],
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                'Estimated: $_estStats',
                                style: const TextStyle(fontSize: 14, color: Colors.black),
                              ),
                            ),
                          ),
                        ),
                        Checkbox(
                          value: _includeEstimates,
                          onChanged: (v) {
                            setState(() {
                              _includeEstimates = v!;
                            });
                            _saveShareOption('estimates', _includeEstimates);
                          },
                        ),
                      ],
                    ),
                  if (_spiedText != null)
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            color: Colors.grey[200],
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _spiedText!,
                                style: const TextStyle(fontSize: 14, color: Colors.black),
                              ),
                            ),
                          ),
                        ),
                        Checkbox(
                          value: _includeSpied,
                          onChanged: (v) {
                            setState(() {
                              _includeSpied = v!;
                            });
                            _saveShareOption('spies', _includeSpied);
                          },
                        ),
                      ],
                    ),
                  if (_tscError.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 15, 55, 8),
                      child: Text(
                        _tscError,
                        style: TextStyle(
                          fontSize: 13,
                          color: _themeProvider.getTextColor(Colors.red),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  if (_tscDetails != null)
                    Row(
                      children: [
                        Expanded(
                          child: Card(
                            color: Colors.grey[200],
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                _tscDetails!,
                                style: const TextStyle(fontSize: 14, color: Colors.black),
                              ),
                            ),
                          ),
                        ),
                        Checkbox(
                          value: _includeTsc,
                          onChanged: (v) {
                            setState(() {
                              _includeTsc = v!;
                            });
                            _saveShareOption('tsc', _includeTsc);
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
                    final faction = UserHelper.factionId;
                    if (faction != 0) {
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
