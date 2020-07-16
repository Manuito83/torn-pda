import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:torn_pda/models/firebase_user_model.dart';
import 'package:http/http.dart' as http;
import 'package:torn_pda/models/loot/loot_model.dart';
import '../main.dart';

class LootPage extends StatefulWidget {
  @override
  _LootPageState createState() => _LootPageState();
}

class _LootPageState extends State<LootPage> {
  Map<String, LootModel> _lootMap;
  Future _getLootInfoFromYata;
  bool _apiSuccess = false;

  @override
  void initState() {
    super.initState();
    _getLootInfoFromYata = _fetchYataApi();
    analytics
        .logEvent(name: 'section_changed', parameters: {'section': 'loot'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Loot'),
        leading: new IconButton(
          icon: new Icon(Icons.menu),
          onPressed: () {
            final ScaffoldState scaffoldState =
                context.findRootAncestorStateOfType();
            scaffoldState.openDrawer();
          },
        ),
        /*
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.info_outline,
            ),
            onPressed: () {

            },
          ),
        ],
        */
      ),
      body: FutureBuilder(
          future: _getLootInfoFromYata,
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              if (_apiSuccess) {
                return Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(5),
                      child: _returnNpcs(),
                    ),
                  ],
                );
              } else {
                return _connectError();
              }
            } else {
              return Center(child: CircularProgressIndicator());
            }
          }),
    );
  }

  Widget _connectError() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'There was an error contacting with Yata!',
            style: TextStyle(
              color: Colors.red,
              fontWeight: FontWeight.bold
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Please try again later.',
          ),
          SizedBox(height: 20),
          Text('If this problem reoccurs, please let us know!'),
        ],
      ),
    );
  }

  Widget _returnNpcs() {
    var npcBoxes = List<Widget>();


    var npcModels = List<LootModel>();
    for (var model in _lootMap.values) {
      npcModels.add(model);
    }

    for (var npc in npcModels) {
      var timings = List<Timing>();
      npc.timings.forEach((key, value) {
        timings.add(value);
      });

      npcBoxes.add(
        Card(
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(Icons.people),
                SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${npc.name}'),
                      SizedBox(height: 10),
                      Text('Level ${npc.levels.current}'),
                      Text('Level ${npc.levels.next} in ${timings[npc.levels.next + 1].due}')
                    ],
                  ),
                ),
                Icon(MdiIcons.knife),
              ],
            ),
          ),
        )
      );
    }

    Widget npcWidget = Column(children: npcBoxes);
    return npcWidget;

  }

  Future _fetchYataApi() async {
    try {
      // Database API
      String url = 'https://yata.alwaysdata.net/loot/timings/';
      final response = await http.get(url).timeout(Duration(seconds: 10));
      if (response.statusCode == 200) {
        _lootMap = lootModelFromJson(response.body);
        _lootMap.length >= 1 ? _apiSuccess = true : _apiSuccess = false;
      } else {
        _apiSuccess = false;
      }
    } catch (e) {
      _apiSuccess = false;
    }
  }
}
