import 'dart:async';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/chaining/chain_timer.dart';
import 'package:http/http.dart' as http;
import 'package:torn_pda/main.dart';
import 'package:torn_pda/models/chaining/tac/tac_in_model.dart';
import 'package:torn_pda/models/chaining/tac/tac_target_model.dart';
import 'package:torn_pda/models/chaining/tac/tac_filters_model.dart';
import 'package:torn_pda/widgets/chaining/tac/tac_card.dart';
import 'package:expandable/expandable.dart';
import 'package:easy_rich_text/easy_rich_text.dart';
import 'package:torn_pda/widgets/webviews/webview_dialog.dart';
import 'package:torn_pda/widgets/webviews/webview_full.dart';
import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:torn_pda/private/tac_config.dart';

class TacPage extends StatefulWidget {
  final String userKey;

  const TacPage({Key key, @required this.userKey}) : super(key: key);

  @override
  _TacPageState createState() => _TacPageState();
}

class _TacPageState extends State<TacPage> {
  Future _preferencesLoaded;

  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;
  UserDetailsProvider _userProvider;

  TacInModel _tacModel;
  TacFilters _tacFilters;
  bool _apiCall = false;
  bool _getButtonActive = true;

  var difficultyLabel = "";
  var _incorrectPremium = false;

  var _statsMap = {
    0: "Under 2k",
    1: "2k - 25k",
    2: "20k - 250k",
    3: "250k - 2.5M",
    4: "2.5M - 25M",
    5: "20M - 250M",
    6: "Over 200M",
  };

  var _ranksMap = {
    1: "Absolute beginner",
    2: "Beginner",
    3: "Inexperienced",
    4: "Rookie",
    5: "Novice",
    6: "Below Average",
    7: "Average",
    8: "Reasonable",
    9: "Above Average",
    10: "Competent",
    11: "Highly competent",
    12: "Veteran",
    13: "Distinguished",
    14: "Highly distinguished",
    15: "Professional",
    16: "Star",
    17: "Master",
    18: "Outstanding",
    19: "Celebrity",
    20: "Supreme",
    21: "Idolised",
    22: "Champion",
    23: "Heroic",
    24: "Legendary",
    25: "Elite",
    26: "Invincible"
  };

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
    _preferencesLoaded = _restorePreferences();

