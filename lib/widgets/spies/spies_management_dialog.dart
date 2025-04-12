// Flutter imports:
import 'dart:developer';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/yata/yata_spy_model.dart';
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

  bool _fetchActive = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      contentPadding: EdgeInsets.all(0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      content: FutureBuilder(
        future: Future.delayed(Duration(milliseconds: 500)),
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
          Text(
            "SPIES MANAGEMENT",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Text(
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
                child: Padding(
                  padding: const EdgeInsets.only(left: 15, right: 15),
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
                    Colors.black.withOpacity(0.5),
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
          SizedBox(height: 10),
          Text(
            lastUpdated,
            style: TextStyle(
              fontSize: 12,
              color: spiesUpdateColor,
            ),
          ),
          SizedBox(height: 10),
          Center(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                elevation: 2,
                side: const BorderSide(
                  width: 2.0,
                  color: Colors.blueGrey,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
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
          SizedBox(height: 10),
          Flexible(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
              child: _spiesList(),
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
                  Text(
                    "(time limit is 2 minutes)",
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  )
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(30),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(30),
            child: Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }

  Widget _spiesList() {
    final spiesCards = <Card>[];

    try {
      if (_spyController.spiesSource == SpiesSource.yata) {
        List<YataSpyModel> sortedListOfSpies = List.from(_spyController.yataSpies)
          ..sort((a, b) => a.targetName!.trim().compareTo(b.targetName!.trim()));

        for (var spy in sortedListOfSpies) {
          spiesCards.add(
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spy.targetName!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "STR: ${spy.strength == -1 ? '??' : formatBigNumbers(spy.strength!)}",
                          style: TextStyle(
                            fontSize: 11,
                          ),
                        ),
                        Text(spy.strength != -1 ? _spyController.statsOld(spy.strengthTimestamp) : "",
                            style: TextStyle(
                              fontSize: 11,
                            )),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "DEF: ${spy.defense == -1 ? '??' : formatBigNumbers(spy.defense!)}",
                          style: TextStyle(
                            fontSize: 11,
                          ),
                        ),
                        Text(spy.defense != -1 ? _spyController.statsOld(spy.defenseTimestamp) : "",
                            style: TextStyle(
                              fontSize: 11,
                            )),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "SPD: ${spy.speed == -1 ? '??' : formatBigNumbers(spy.speed!)}",
                          style: TextStyle(
                            fontSize: 11,
                          ),
                        ),
                        Text(spy.speed != -1 ? _spyController.statsOld(spy.speedTimestamp) : "",
                            style: TextStyle(
                              fontSize: 11,
                            )),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "DEX: ${spy.dexterity == -1 ? '??' : formatBigNumbers(spy.dexterity!)}",
                          style: TextStyle(
                            fontSize: 11,
                          ),
                        ),
                        Text(spy.dexterity != -1 ? _spyController.statsOld(spy.dexterityTimestamp) : "",
                            style: TextStyle(
                              fontSize: 11,
                            )),
                      ],
                    ),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "TOTAL: ${spy.total == -1 ? '??' : formatBigNumbers(spy.total!)}",
                          style: TextStyle(
                            fontSize: 11,
                          ),
                        ),
                        Text(spy.total != -1 ? _spyController.statsOld(spy.totalTimestamp) : "",
                            style: TextStyle(
                              fontSize: 11,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      } else {
        final sortedListOfSpies = List.from(_spyController.tornStatsSpies.spies)
          ..sort((a, b) => a.playerName!.trim().compareTo(b.playerName!.trim()));

        for (var spy in sortedListOfSpies) {
          spiesCards.add(
            Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spy.playerName!,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "STR: ${spy.strength == -1 ? '??' : formatBigNumbers(spy.strength!)}",
                          style: TextStyle(
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
                          style: TextStyle(
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
                          style: TextStyle(
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
                          style: TextStyle(
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "TOTAL: ${spy.total == -1 ? '??' : formatBigNumbers(spy.total!)}",
                          style: TextStyle(
                            fontSize: 11,
                          ),
                        ),
                        Text(spy.total != -1 ? _spyController.statsOld(spy.timestamp) : "",
                            style: TextStyle(
                              fontSize: 11,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        }
      }

      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Found ${spiesCards.length} spies",
            style: TextStyle(
              fontSize: 12,
            ),
          ),
          SizedBox(height: 6),
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
                itemCount: spiesCards.length,
                itemBuilder: (context, index) {
                  return spiesCards[index];
                },
              ),
            ),
          ),
        ],
      );
    } catch (e) {
      return Padding(
        padding: const EdgeInsets.only(top: 20),
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
}
