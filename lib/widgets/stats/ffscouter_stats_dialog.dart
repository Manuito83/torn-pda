import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_stats_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/utils/external/ffscouter_comm.dart';
import 'package:torn_pda/utils/number_formatter.dart';
import 'package:torn_pda/widgets/stats/ffscouter_info.dart';
import 'package:torn_pda/widgets/stats/stats_dialog.dart';

class FFScouterStatsDialog extends StatefulWidget {
  FFScouterStatsDialog({
    required this.ffScouterStatsPayload,
    required this.themeProvider,
    required this.callBackToDisableFFScouterTab,
  });

  final FFScouterStatsPayload ffScouterStatsPayload;
  final ThemeProvider themeProvider;
  final Function callBackToDisableFFScouterTab;

  @override
  State<FFScouterStatsDialog> createState() => _FFScouterStatsDialogState();
}

class _FFScouterStatsDialogState extends State<FFScouterStatsDialog> {
  final UserController _u = Get.find<UserController>();
  late Future _ffScouterDetailsFetched;

  bool _preEnabled = false;

  @override
  void initState() {
    super.initState();
    _ffScouterDetailsFetched = _fetchDetails();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    "FFSCOUTER",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            FutureBuilder(
              future: _ffScouterDetailsFetched,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.data is FFScouterPlayerStats) {
                    return _mainResponseWidget(snapshot.data as FFScouterPlayerStats);
                  } else if (snapshot.data is Map<String, dynamic>) {
                    final errorData = snapshot.data as Map<String, dynamic>;
                    final errorMessage = errorData['errorMessage'] as String;
                    final errorCode = errorData['errorCode'] as int?;
                    return _errorWidget(errorMessage, errorCode);
                  } else if (snapshot.data is String) {
                    // Legacy string error handling
                    return _errorWidget(snapshot.data as String, null);
                  } else if (snapshot.data == null && _preEnabled) {
                    return _preEnabledWidget();
                  }
                  return const Text("Error fetching from FFScouter");
                }
                return const Padding(
                  padding: EdgeInsets.only(top: 100),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text("Fetching from FFScouter"),
                      Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorWidget(String errorMessage, int? errorCode) {
    final isKeyNotRegistered = errorCode == 6;

    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 50),
        child: Column(
          children: [
            Text(
              errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            if (isKeyNotRegistered) ...[
              const SizedBox(height: 16),
              Text(
                "Your API key is not registered with FFScouter. "
                "You can register it directly from Torn PDA.",
                style: TextStyle(fontSize: 13, color: widget.themeProvider.mainText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FFScouterInfoPage(
                        settingsProvider: context.read<SettingsProvider>(),
                        themeProvider: widget.themeProvider,
                        jumpToKeySetup: true,
                      ),
                    ),
                  );
                  // Retry after registration
                  if (mounted) {
                    setState(() {
                      _ffScouterDetailsFetched = _fetchDetails();
                    });
                  }
                },
                icon: const Icon(Icons.app_registration, size: 18),
                label: const Text("Register Key"),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                child: Column(
                  children: [
                    Text(
                      "Make sure you have registered your key with FFScouter.\n\n"
                      "If you have, make sure you are using the correct key or that an alternative key has been "
                      "provided in Torn PDA Settings.",
                      style: TextStyle(fontSize: 13, color: widget.themeProvider.mainText),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => FFScouterInfoPage(
                              settingsProvider: context.read<SettingsProvider>(),
                              themeProvider: widget.themeProvider,
                              jumpToKeySetup: true,
                            ),
                          ),
                        );
                        if (mounted) {
                          setState(() {
                            _ffScouterDetailsFetched = _fetchDetails();
                          });
                        }
                      },
                      icon: const Icon(Icons.settings, size: 16),
                      label: const Text("Open FFScouter Setup", style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _mainResponseWidget(FFScouterPlayerStats stats) {
    String bsString = "N/A";
    String ffString = "N/A";

    // Prefer the human-readable estimate from the API; fall back to formatting the raw number
    if (stats.bsEstimateHuman != null && stats.bsEstimateHuman!.isNotEmpty) {
      bsString = stats.bsEstimateHuman!;
    } else if (stats.bsEstimate != null) {
      bsString = formatBigNumbers(stats.bsEstimate!);
    }

    if (stats.fairFight != null) {
      ffString = stats.fairFight!.toStringAsFixed(2);
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "BATTLE SCORE ESTIMATE",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink[700], fontSize: 16),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 10),
            child: Text(
              bsString,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
          ),
          const SizedBox(height: 20),
          if (stats.fairFight != null)
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 10),
              child: Row(
                children: [
                  const Text(
                    "Fair Fight: ",
                    style: TextStyle(fontSize: 15),
                  ),
                  Text(
                    ffString,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ],
              ),
            ),
          if (stats.lastUpdated != null)
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Last updated",
                    style: TextStyle(fontSize: 15),
                  ),
                  const SizedBox(height: 2),
                  Builder(builder: (context) {
                    final updatedDate = DateTime.fromMillisecondsSinceEpoch(stats.lastUpdated! * 1000);
                    final daysAgo = DateTime.now().difference(updatedDate).inDays;
                    final dateFormatted = "${updatedDate.day.toString().padLeft(2, '0')} "
                        "${_monthName(updatedDate.month)} "
                        "${updatedDate.year}";
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateFormatted,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey[600]),
                        ),
                        Text(
                          "$daysAgo days ago",
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _preEnabledWidget() {
    return Column(
      children: [
        Icon(Icons.shield_outlined, color: Colors.grey[400], size: 40),
        const SizedBox(height: 12),
        Text(
          "FFScouter requires your consent before use",
          style: TextStyle(color: Colors.grey[600], fontSize: 14, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Text(
          "Please review the terms, data policy and conditions before enabling",
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FFScouterInfoPage(
                      settingsProvider: context.read<SettingsProvider>(),
                      themeProvider: widget.themeProvider,
                    ),
                  ),
                );
                // If the user accepted in the dialog, fetch the data
                if (context.read<SettingsProvider>().ffScouterEnabledStatus == 1) {
                  setState(() {
                    _preEnabled = false;
                    _ffScouterDetailsFetched = _fetchDetails();
                  });
                }
              },
              icon: const Icon(Icons.info_outline, size: 18),
              label: const Text("Review & Enable"),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () {
                context.read<SettingsProvider>().ffScouterEnabledStatus = 0;
                _preEnabled = false;
                widget.callBackToDisableFFScouterTab();
              },
              child: const Text("Disable"),
            ),
          ],
        ),
      ],
    );
  }

  Future<dynamic> _fetchDetails() async {
    final settingsProvider = context.read<SettingsProvider>();

    // FFScouter is pre-enabled (never used, but not disabled)
    if (settingsProvider.ffScouterEnabledStatus == -1) {
      _preEnabled = true;
      return null;
    }

    final result = await FFScouterComm.getStats(
      key: _u.alternativeFFScouterKey,
      targetIds: [widget.ffScouterStatsPayload.targetId],
    );

    if (result.success && result.data != null && result.data!.isNotEmpty) {
      return result.data!.first;
    } else {
      // Return a map with error details so the UI can distinguish error code 6
      return {
        'errorMessage': result.errorMessage ?? "Error fetching data from FFScouter",
        'errorCode': result.errorCode,
      };
    }
  }

  String _monthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month - 1];
  }
}
