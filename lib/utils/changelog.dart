import 'package:flutter/material.dart';

class ChangeLogItem {
  String version;
  var features = List<String>();
}

class ChangeLog extends StatefulWidget {
  @override
  _ChangeLogState createState() => _ChangeLogState();
}

class _ChangeLogState extends State<ChangeLog> {
  var _changeLogItems = Map<String, List<String>>();

  @override
  void initState() {
    super.initState();
    _createItems();
  }

  void _createItems() {
    var itemList = List<ChangeLogItem>();

    // VERSION 1.4.0
    var v1_4_0 = ChangeLogItem();
    v1_4_0.version = 'Torn PDA v1.4.0';
    String feat1_4_0_1 = "New 'About' section";
    String feat1_4_0_2 = "You can now choose between 12h/24h time systems & "
        "local time (LT) or Torn City TIme (TCT) time zones";
    String feat1_4_0_3 = "Added travel progress bar to the Travel section";
    String feat1_4_0_4 = "Fixed an issue causing user settings preferences not "
        "to be applied after restarting the application";
    String feat1_4_0_5 = "Fixed several issues reported in previous version "
        "(thanks Kivou + JDTech)";
    v1_4_0.features.add(feat1_4_0_1);
    v1_4_0.features.add(feat1_4_0_2);
    v1_4_0.features.add(feat1_4_0_3);
    v1_4_0.features.add(feat1_4_0_4);
    v1_4_0.features.add(feat1_4_0_5);

    // VERSION 1.3.0
    var v1_3_0 = ChangeLogItem();
    v1_3_0.version = 'Torn PDA v1.3.0';
    String feat1_3_0_1 = "New Friends section, with quick access to player "
        "details and in-game actions. Personal notes and "
        "backup functionality is also included";
    String feat1_3_0_2 = "New notifications (manually activated) added in the "
        "Profile section for energy, nerve, life and "
        "all cooldowns";
    String feat1_3_0_3 = "Energy and nerve had their colors corrected in the "
        "Profile section to adapt to game colors";
    String feat1_3_0_4 = "Other bug fixes and corrections thanks to "
        "players suggestions";
    v1_3_0.features.add(feat1_3_0_1);
    v1_3_0.features.add(feat1_3_0_2);
    v1_3_0.features.add(feat1_3_0_3);
    v1_3_0.features.add(feat1_3_0_4);

    // NEED TO ADD HERE!
    itemList.add(v1_4_0);
    itemList.add(v1_3_0);

    for (var i = 0; i < itemList.length; i++) {
      _changeLogItems.putIfAbsent(
          itemList[i].version, () => itemList[i].features);
    }
  }

  var _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Scrollbar(
                  controller: _scrollController,
                  isAlwaysShown: true,
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    child: Container(
                      padding: EdgeInsets.fromLTRB(15, 25, 15, 15),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _items(),
                      ),
                    ),
                  ),
                ),
              ),
              Divider(
                thickness: 1,
                color: Colors.blueGrey,
              ),
              Padding(
                padding: EdgeInsets.all(5),
                child: RaisedButton(
                  child: Text(
                    'Great!',
                    style: TextStyle(
                      fontSize: 15,
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _items() {
    var itemList = List<Widget>();
    var itemNumber = 1;

    itemList.add(
      Padding(
        padding: const EdgeInsets.only(bottom: 25),
        child: Text("CHANGELOG"),
      ),
    );

    for (var entry in _changeLogItems.entries) {
      if (itemNumber > 1) {
        itemList.add(
          Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 24,
              horizontal: 50,
            ),
            child: Divider(
              thickness: 1,
              color: Colors.blueGrey,
            ),
          ),
        );
      }
      itemList.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Text(
            entry.key,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
      for (var feat in entry.value) {
        itemList.add(
          Padding(
            padding: EdgeInsets.fromLTRB(10, 10, 10, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                _factionIcon(),
                Padding(padding: EdgeInsets.only(right: 12)),
                Flexible(
                  child: Text(
                    feat,
                  ),
                ),
              ],
            ),
          ),
        );
      }
      itemNumber++;
    }
    return itemList;
  }

  Widget _factionIcon() {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: SizedBox(
        height: 18,
        width: 18,
        child: ImageIcon(
          AssetImage('images/icons/faction.png'),
        ),
      ),
    );
  }
}
