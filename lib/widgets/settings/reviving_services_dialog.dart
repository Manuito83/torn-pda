// Flutter imports:
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:torn_pda/providers/war_controller.dart';

class RevivingServicesDialog extends StatefulWidget {
  @override
  RevivingServicesDialogState createState() => RevivingServicesDialogState();
}

class RevivingServicesDialogState extends State<RevivingServicesDialog> {
  final WarController _w = Get.find<WarController>();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Reviving services"),
      content: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              "Choose which reviving services you might want to use. "
              "If enabled, when you are in hospital you'll have the option to call "
              "one of their revivers from several places (e.g. Profile and Chaining sections).",
              style: TextStyle(
                fontSize: 12,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Flexible(
                    child: Text(
                      "Nuke Reviving Services",
                      style: TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Switch(
                    value: _w.nukeReviveActive,
                    onChanged: (value) {
                      setState(() {
                        _w.nukeReviveActive = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Flexible(
                    child: Text(
                      "UHC Reviving Services",
                      style: TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Switch(
                    value: _w.uhcReviveActive,
                    onChanged: (value) {
                      setState(() {
                        _w.uhcReviveActive = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Flexible(
                    child: Text(
                      "HeLa Reviving Services",
                      style: TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Switch(
                    value: _w.helaReviveActive,
                    onChanged: (value) {
                      setState(() {
                        _w.helaReviveActive = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Flexible(
                    child: Text(
                      "WTF Reviving Services",
                      style: TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Switch(
                    value: _w.wtfReviveActive,
                    onChanged: (value) {
                      setState(() {
                        _w.wtfReviveActive = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Flexible(
                    child: Text(
                      "Midnight X Reviving Services",
                      style: TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Switch(
                    value: _w.midnightXReviveActive,
                    onChanged: (value) {
                      setState(() {
                        _w.midnightXReviveActive = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Flexible(
                    child: Text(
                      "The Wolverines Reviving Services",
                      style: TextStyle(
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Switch(
                    value: _w.wolverinesReviveActive,
                    onChanged: (value) {
                      setState(() {
                        _w.wolverinesReviveActive = value;
                      });
                    },
                    activeTrackColor: Colors.lightGreenAccent,
                    activeThumbColor: Colors.green,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              "NOTE: Torn PDA is not affiliated to any of these services in any form",
              style: TextStyle(
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 15),
          child: TextButton(
            child: const Text("Close"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        )
      ],
    );
  }
}
