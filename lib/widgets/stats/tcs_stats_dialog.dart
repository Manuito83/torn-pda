import 'package:easy_rich_text/easy_rich_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/tsc/tsc_response_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/external/tsc_comm.dart';
import 'package:torn_pda/utils/number_formatter.dart';
import 'package:torn_pda/widgets/stats/stats_dialog.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

class TSCStatsDialog extends StatefulWidget {
  TSCStatsDialog({
    required this.tscStatsPayload,
    required this.themeProvider,
    required this.callBackToDisableTSCtab,
  });

  final TSCStatsPayload tscStatsPayload;
  final ThemeProvider themeProvider;
  final Function callBackToDisableTSCtab;

  @override
  State<TSCStatsDialog> createState() => _TSCStatsDialogState();
}

class _TSCStatsDialogState extends State<TSCStatsDialog> {
  final UserController _u = Get.put(UserController());
  late Future tscDetailsFetched;

  bool tscPreEnabled = false;

  @override
  void initState() {
    super.initState();
    tscDetailsFetched = _fetchDetails();

    // DEBUG TO BRING TSC TO PRE-ENABLED
    //WidgetsBinding.instance.addPostFrameCallback((_) => context.read<SettingsProvider>().tscEnabledStatus = -1);
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
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Text(
                    "TORN SPIES CENTRAL",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            FutureBuilder(
              future: tscDetailsFetched,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.data is TscResponse) {
                    final tsc = snapshot.data as TscResponse;
                    if (tsc.success && tsc.spy != null) {
                      return _mainTSCResponseWidget(tsc);
                    }

                    String error = tsc.message;
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: tsc.code == 3 ? 50 : 100),
                        child: Column(
                          children: [
                            Text(
                              "Error: $error",
                              style: TextStyle(color: Colors.red, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                            if (tsc.code == 3)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                                child: EasyRichText(
                                  "Make sure you have registered as an user in TSC's Discord server if you haven't "
                                  "done so yet, as it is needed in order to fetch data from the service.\n\nIf you "
                                  "have, make sure you are using the correct key or that an alternative key has been "
                                  "provided in Torn PDA Settings",
                                  patternList: [
                                    EasyRichTextPattern(
                                      targetString: "TSC's Discord server",
                                      style: TextStyle(
                                        decoration: TextDecoration.underline,
                                        color: Colors.blue[400],
                                      ),
                                      recognizer: TapGestureRecognizer()
                                        ..onTap = () async {
                                          Navigator.of(context).pop();
                                          const url = 'https://discord.gg/eegQhTUqPS';
                                          await context.read<WebViewProvider>().openBrowserPreference(
                                                context: context,
                                                url: url,
                                                browserTapType: BrowserTapType.short,
                                              );
                                        },
                                    ),
                                  ],
                                  defaultStyle: TextStyle(
                                    fontSize: 14,
                                    color: widget.themeProvider.mainText,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  } else if (snapshot.data == null && tscPreEnabled) {
                    return Column(
                      children: [
                        EasyRichText(
                          "The Torn Spies Central implementation in Torn PDA is part of a bigger stats estimation algorithm "
                          "developed by Mavri, which you can review in its own forum thread.\n\n"
                          "You will need to register as an user in TSC's Dicord server if you haven't done so yet\n\n"
                          "IMPORTANT: please be aware that by making use of TSC in Torn PDA, your API Key WILL be shared "
                          "with TSC.\n\nAs with other service providers, you can configure an alternative API Key in Torn "
                          "PDA Settings. A Limited key is needed.",
                          patternList: [
                            EasyRichTextPattern(
                              targetString: 'Mavri',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                color: Colors.blue[400],
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () async {
                                  Navigator.of(context).pop();
                                  const url = 'https://www.torn.com/profiles.php?XID=2402357';
                                  await context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.short,
                                      );
                                },
                            ),
                            EasyRichTextPattern(
                              targetString: 'forum thread',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                color: Colors.blue[400],
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () async {
                                  Navigator.of(context).pop();
                                  const url = 'https://www.torn.com/forums.php#/p=threads&f=67&t=16290287&b=0&a=0';
                                  await context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.short,
                                      );
                                },
                            ),
                            EasyRichTextPattern(
                              targetString: "TSC's Dicord server",
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                color: Colors.blue[400],
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () async {
                                  Navigator.of(context).pop();
                                  const url = 'https://discord.gg/eegQhTUqPS';
                                  await context.read<WebViewProvider>().openBrowserPreference(
                                        context: context,
                                        url: url,
                                        browserTapType: BrowserTapType.short,
                                      );
                                },
                            ),
                          ],
                          defaultStyle: TextStyle(
                            fontSize: 14,
                            color: widget.themeProvider.mainText,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              TextButton(
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  side: BorderSide(
                                    color: widget.themeProvider.mainText!,
                                    width: 2,
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    context.read<SettingsProvider>().tscEnabledStatus = 1;
                                    tscPreEnabled = false;
                                    tscDetailsFetched = _fetchDetails();
                                  });
                                },
                                child: Text(" Enable "),
                              ),
                              SizedBox(width: 30),
                              TextButton(
                                style: TextButton.styleFrom(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  side: BorderSide(
                                    color: widget.themeProvider.mainText!,
                                    width: 2,
                                  ),
                                ),
                                onPressed: () {
                                  context.read<SettingsProvider>().tscEnabledStatus = 0;
                                  tscPreEnabled = false;
                                  widget.callBackToDisableTSCtab();
                                },
                                child: Text(" Disable "),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                  return Text("Error fetching from TSC");
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text("Fetching from TSC"),
                      Padding(
                        padding: const EdgeInsets.only(top: 20),
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

  Widget _mainTSCResponseWidget(TscResponse tsc) {
    // Estimate is always present, but less exact. It's updated at least once a week.
    // Interval is more precsise since it comes from spyes
    //  1.- If interval [lastUpdated] is not null, we'll show it
    //     1a.- If it's less than 45 days, we'll show it and cross overr the estimate
    //     1b.- If it's older than 45 days, we'll give a warning that it might be old and don't cross over estimage
    //  2.- If interval [lastUpdated] is null, we'll show the estimate

    bool? intervalIsNew;
    String minString = "ERROR";
    String maxString = "ERROR";
    String bsString = "";
    String ff = "";
    String dateString = "";
    bool intervalExists = tsc.spy!.statInterval.lastUpdated != null;

    if (intervalExists) {
      try {
        DateTime parsedDate = DateTime.parse(tsc.spy!.statInterval.lastUpdated!);
        intervalIsNew = DateTime.now().difference(parsedDate).inDays < 45;
        dateString = DateFormat('dd MMM yyyy').format(parsedDate);
      } on FormatException {
        dateString = "ERROR";
      }

      int? min = int.tryParse(tsc.spy!.statInterval.min);
      if (min != null) {
        minString = formatBigNumbers(min);
      }

      int? max = int.tryParse(tsc.spy!.statInterval.max);
      if (max != null) {
        maxString = formatBigNumbers(max);
      }

      bsString = formatBigNumbers(tsc.spy!.statInterval.battleScore.floor());

      ff = tsc.spy!.statInterval.fairFight;
    }

    String estimateString = "ERROR";
    int? estimate = int.tryParse(tsc.spy!.estimate.stats);
    if (estimate != null) {
      estimateString = formatBigNumbers(estimate);
    }

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "ESTIMATE",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink[700], fontSize: 16),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 20, top: 10),
            child: Text(
              estimateString,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  decoration: intervalIsNew != null && !intervalIsNew ? TextDecoration.lineThrough : null),
            ),
          ),
          if (intervalExists)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 20),
                Text(
                  "SPIED STAT RANGE",
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink[700], fontSize: 16),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 10),
                  child: Text(
                    "$minString - $maxString",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 10),
                  child: Row(
                    children: [
                      Text(
                        "Battle Score: ",
                        style: TextStyle(fontSize: 15),
                      ),
                      Text(
                        bsString,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 10),
                  child: Row(
                    children: [
                      Text(
                        "Fair Fight: ",
                        style: TextStyle(fontSize: 15),
                      ),
                      Text(
                        ff,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 20, top: 10),
                  child: Row(
                    children: [
                      Text(
                        "Date spied: ",
                        style: TextStyle(fontSize: 15),
                      ),
                      Text(
                        dateString,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
        ],
      ),
    );
  }

  Future<TscResponse?> _fetchDetails() async {
    final settingsProvider = context.read<SettingsProvider>();

    // TSC is pre-enabled (never used, but not disabled)
    if (settingsProvider.tscEnabledStatus == -1) {
      tscPreEnabled = true;
      return null;
    }

    final tscResponse = await TSCComm.checkIfUserExists(
      targetId: widget.tscStatsPayload.targetId.toString(),
      ownApiKey: _u.alternativeTSCKey,
    );
    return tscResponse;
  }
}
