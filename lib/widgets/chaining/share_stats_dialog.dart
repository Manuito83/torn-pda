import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:torn_pda/providers/war_controller.dart';

class ShareStatsDialog extends StatefulWidget {
  ShareStatsDialog();

  @override
  ShareStatsDialogState createState() => ShareStatsDialogState();
}

class ShareStatsDialogState extends State<ShareStatsDialog> {
  final WarController _w = Get.find<WarController>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Share stats'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                _w.shareStats(context);
              },
              child: const Text("Share"),
            ),
            ElevatedButton(
              onPressed: () {
                _w.generateCSV(context);
              },
              child: const Text("Generate CSV"),
            ),
            const Padding(
              padding: EdgeInsets.all(5.0),
              child: Divider(),
            ),
            const Text("OPTIONS", style: TextStyle(fontSize: 10)),
            SwitchListTile(
              title: const Text(
                'Include hidden targets',
                style: TextStyle(fontSize: 13),
              ),
              value: _w.statsShareIncludeHiddenTargets,
              onChanged: (bool value) {
                setState(() {
                  _w.statsShareIncludeHiddenTargets = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text(
                'Show only totals',
                style: TextStyle(fontSize: 13),
              ),
              value: _w.statsShareShowOnlyTotals,
              onChanged: (bool value) {
                setState(() {
                  _w.statsShareShowOnlyTotals = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text(
                'Show estimates if spied stats are not available',
                style: TextStyle(fontSize: 13),
              ),
              value: _w.statsShareShowEstimatesIfNoSpyAvailable,
              onChanged: (bool value) {
                setState(() {
                  _w.statsShareShowEstimatesIfNoSpyAvailable = value;
                });
              },
            ),
            SwitchListTile(
              title: const Text(
                'Include targets with no stats available',
                style: TextStyle(fontSize: 13),
              ),
              value: _w.statsShareIncludeTargetsWithNoStatsAvailable,
              onChanged: (bool value) {
                setState(() {
                  _w.statsShareIncludeTargetsWithNoStatsAvailable = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Close'),
        ),
      ],
    );
  }
}
