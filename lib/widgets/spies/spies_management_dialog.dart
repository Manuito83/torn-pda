// Flutter imports:
import 'dart:developer';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/spies_controller.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/number_formatter.dart';

class SpiesManagementDialog extends StatefulWidget {
  @override
  SpiesManagementDialogState createState() => SpiesManagementDialogState();
}

class SpiesManagementDialogState extends State<SpiesManagementDialog> {
  final SpiesController _spyController = Get.find<SpiesController>();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _searchQueryNotifier = ValueNotifier<String>('');

  bool _fetchActive = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchQueryNotifier.dispose();
    super.dispose();
  }

  // Valid if it has an ID, OR if it has a meaningful name (not null/empty/"Player")
  bool _isValidYataSpy(dynamic spy) {
    final hasValidId = spy.targetId != null && spy.targetId!.isNotEmpty;
    final hasValidName = spy.targetName != null && spy.targetName!.isNotEmpty && spy.targetName != 'Player';
    return hasValidId || hasValidName;
  }

  // Valid if it has an ID, OR if it has a meaningful name (not null/empty/"Player")
  bool _isValidTornStatsSpy(dynamic spy) {
    final hasValidId = spy.playerId != null && spy.playerId!.isNotEmpty;
    final hasValidName = spy.playerName != null && spy.playerName!.isNotEmpty && spy.playerName != 'Player';
    return hasValidId || hasValidName;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: const EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      content: FutureBuilder(
        future: Future.delayed(const Duration(milliseconds: 500)),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            if (_fetchActive) {
              return fetchWaitScreen(context);
            } else {
              return mainSpiesScreen(context);
            }
          } else {
            return loadWaitScreen(context);
          }
        },
      ),
    );
  }

  Container mainSpiesScreen(BuildContext context) {
    String lastUpdated = "Never updated";
    int lastUpdatedTs = 0;

    if (_spyController.spiesSource == SpiesSource.yata && _spyController.yataSpiesTime != null) {
      lastUpdatedTs = _spyController.yataSpiesTime!.millisecondsSinceEpoch;
      if (lastUpdatedTs > 0) {
        lastUpdated = _spyController.statsOld((lastUpdatedTs / 1000).round());
      }
    } else if (_spyController.spiesSource == SpiesSource.tornStats && _spyController.tornStatsSpiesTime != null) {
      lastUpdatedTs = _spyController.tornStatsSpiesTime!.millisecondsSinceEpoch;
      if (lastUpdatedTs > 0) {
        lastUpdated = _spyController.statsOld((lastUpdatedTs / 1000).round());
      }
    }

    Color spiesUpdateColor = Colors.blue;
    if (lastUpdatedTs > 0) {
      final currentTime = DateTime.now().millisecondsSinceEpoch;
      final oneMonthAgo = currentTime - (30.44 * 24 * 60 * 60 * 1000).round();
      spiesUpdateColor = (lastUpdatedTs < oneMonthAgo) ? Colors.red : context.read<ThemeProvider>().mainText;
    }

    return Container(
      width: double.maxFinite,
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.only(
        top: 25,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      margin: const EdgeInsets.only(top: 30),
      decoration: BoxDecoration(
        color: context.read<ThemeProvider>().secondBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.0,
            offset: Offset(0.0, 10.0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          const Text(
            "SPIES MANAGEMENT",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Text(
                "Provider: ",
                style: TextStyle(
                  fontSize: 12,
                ),
              ),
              SizedBox(
                height: 30,
                width: 30,
                child: Image.asset(
                  _spyController.spiesSource == SpiesSource.yata
                      ? 'images/icons/yata_logo.png'
                      : 'images/icons/tornstats_logo.png',
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _spyController.spiesSource == SpiesSource.yata
                        ? _spyController.spiesSource = SpiesSource.tornStats
                        : _spyController.spiesSource = SpiesSource.yata;
                  });
                },
                child: const Padding(
                  padding: EdgeInsets.only(left: 15, right: 15),
                  child: SizedBox(
                    height: 30,
                    width: 30,
                    child: Icon(
                      Icons.swap_horiz,
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: 15,
                width: 15,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(
                    Colors.black.withAlpha((0.5 * 255).toInt()),
                    BlendMode.srcATop,
                  ),
                  child: Image.asset(
                    _spyController.spiesSource != SpiesSource.yata
                        ? 'images/icons/yata_logo.png'
                        : 'images/icons/tornstats_logo.png',
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            lastUpdated,
            style: TextStyle(
              fontSize: 12,
              color: spiesUpdateColor,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 2,
                side: const BorderSide(
                  width: 2.0,
                  color: Colors.blueGrey,
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Text("Update!"),
              ),
              onPressed: () async {
                setState(() {
                  _fetchActive = true;
                });

                bool success = false;
                try {
                  success = _spyController.spiesSource == SpiesSource.yata
                      ? await _spyController.fetchYataSpies()
                      : await _spyController.fetchTornStatsSpies();
                  if (success) {
                    BotToast.showText(
                      clickClose: true,
                      text: "Update successful!\n\n"
                          "${_spyController.spiesSource == SpiesSource.yata ? _spyController.yataSpies.length : _spyController.tornStatsSpies.spies.length} spies retrieved!",
                      textStyle: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      contentColor: Colors.green,
                      duration: const Duration(seconds: 4),
                      contentPadding: const EdgeInsets.all(10),
                    );
                  }
                } catch (e) {
                  log(e.toString());
                }

                if (!success) {
                  BotToast.showText(
                    clickClose: true,
                    text: "Update failed!",
                    textStyle: const TextStyle(
                      fontSize: 14,
                      color: Colors.white,
                    ),
                    contentColor: Colors.red,
                    duration: const Duration(seconds: 4),
                    contentPadding: const EdgeInsets.all(10),
                  );
                }

                setState(() {
                  _fetchActive = false;
                });
              },
            ),
          ),
          const SizedBox(height: 10),
          // Search field
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: TextField(
              controller: _searchController,
              autofocus: false,
              decoration: InputDecoration(
                hintText: 'Search by name or ID...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: ValueListenableBuilder<String>(
                  valueListenable: _searchQueryNotifier,
                  builder: (context, query, child) {
                    return query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _searchQueryNotifier.value = '';
                            },
                          )
                        : const SizedBox.shrink();
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                _searchQueryNotifier.value = value.toLowerCase().trim();
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
              child: ValueListenableBuilder<String>(
                valueListenable: _searchQueryNotifier,
                builder: (context, searchQuery, child) {
                  return _spiesList(searchQuery);
                },
              ),
            ),
          ),
          if (!_fetchActive)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 15),
                  child: TextButton(
                    child: const Text("Close"),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Container fetchWaitScreen(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.only(
        top: 25,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      margin: const EdgeInsets.only(top: 30),
      decoration: BoxDecoration(
        color: context.read<ThemeProvider>().secondBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.0,
            offset: Offset(0.0, 10.0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_fetchActive)
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Updating ${_spyController.spiesSource == SpiesSource.yata ? "YATA" : "Torn Stats"}..."),
                  const Text(
                    "(time limit is 2 minutes)",
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  )
                ],
              ),
            ),
          const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: CircularProgressIndicator()),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: TextButton(
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.orange),
                  ),
                  onPressed: () {
                    _spyController.cancelRequests();
                    setState(() {
                      _fetchActive = false;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Container loadWaitScreen(BuildContext context) {
    return Container(
      width: double.maxFinite,
      padding: const EdgeInsets.only(
        top: 25,
        bottom: 16,
        left: 16,
        right: 16,
      ),
      margin: const EdgeInsets.only(top: 30),
      decoration: BoxDecoration(
        color: context.read<ThemeProvider>().secondBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10.0,
            offset: Offset(0.0, 10.0),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }

  Widget _spiesList(String searchQuery) {
    try {
      // Get sorted list based on source and filter out invalid spies
      List<dynamic> sortedSpies;
      if (_spyController.spiesSource == SpiesSource.yata) {
        // Filter out invalid spies using helper method
        sortedSpies = List.from(_spyController.yataSpies.where(_isValidYataSpy))
          ..sort((a, b) => a.targetName!.trim().compareTo(b.targetName!.trim()));
      } else {
        // Filter out invalid spies using helper method
        sortedSpies = List.from(_spyController.tornStatsSpies.spies.where(_isValidTornStatsSpy))
          ..sort((a, b) => a.playerName!.trim().compareTo(b.playerName!.trim()));
      }

      // Apply search filter if needed
      if (searchQuery.isNotEmpty) {
        if (_spyController.spiesSource == SpiesSource.yata) {
          sortedSpies = sortedSpies.where((spy) {
            final name = spy.targetName?.toLowerCase() ?? '';
            final id = spy.targetId?.toString() ?? '';
            return name.contains(searchQuery) || id.contains(searchQuery);
          }).toList();
        } else {
          sortedSpies = sortedSpies.where((spy) {
            final name = spy.playerName?.toLowerCase() ?? '';
            final id = spy.playerId?.toString() ?? '';
            return name.contains(searchQuery) || id.contains(searchQuery);
          }).toList();
        }
      }

      final int spiesCount = sortedSpies.length;

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Found $spiesCount spies",
            style: const TextStyle(
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              trackVisibility: true,
              interactive: true,
              thickness: 6,
              child: ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                itemCount: spiesCount,
                itemBuilder: (context, index) {
                  final spy = sortedSpies[index];
                  // Build card on demand for visible items only
                  return _buildSpyCard(spy);
                },
              ),
            ),
          ),
        ],
      );
    } catch (e) {
      return const Padding(
        padding: EdgeInsets.only(top: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Error listing spies!",
              style: TextStyle(
                color: Colors.red,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildSpyCard(dynamic spy) {
    if (_spyController.spiesSource == SpiesSource.yata) {
      // Build display name: show "Player [ID]" if name is null/empty/Player, otherwise "Name [ID]"
      String displayName;
      final bool hasValidName = spy.targetName != null && spy.targetName!.isNotEmpty && spy.targetName != 'Player';
      final bool hasValidId = spy.targetId != null && spy.targetId!.isNotEmpty;

      if (hasValidName && hasValidId) {
        // Show name with ID in brackets
        displayName = '${spy.targetName} [${spy.targetId}]';
      } else if (hasValidName) {
        // Show only name (no ID available)
        displayName = spy.targetName!;
      } else if (hasValidId) {
        // Show "Player [ID]" for null/empty/Player names
        displayName = 'Player [${spy.targetId}]';
      } else {
        // Fallback (shouldn't happen due to filtering)
        displayName = 'Player';
      }

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "STR: ${spy.strength == -1 ? '??' : formatBigNumbers(spy.strength!)}",
                    style: const TextStyle(
                      fontSize: 11,
                    ),
                  ),
                  Text(spy.strength != -1 ? _spyController.statsOld(spy.strengthTimestamp) : "",
                      style: const TextStyle(
                        fontSize: 11,
                      )),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "DEF: ${spy.defense == -1 ? '??' : formatBigNumbers(spy.defense!)}",
                    style: const TextStyle(
                      fontSize: 11,
                    ),
                  ),
                  Text(spy.defense != -1 ? _spyController.statsOld(spy.defenseTimestamp) : "",
                      style: const TextStyle(
                        fontSize: 11,
                      )),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "SPD: ${spy.speed == -1 ? '??' : formatBigNumbers(spy.speed!)}",
                    style: const TextStyle(
                      fontSize: 11,
                    ),
                  ),
                  Text(spy.speed != -1 ? _spyController.statsOld(spy.speedTimestamp) : "",
                      style: const TextStyle(
                        fontSize: 11,
                      )),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "DEX: ${spy.dexterity == -1 ? '??' : formatBigNumbers(spy.dexterity!)}",
                    style: const TextStyle(
                      fontSize: 11,
                    ),
                  ),
                  Text(spy.dexterity != -1 ? _spyController.statsOld(spy.dexterityTimestamp) : "",
                      style: const TextStyle(
                        fontSize: 11,
                      )),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "TOTAL: ${spy.total == -1 ? '??' : formatBigNumbers(spy.total!)}",
                    style: const TextStyle(
                      fontSize: 11,
                    ),
                  ),
                  Text(spy.total != -1 ? _spyController.statsOld(spy.totalTimestamp) : "",
                      style: const TextStyle(
                        fontSize: 11,
                      )),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      // TornStats spy card
      // Build display name: show "Player [ID]" if name is null/empty/Player, otherwise "Name [ID]"
      String displayName;
      final bool hasValidName = spy.playerName != null && spy.playerName!.isNotEmpty && spy.playerName != 'Player';
      final bool hasValidId = spy.playerId != null && spy.playerId!.isNotEmpty;

      if (hasValidName && hasValidId) {
        // Show name with ID in brackets
        displayName = '${spy.playerName} [${spy.playerId}]';
      } else if (hasValidName) {
        // Show only name (no ID available)
        displayName = spy.playerName!;
      } else if (hasValidId) {
        // Show "Player [ID]" for null/empty/Player names
        displayName = 'Player [${spy.playerId}]';
      } else {
        // Fallback (shouldn't happen due to filtering)
        displayName = 'Player';
      }

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "STR: ${spy.strength == -1 ? '??' : formatBigNumbers(spy.strength!)}",
                    style: const TextStyle(
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "DEF: ${spy.defense == -1 ? '??' : formatBigNumbers(spy.defense!)}",
                    style: const TextStyle(
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "SPD: ${spy.speed == -1 ? '??' : formatBigNumbers(spy.speed!)}",
                    style: const TextStyle(
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "DEX: ${spy.dexterity == -1 ? '??' : formatBigNumbers(spy.dexterity!)}",
                    style: const TextStyle(
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "TOTAL: ${spy.total == -1 ? '??' : formatBigNumbers(spy.total!)}",
                    style: const TextStyle(
                      fontSize: 11,
                    ),
                  ),
                  Text(spy.total != -1 ? _spyController.statsOld(spy.timestamp) : "",
                      style: const TextStyle(
                        fontSize: 11,
                      )),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }
}
