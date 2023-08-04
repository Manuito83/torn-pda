// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:torn_pda/utils/shared_prefs.dart';

class RevivingServicesDialog extends StatefulWidget {
  @override
  _RevivingServicesDialogState createState() => _RevivingServicesDialogState();
}

class _RevivingServicesDialogState extends State<RevivingServicesDialog> {
  Future? _preferencesLoaded;
  bool _nukeReviveEnabled = true;
  bool _uhcReviveEnabled = true;
  bool _helaReviveEnabled = true;
  bool _wtfReviveEnabled = true;

  @override
  void initState() {
    super.initState();
    _preferencesLoaded = _restorePreferences();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Reviving services"),
      content: FutureBuilder(
        future: _preferencesLoaded,
        builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.connectionState != ConnectionState.done) return const SizedBox.shrink();
          return SingleChildScrollView(
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
                        value: _nukeReviveEnabled,
                        onChanged: (value) {
                          Prefs().setUseNukeRevive(value);
                          setState(() {
                            _nukeReviveEnabled = value;
                          });
                        },
                        activeTrackColor: Colors.lightGreenAccent,
                        activeColor: Colors.green,
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
                        value: _uhcReviveEnabled,
                        onChanged: (value) {
                          Prefs().setUseUhcRevive(value);
                          setState(() {
                            _uhcReviveEnabled = value;
                          });
                        },
                        activeTrackColor: Colors.lightGreenAccent,
                        activeColor: Colors.green,
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
                        value: _helaReviveEnabled,
                        onChanged: (value) {
                          Prefs().setUseHelaRevive(value);
                          setState(() {
                            _helaReviveEnabled = value;
                          });
                        },
                        activeTrackColor: Colors.lightGreenAccent,
                        activeColor: Colors.green,
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
                        value: _wtfReviveEnabled,
                        onChanged: (value) {
                          Prefs().setUseWtfRevive(value);
                          setState(() {
                            _wtfReviveEnabled = value;
                          });
                        },
                        activeTrackColor: Colors.lightGreenAccent,
                        activeColor: Colors.green,
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
          );
        },
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

  Future _restorePreferences() async {
    final prefs = Prefs();
    final futures = [
      prefs.getUseNukeRevive(),
      prefs.getUseUhcRevive(),
      prefs.getUseHelaRevive(),
      prefs.getUseWtfRevive(),
    ];

    final results = await Future.wait(futures);

    setState(() {
      _nukeReviveEnabled = results[0];
      _uhcReviveEnabled = results[1];
      _helaReviveEnabled = results[2];
      _wtfReviveEnabled = results[3];
    });
  }
}