    analytics.logEvent(name: 'section_changed', parameters: {'section': 'tac'});
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Scaffold(
      drawer: Drawer(),
      appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(),
            )
          : null,
      body: FutureBuilder(
          future: _preferencesLoaded,
          builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () =>
                    FocusScope.of(context).requestFocus(new FocusNode()),
                child: Column(
                  children: <Widget>[
                    SizedBox(height: 5),
                    ChainTimer(
                      userKey: widget.userKey,
                      alwaysDarkBackground: false,
                      chainTimerParent: ChainTimerParent.targets,
                    ),
                    _filtersCard(),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: _optimalWidget(),
                        ),
                        Expanded(
                          child: _getTargetsButton(),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    _incorrectPremium
                        ? Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Text(
                              'NOTE: you requested optimal targets but your account is '
                              'not premium, only showing standard targets!',
                              style: TextStyle(
                                color: Colors.orange[900],
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          )
                        : SizedBox.shrink(),
                    SizedBox(height: 10),
                    _apiCall
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.only(top: 50),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : Flexible(child: _targetsListView()),
                  ],
                ),
              );
            } else {
              return Center(child: CircularProgressIndicator());
            }
          }),
    );
  }

  Card _filtersCard() {
    return Card(
      child: ExpandablePanel(
        //controller: _controller,
        header: Padding(
          padding: const EdgeInsets.fromLTRB(25, 10, 25, 0),
          child: Row(
            children: [
              Text(
                'SETTINGS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        collapsed: Padding(
          padding: const EdgeInsets.fromLTRB(25, 0, 25, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Min. level: ${_tacFilters.minLevel}',
                      style: TextStyle(fontSize: 12)),
                  Text('Max. level: ${_tacFilters.maxLevel}',
                      style: TextStyle(fontSize: 12)),
                  Text('Max. life: ${_tacFilters.maxLife}',
                      style: TextStyle(fontSize: 12)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Battle stats: ${_statsMap[_tacFilters.battleStats]}',
                      style: TextStyle(fontSize: 12)),
                  Text('${_ranksMap[_tacFilters.rank]}',
                      style: TextStyle(fontSize: 12)),
                ],
              ),
            ],
          ),
        ),
        expanded: Padding(
          padding: const EdgeInsets.fromLTRB(30, 0, 5, 0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(child: Text('Minimum level')),
                  Row(
                    children: [
                      Row(
                        children: [
                          Text(_tacFilters.minLevel.toString()),
                          SizedBox(
                            width: 175,
                            child: Slider(
                              value: _tacFilters.minLevel.toDouble(),
                              min: 1,
                              max: 100,
                              label: _tacFilters.minLevel.toString(),
                              divisions: 99,
                              onChanged: (double newValue) {
                                if (newValue <= _tacFilters.maxLevel) {
                                  setState(() {
                                    _tacFilters.minLevel = newValue.round();
                                  });
                                }
                              },
                              onChangeEnd: (double newValue) {
                                _saveFilters();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Maximum level'),
                  Row(
                    children: [
                      Text(_tacFilters.maxLevel.toString()),
                      SizedBox(
                        width: 175,
                        child: Slider(
                          value: _tacFilters.maxLevel.toDouble(),
                          min: 1,
                          max: 100,
                          label: _tacFilters.maxLevel.toString(),
                          divisions: 99,
                          onChanged: (double newValue) {
                            if (newValue >= _tacFilters.minLevel) {
                              setState(() {
                                _tacFilters.maxLevel = newValue.round();
                              });
                            }
                          },
                          onChangeEnd: (double newValue) {
                            _saveFilters();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Maximum life'),
                  Row(
                    children: [
                      Text(_tacFilters.maxLife.toString()),
                      SizedBox(
                        width: 175,
                        child: Slider(
                          value: _tacFilters.maxLife.toDouble(),
                          min: 800,
                          max: 9900,
                          label: _tacFilters.maxLife.toString(),
                          divisions: 91,
                          onChanged: (double newValue) {
                            setState(() {
                              _tacFilters.maxLife = newValue.round();
                            });
                          },
                          onChangeEnd: (double newValue) {
                            _saveFilters();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Rank'),
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: _rankDropdown(),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Battle stats'),
                  Padding(
                    padding: const EdgeInsets.only(right: 20),
                    child: _battleStatsDropdown(),
                  ),
                ],
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getTargetsButton() {
    return Column(
      children: [
        RaisedButton(
          child: Text('Get targets'),
          onPressed: _getButtonActive
              ? () {
                  setState(() {
                    _getButtonActive = false;
                  });

                  _fetchTac();

                  if (mounted) {
                    Future.delayed(Duration(seconds: 2), () {}).then((value) {
                      setState(() {
                        _getButtonActive = true;
                      });
                    });
                  }
                }
              : null,
        ),
      ],
    );
  }

  Widget _optimalWidget() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Checkbox(
              value: _tacFilters.useOptimal,
              onChanged: (value) {
                setState(() {
                  _tacFilters.useOptimal = value;
                });
                _saveFilters();
              },
            ),
            Text(
              "OPTIMAL TARGETS",
              style: TextStyle(fontSize: 12),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: GestureDetector(
                onTap: () async {
                  await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return _optimalExplanationDialog();
                    },
                  );
                },
                child: Icon(
                  Icons.info_outline,
                  size: 18,
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          width: 200,
          child: SizedBox(
            width: 150,
            height: 20,
            child: Slider(
              value: _tacFilters.optimalLevel.toDouble(),
              min: 1,
              max: 5,
              label: difficultyLabel,
              divisions: 4,
              onChanged: _tacFilters.useOptimal
                  ? (double value) {
                      setState(() {
                        switch (value.round()) {
                          case 1:
                            difficultyLabel = "Easy";
                            break;
                          case 2:
                            difficultyLabel = "Easy-Moderate";
                            break;
                          case 3:
                            difficultyLabel = "Moderate";
                            break;
                          case 4:
                            difficultyLabel = "Moderate-Hard";
                            break;
                          case 5:
                            difficultyLabel = "Hard";
                            break;
                        }
                        _tacFilters.optimalLevel = value.round();
                      });
                    }
                  : null,
              onChangeEnd: (double newValue) {
                _saveFilters();
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _rankDropdown() {
    var dropDownList = <DropdownMenuItem>[];

    _ranksMap.forEach((key, value) {
      dropDownList.add(
        DropdownMenuItem(
          value: key,
          child: SizedBox(
            width: 150,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    });

    return DropdownButton<dynamic>(
      value: _tacFilters.rank,
      items: dropDownList,
      onChanged: (value) {
        setState(() {
          _tacFilters.rank = value;
        });
        _saveFilters();
      },
    );
  }

  Widget _battleStatsDropdown() {
    var dropDownList = <DropdownMenuItem>[];

    _statsMap.forEach((key, value) {
      dropDownList.add(
        DropdownMenuItem(
          value: key,
          child: SizedBox(
            width: 150,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      );
    });

    return DropdownButton<dynamic>(
      value: _tacFilters.battleStats,
      items: dropDownList,
      onChanged: (value) {
        setState(() {
          _tacFilters.battleStats = value;
        });
        _saveFilters();
      },
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      brightness: Brightness.dark,
      title: Text("Torn Attack Central"),
      leading: new IconButton(
        icon: new Icon(Icons.menu),
        onPressed: () {
          final ScaffoldState scaffoldState =
              context.findRootAncestorStateOfType();
          scaffoldState.openDrawer();
        },
      ),
      actions: <Widget>[
        IconButton(
          icon: Icon(Icons.info_outline_rounded),
          onPressed: () async {
            await showDialog(
              context: context,
              builder: (BuildContext context) {
                return _tacExplanationDialog();
              },
            );
          },
        )
      ],
    );
  }

  Widget _targetsListView() {
    var targetsList = <TacTarget>[];
    if (_tacModel != null) {
      _tacModel.targets.forEach((targetId, value) {
        var thisTacModel = TacTarget();
        thisTacModel
          ..id = targetId
          ..optimal = value.optimal
          ..username = value.username
          ..rank = value.rank
          ..battleStats = value.battlestats
          ..estimatedStats = value.estimatedstats
          ..userLevel = value.userlevel;

        targetsList.add(thisTacModel);
      });
    }

    var targetCards = <TacCard>[];
    for (var model in targetsList) {
      targetCards.add(
        TacCard(
          target: model,
          targetList: targetsList,
        ),
      );
    }

    return ListView(children: targetCards);
  }

  Future _fetchTac() async {
    setState(() {
      _apiCall = true;
    });

    var optimal = 0;
    if (_tacFilters.useOptimal) optimal = 1;

    var url = 'https://tornattackcentral.eu/pdaintegration.php?'
        'password=${TacConfig.password}'
        '&userid=${_userProvider.basic.playerId}'
        '&optimallevel=${_tacFilters.optimalLevel}'
        '&optimal=$optimal'
        '&rank=${_tacFilters.rank}'
        '&bslevel=${_tacFilters.battleStats}'
        '&minlevel=${_tacFilters.minLevel}'
        '&maxlevel=${_tacFilters.maxLevel}'
        '&maxlife=${_tacFilters.maxLife}'
        '&strength=${_userProvider.basic.strength}'
        '&speed=${_userProvider.basic.speed}'
        '&dexterity=${_userProvider.basic.dexterity}'
        '&defense=${_userProvider.basic.defense}';

    try {
      var response = await http.get(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8'
        },
      );

      if (response.statusCode == 200) {
        // Fix TAC json encoding
        var model = tacModelFromJson(response.body);
        if (model is TacInModel) {
          setState(() {
            // Optimal targets are obtained only for premium users when the
            // _optimal checkbox is ticked. In this case, we get battle stats
            // instead of estimated stats (they are two different parameters)
            bool optimalTargets = false;
            if (_tacFilters.useOptimal && model.premium == 1) {
              optimalTargets = true;
            }
            model.targets.forEach((key, value) {
              value.optimal = optimalTargets;
            });

            if (model.targets.length > 0) {
              var time = 3;

              var resultString = 'Retrieved ${model.targets.length} '
                  'targets from Torn Attack Central!';

              // Needs to assign the premium check, as it does not come from API
              // We save it in the model to save in preferences
              model.incorrectPremium = false;
              if (model.premium == 0 && _tacFilters.useOptimal) {
                model.incorrectPremium = true;
                resultString += '\n\nNOTE: no optimal targets retrieved '
                    'as your account is not premium!';
                time = 5;
              }

              _showSuccessToast(
                resultString,
                Colors.green,
                time: time,
              );

              _incorrectPremium = model.incorrectPremium;
              _tacModel = model;
              _saveTargets();
            } else {
              _showSuccessToast(
                'No targets found with the current filters!',
                Colors.orange[700],
              );
            }

            _apiCall = false;
          });
        } else {
          setState(() {
            _showErrorToast();
            _apiCall = false;
          });
        }
      }
    } catch (e) {
      print(e);

      setState(() {
        _showErrorToast();
        _apiCall = false;
      });
    }
  }

  void _showErrorToast() {
    BotToast.showText(
      text: 'There was an error getting your request, try again later!',
      textStyle: TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: Colors.red,
      duration: Duration(seconds: 3),
      contentPadding: EdgeInsets.all(10),
    );
  }

  void _showSuccessToast(String text, Color background, {int time = 3}) {
    BotToast.showText(
      text: text,
      textStyle: TextStyle(
        fontSize: 14,
        color: Colors.white,
      ),
      contentColor: background,
      duration: Duration(seconds: time),
      contentPadding: EdgeInsets.all(10),
    );
  }

  _optimalExplanationDialog() {
    return AlertDialog(
      title: Text("Optimal targets"),
      content: EasyRichText(
        "This feature requires premium access to TAC."
        "\n\n"
        "Tap here or contact Fr00t for more info",
        defaultStyle: TextStyle(fontSize: 13, color: _themeProvider.mainText),
        patternList: [
          EasyRichTextPattern(
            targetString: 'here',
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                Navigator.of(context).pop();
                var url = 'https://tornattackcentral.eu/premium.php';
                if (_settingsProvider.currentBrowser ==
                    BrowserSetting.external) {
                  if (await canLaunch(url)) {
                    await launch(url, forceSafariVC: false);
                  }
                } else {
                  _settingsProvider.useQuickBrowser
                      ? openBrowserDialog(context, url)
                      : _openTornBrowser(url);
                }
              },
            style: TextStyle(
              decoration: TextDecoration.underline,
              color: Colors.blue,
            ),
          ),
          EasyRichTextPattern(
            targetString: 'Fr00t',
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                Navigator.of(context).pop();
                var url = 'https://www.torn.com/profiles.php?XID=2518990';
                if (_settingsProvider.currentBrowser ==
                    BrowserSetting.external) {
                  if (await canLaunch(url)) {
                    await launch(url, forceSafariVC: false);
                  }
                } else {
                  _settingsProvider.useQuickBrowser
                      ? openBrowserDialog(context, url)
                      : _openTornBrowser(url);
                }
              },
            style: TextStyle(
              decoration: TextDecoration.underline,
              color: Colors.blue,
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FlatButton(
            child: Text("Understood"),
            onPressed: () {
              Navigator.of(context).pop('exit');
            },
          ),
        ),
      ],
    );
  }

  _tacExplanationDialog() {
    return AlertDialog(
      title: Text("Torn Attack Central"),
      content: EasyRichText(
        "Torn Attack Central (TAC) is a service provided by Fr00t. This is its Torn PDA interface."
        "\n\n"
        "TAC will help you find targets depending on several factors. There is also a Premium package and "
        "other features you can benefit from. Make sure to visit their website and forum if you wish to learn more."
        "\n\n"
        "IMPORTANT: Torn PDA does not benefit from TAC and does not share any information with it."
        "\n\n"
        "If you prefer not to use TAC, please go to Options in your main target's screen (Chaining section) "
        "and deactivate it.",
        defaultStyle: TextStyle(fontSize: 13, color: _themeProvider.mainText),
        patternList: [
          EasyRichTextPattern(
            targetString: 'IMPORTANT',
            //matchOption: 'all'
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          EasyRichTextPattern(
            targetString: 'website',
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                Navigator.of(context).pop();
                var url = 'https://tornattackcentral.eu';
                if (_settingsProvider.currentBrowser ==
                    BrowserSetting.external) {
                  if (await canLaunch(url)) {
                    await launch(url, forceSafariVC: false);
                  }
                } else {
                  _settingsProvider.useQuickBrowser
                      ? openBrowserDialog(context, url)
                      : _openTornBrowser(url);
                }
              },
            style: TextStyle(
                decoration: TextDecoration.underline, color: Colors.blue),
          ),
          EasyRichTextPattern(
            targetString: 'Fr00t',
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                Navigator.of(context).pop();
                var url = 'https://www.torn.com/profiles.php?XID=2518990';
                if (_settingsProvider.currentBrowser ==
                    BrowserSetting.external) {
                  if (await canLaunch(url)) {
                    await launch(url, forceSafariVC: false);
                  }
                } else {
                  _settingsProvider.useQuickBrowser
                      ? openBrowserDialog(context, url)
                      : _openTornBrowser(url);
                }
              },
            style: TextStyle(
                decoration: TextDecoration.underline, color: Colors.blue),
          ),
          EasyRichTextPattern(
            targetString: 'forum',
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                Navigator.of(context).pop();
                var url =
                    'https://www.torn.com/forums.php#/p=threads&f=67&t=16172651&b=0&a=0';
                if (_settingsProvider.currentBrowser ==
                    BrowserSetting.external) {
                  if (await canLaunch(url)) {
                    await launch(url, forceSafariVC: false);
                  }
                } else {
                  _settingsProvider.useQuickBrowser
                      ? openBrowserDialog(context, url)
                      : _openTornBrowser(url);
                }
              },
            style: TextStyle(
                decoration: TextDecoration.underline, color: Colors.blue),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: FlatButton(
            child: Text("Understood"),
            onPressed: () {
              Navigator.of(context).pop('exit');
            },
          ),
        ),
      ],
    );
  }

  Future _openTornBrowser(String page) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (BuildContext context) => WebViewFull(
          customUrl: page,
          customTitle: 'Torn',
        ),
      ),
    );
  }

  void _saveFilters() {
    SharedPreferencesModel().setTACFilters(tacFiltersToJson(_tacFilters));
  }

  void _saveTargets() {
    SharedPreferencesModel().setTACTargets(tacModelToJson(_tacModel));
  }

  Future _restorePreferences() async {
    _tacFilters = TacFilters();
    var savedFilters = await SharedPreferencesModel().getTACFilters();
    if (savedFilters != "") {
      _tacFilters = tacFiltersFromJson(savedFilters);
    }

    var savedModel = await SharedPreferencesModel().getTACTargets();
    if (savedModel != "") {
      setState(() {
        if (_tacModel.incorrectPremium) {
          _incorrectPremium = true;
        }
        _tacModel = tacModelFromJson(savedModel);
      });
    }
  }
}
