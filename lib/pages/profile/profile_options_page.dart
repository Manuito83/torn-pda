import 'package:flutter/material.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class ProfileOptionsReturn {
  bool nukeReviveEnabled;
}

class ProfileOptionsPage extends StatefulWidget {
  @override
  _ProfileOptionsPageState createState() => _ProfileOptionsPageState();
}

class _ProfileOptionsPageState extends State<ProfileOptionsPage> {
  bool _nukeReviveEnabled = true;

  Future _preferencesLoaded;

  @override
  void initState() {
    super.initState();
    _preferencesLoaded = _restorePreferences();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _willPopCallback,
      child: Scaffold(
        appBar: AppBar(
          title: Text("Profile Options"),
          leading: new IconButton(
            icon: new Icon(Icons.arrow_back),
            onPressed: () {
              _willPopCallback();
            },
          ),
        ),
        body: Builder(
          builder: (BuildContext context) {
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
              child: FutureBuilder(
                future: _preferencesLoaded,
                builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                  if (snapshot.connectionState == ConnectionState.done) {
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text("Use Nuke Reviving Services"),
                                Switch(
                                  value: _nukeReviveEnabled,
                                  onChanged: (value) {
                                    SharedPreferencesModel().setUseNukeRevive(value);
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
                            child: Text(
                              'If active, when you are in hospital you\'ll have the option to call '
                              'a reviver from Central Hospital. NOTE: this is an external '
                              'service not affiliated to Torn PDA. It\'s here so that it is '
                              'more accessible!',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                          SizedBox(height: 50),
                        ],
                      ),
                    );
                  } else {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Future _restorePreferences() async {
    var useNuke = await SharedPreferencesModel().getUseNukeRevive();

    setState(() {
      _nukeReviveEnabled = useNuke;
    });
  }

  Future<bool> _willPopCallback() async {
    Navigator.of(context).pop(
      ProfileOptionsReturn()..nukeReviveEnabled = _nukeReviveEnabled,
    );
    return true;
  }
}
