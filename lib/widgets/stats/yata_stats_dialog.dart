import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/chaining/yata/yata_stats_response_model.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/utils/external/yata_stats_comm.dart';
import 'package:torn_pda/utils/number_formatter.dart';
import 'package:torn_pda/utils/timestamp_ago.dart';
import 'package:torn_pda/widgets/stats/stats_dialog.dart';

class YataStatsDialog extends StatefulWidget {
  YataStatsDialog({
    required this.yataStatsPayload,
    required this.themeProvider,
  });

  final YataStatsPayload yataStatsPayload;
  final ThemeProvider themeProvider;

  @override
  State<YataStatsDialog> createState() => _YataStatsDialogState();
}

class _YataStatsDialogState extends State<YataStatsDialog> {
  final UserController _u = Get.put(UserController());
  late Future yataDetailsFetched;

  @override
  void initState() {
    super.initState();
    yataDetailsFetched = _fetchDetails();
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
                    "YATA STATS ESTIMATE",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            FutureBuilder(
              future: yataDetailsFetched,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.data is YataStatsResponse) {
                    return _mainYataResponseWidget(snapshot.data as YataStatsResponse);
                  }
                  return Text("Error fetching from YATA");
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 100),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Text("Fetching from YATA"),
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

  Widget _mainYataResponseWidget(YataStatsResponse yataResponse) {
    if (yataResponse.success) {
      if (yataResponse.data == null) return Text("Error: missing data!");

      YataStatsData? statsData = yataResponse.data!.data[widget.yataStatsPayload.targetId.toString()];
      if (statsData != null) {
        String ts = readTimestamp(statsData.timestamp ?? 0) == "0" ? "unkown" : readTimestamp(statsData.timestamp!);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text("Total: ", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(statsData.total != null ? formatBigNumbers(statsData.total!) : 'unknown'),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text("Score: ", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(statsData.score != null ? formatBigNumbers(statsData.score!) : 'unknown'),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text("Type: ", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(statsData.type ?? 'unknown'),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text("Skewness: ", style: TextStyle(fontWeight: FontWeight.bold)),
                Text("${statsData.skewness ?? 'unknown'}"),
              ],
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text("Updated: ", style: TextStyle(fontWeight: FontWeight.bold)),
                Text(ts),
              ],
            ),
          ],
        );
      }
    } else {
      if (yataResponse.error?.error != null) {
        return Center(
          child: Text(
            yataResponse.error!.error!,
            style: TextStyle(
              color: Colors.red,
            ),
          ),
        );
      }
    }

    return Center(
      child: Text(
        "Error: missing data!",
        style: TextStyle(
          color: Colors.red,
        ),
      ),
    );
  }

  Future<YataStatsResponse?> _fetchDetails() async {
    final yataStatsResponse = await YataStatsComm.getYataStats(
      targetId: widget.yataStatsPayload.targetId.toString(),
      ownApiKey: _u.alternativeTSCKey,
    );
    return yataStatsResponse;
  }
}
