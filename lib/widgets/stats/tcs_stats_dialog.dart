import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/chaining/tsc/tsc_response_model.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_controller.dart';
import 'package:torn_pda/utils/external/tsc_comm.dart';
import 'package:torn_pda/widgets/stats/stats_dialog.dart';

class TSCStatsDialog extends StatefulWidget {
  TSCStatsDialog({
    required this.tscStatsPayload,
    required this.themeProvider,
  });

  final TSCStatsPayload tscStatsPayload;
  final ThemeProvider themeProvider;

  @override
  State<TSCStatsDialog> createState() => _TSCStatsDialogState();
}

class _TSCStatsDialogState extends State<TSCStatsDialog> {
  final UserController _u = Get.put(UserController());
  late final Future tscDetailsFetched;

  @override
  void initState() {
    super.initState();
    tscDetailsFetched = _fetchDetails();
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
                    "TORN STATS CENTRAL",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            FutureBuilder(
              future: tscDetailsFetched,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasData) {
                    final tscResponse = snapshot.data as TscResponse;
                    return Column(
                      children: [
                        Text(tscResponse.spy!.estimate.stats),
                      ],
                    );
                  } else {
                    return Text("Error fetching from TSC");
                  }
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

  Future<TscResponse> _fetchDetails() async {
    final tscResponse = await TSCComm.checkIfUserExists(
      targetId: widget.tscStatsPayload.targetId.toString(),
      ownApiKey: _u.alternativeTSCKey,
    );
    return tscResponse;
  }
}
