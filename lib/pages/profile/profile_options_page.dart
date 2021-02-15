import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/pages/profile/shortcuts_page.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/shortcuts_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class ProfileOptionsReturn {
  bool nukeReviveEnabled;
  bool warnAboutChainsEnabled;
  bool shortcutsEnabled;
  bool dedicatedTravelCard;
  bool disableTravelSection;
  bool expandEvents;
  int eventsShowNumber;
  bool expandMessages;
  int messagesShowNumber;
  bool expandBasicInfo;
  bool expandNetworth;
  List<String> sectionSort;
}

class ProfileOptionsPage extends StatefulWidget {
  @override
  _ProfileOptionsPageState createState() => _ProfileOptionsPageState();
}

class _ProfileOptionsPageState extends State<ProfileOptionsPage> {
  bool _nukeReviveEnabled = true;
  bool _warnAboutChainsEnabled = true;
  bool _shortcutsEnabled = true;
  bool _dedicatedTravelCard = true;
  bool _disableTravelSection = false;
  bool _expandEvents = false;
  bool _expandMessages = false;
  bool _expandBasicInfo = false;
  bool _expandNetworth = false;

  List<String> _sectionList;

  int _messagesNumber = 25;
  int _eventsNumber = 25;

  Future _preferencesLoaded;

  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _preferencesLoaded = _restorePreferences();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return WillPopScope(
      onWillPop: _willPopCallback,
      child: Container(
        color: _themeProvider.currentTheme == AppTheme.light
            ? Colors.blueGrey
            : Colors.grey[900],
        child: SafeArea(
          top: _settingsProvider.appBarTop ? false : true,
          bottom: true,
          child: Scaffold(
            appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
            bottomNavigationBar: !_settingsProvider.appBarTop
                ? SizedBox(
                    height: AppBar().preferredSize.height,
                    child: buildAppBar(),
                  )
                : null,
            body: Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () =>
                      FocusScope.of(context).requestFocus(new FocusNode()),
                  child: FutureBuilder(
                    future: _preferencesLoaded,
                    builder: (BuildContext context,
                        AsyncSnapshot<dynamic> snapshot) {
                      if (snapshot.connectionState == ConnectionState.done) {
                        return SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              SizedBox(height: 15),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'SHORTCUTS',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text("Enable shortcuts"),
                                    Switch(
                                      value: _shortcutsEnabled,
                                      onChanged: (value) {
                                        // If user wants to disable and there are
                                        // active shortcuts, open dialog and offer
                                        // a second opportunity. Also might be good
                                        // to reset the lists if there are issues.
                                        if (!value &&
                                            context
                                                    .read<ShortcutsProvider>()
                                                    .activeShortcuts
                                                    .length >
                                                0) {
                                          _shortcutsDisableConfirmationDialog();
                                        } else {
                                          SharedPreferencesModel()
                                              .setEnableShortcuts(value);
                                          setState(() {
                                            _shortcutsEnabled = value;
                                          });
                                        }
                                      },
                                      activeTrackColor: Colors.lightGreenAccent,
                                      activeColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                child: Text(
                                  'Enable configurable shortcuts in the Profile section to '
                                  'quickly access your favourite sections in game. '
                                  'Tip: if enabled in settings, short-press shortcuts for quick browser '
                                  'window, long-press for full browser with app bar',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              SizedBox(height: 10),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text(
                                      "Configure shortcuts",
                                      style: TextStyle(
                                        color: _shortcutsEnabled
                                            ? _themeProvider.mainText
                                            : Colors.grey,
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                          Icons.keyboard_arrow_right_outlined),
                                      color: _shortcutsEnabled
                                          ? _themeProvider.mainText
                                          : Colors.grey,
                                      onPressed: _shortcutsEnabled
                                          ? () {
                                              Navigator.of(context).push(
                                                MaterialPageRoute(
                                                  builder:
                                                      (BuildContext context) =>
                                                          ShortcutsPage(),
                                                ),
                                              );
                                            }
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 15),
                              Divider(),
                              SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'CHAINING',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text("Warn about chains"),
                                    Switch(
                                      value: _warnAboutChainsEnabled,
                                      onChanged: (value) {
                                        SharedPreferencesModel()
                                            .setWarnAboutChains(value);
                                        setState(() {
                                          _warnAboutChainsEnabled = value;
                                        });
                                      },
                                      activeTrackColor: Colors.lightGreenAccent,
                                      activeColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                child: Text(
                                  'If active, you\'ll get a message and a chain icon to the side of '
                                  'the energy bar, so that you avoid spending energy in the gym '
                                  'if you are unaware that your faction is chaining',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              SizedBox(height: 15),
                              Divider(),
                              SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'TRAVEL',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text("Dedicated Travel card"),
                                    Switch(
                                      value: _dedicatedTravelCard,
                                      onChanged: (value) {
                                        SharedPreferencesModel()
                                            .setDedicatedTravelCard(value);
                                        setState(() {
                                          _dedicatedTravelCard = value;
                                        });

                                        if (!value) {
                                          _disableTravelSection = false;
                                          SharedPreferencesModel()
                                              .setDisableTravelSection(value);
                                        }
                                      },
                                      activeTrackColor: Colors.lightGreenAccent,
                                      activeColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                child: Text(
                                  'If active, you\'ll get an extra card for travel information, '
                                  'access to foreign stocks and notifications (reduced version of the '
                                  'Travel section). If inactive, you\'ll still have basic travel information '
                                  'in the Status card',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              if (_dedicatedTravelCard)
                                Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          15, 5, 15, 0),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: <Widget>[
                                          Text("Disable Travel Section"),
                                          Switch(
                                            value: _disableTravelSection,
                                            onChanged: (value) {
                                              SharedPreferencesModel()
                                                  .setDisableTravelSection(
                                                      value);
                                              setState(() {
                                                _disableTravelSection = value;
                                              });
                                            },
                                            activeTrackColor:
                                                Colors.lightGreenAccent,
                                            activeColor: Colors.green,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 15),
                                      child: Text(
                                        'If using the dedicated travel card, you can optionally disable the app\'s '
                                        'Travel section entirely, as the same information is shown in both',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              SizedBox(height: 15),
                              Divider(),
                              SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'REVIVING SERVICES',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text("Use Nuke Reviving Services"),
                                    Switch(
                                      value: _nukeReviveEnabled,
                                      onChanged: (value) {
                                        SharedPreferencesModel()
                                            .setUseNukeRevive(value);
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
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
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
                              SizedBox(height: 15),
                              Divider(),
                              SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'EXPANDABLE PANELS',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                              SizedBox(height: 8),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                child: Text(
                                  'Choose whether you want to automatically expand '
                                  'or collapse certain sections. You can always '
                                  'toggle manually by tapping',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text("Expand events"),
                                    Switch(
                                      value: _expandEvents,
                                      onChanged: (value) {
                                        SharedPreferencesModel()
                                            .setExpandEvents(value);
                                        setState(() {
                                          _expandEvents = value;
                                        });
                                      },
                                      activeTrackColor: Colors.lightGreenAccent,
                                      activeColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Flexible(
                                      child: Text("Events to show"),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 20),
                                    ),
                                    Flexible(
                                      child: _eventsNumberDropdown(),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text("Expand messages"),
                                    Switch(
                                      value: _expandMessages,
                                      onChanged: (value) {
                                        SharedPreferencesModel()
                                            .setExpandMessages(value);
                                        setState(() {
                                          _expandMessages = value;
                                        });
                                      },
                                      activeTrackColor: Colors.lightGreenAccent,
                                      activeColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Flexible(
                                      child: Text("Messages to show"),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.only(left: 20),
                                    ),
                                    Flexible(
                                      child: _messagesNumberDropdown(),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text("Expand basic info"),
                                    Switch(
                                      value: _expandBasicInfo,
                                      onChanged: (value) {
                                        SharedPreferencesModel()
                                            .setExpandBasicInfo(value);
                                        setState(() {
                                          _expandBasicInfo = value;
                                        });
                                      },
                                      activeTrackColor: Colors.lightGreenAccent,
                                      activeColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: <Widget>[
                                    Text("Expand networth"),
                                    Switch(
                                      value: _expandNetworth,
                                      onChanged: (value) {
                                        SharedPreferencesModel()
                                            .setExpandNetworth(value);
                                        setState(() {
                                          _expandNetworth = value;
                                        });
                                      },
                                      activeTrackColor: Colors.lightGreenAccent,
                                      activeColor: Colors.green,
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 15),
                              Divider(),
                              SizedBox(height: 5),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'CARDS ORDER',
                                    style: TextStyle(fontSize: 10),
                                  ),
                                ],
                              ),
                              SizedBox(height: 5),
                              Container(
                                height: _sectionList.length * 40.0 + 40,
                                child: ReorderableListView(
                                  onReorder: (int oldIndex, int newIndex) {
                                    if (oldIndex < newIndex) {
                                      // removing the item at oldIndex will shorten the list by 1
                                      newIndex -= 1;
                                    }
                                    var oldItem = _sectionList[oldIndex];
                                    setState(() {
                                      _sectionList.removeAt(oldIndex);
                                      _sectionList.insert(newIndex, oldItem);
                                    });
                                    SharedPreferencesModel()
                                        .setProfileSectionOrder(_sectionList);
                                  },
                                  children: _currentSectionSort(),
                                ),
                              ),
                              SizedBox(height: 5),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                child: Text(
                                  'Drag card names to sort them accordingly in the '
                                  'Profile section',
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
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      brightness: Brightness.dark,
      title: Text("Profile Options"),
      leading: new IconButton(
        icon: new Icon(Icons.arrow_back),
        onPressed: () {
          _willPopCallback();
        },
      ),
    );
  }

  DropdownButton _eventsNumberDropdown() {
    return DropdownButton<String>(
      value: _eventsNumber.toString(),
      items: [
        DropdownMenuItem(
          value: "3",
          child: SizedBox(
            width: 40,
            child: Text(
              "3",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "10",
          child: SizedBox(
            width: 40,
            child: Text(
              "10",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "25",
          child: SizedBox(
            width: 40,
            child: Text(
              "25",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "50",
          child: SizedBox(
            width: 40,
            child: Text(
              "50",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "75",
          child: SizedBox(
            width: 40,
            child: Text(
              "75",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "100",
          child: SizedBox(
            width: 40,
            child: Text(
              "100",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        SharedPreferencesModel().setEventsShowNumber(int.parse(value));
        setState(() {
          _eventsNumber = int.parse(value);
        });
      },
    );
  }

  DropdownButton _messagesNumberDropdown() {
    return DropdownButton<String>(
      value: _messagesNumber.toString(),
      items: [
        DropdownMenuItem(
          value: "3",
          child: SizedBox(
            width: 40,
            child: Text(
              "3",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "10",
          child: SizedBox(
            width: 40,
            child: Text(
              "10",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "25",
          child: SizedBox(
            width: 40,
            child: Text(
              "25",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "50",
          child: SizedBox(
            width: 40,
            child: Text(
              "50",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "75",
          child: SizedBox(
            width: 40,
            child: Text(
              "75",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: "100",
          child: SizedBox(
            width: 40,
            child: Text(
              "100",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        SharedPreferencesModel().setMessagesShowNumber(int.parse(value));
        setState(() {
          _messagesNumber = int.parse(value);
        });
      },
    );
  }

  Future _restorePreferences() async {
    var useNuke = await SharedPreferencesModel().getUseNukeRevive();
    var warnChains = await SharedPreferencesModel().getWarnAboutChains();
    var shortcuts = await SharedPreferencesModel().getEnableShortcuts();
    var dedTravel = await SharedPreferencesModel().getDedicatedTravelCard();
    var disableTravel =
        await SharedPreferencesModel().getDisableTravelSection();
    var expandEvents = await SharedPreferencesModel().getExpandEvents();
    var eventsNumber = await SharedPreferencesModel().getEventsShowNumber();
    var expandMessages = await SharedPreferencesModel().getExpandMessages();
    var messagesNumber = await SharedPreferencesModel().getMessagesShowNumber();
    var expandBasicInfo = await SharedPreferencesModel().getExpandBasicInfo();
    var expandNetworth = await SharedPreferencesModel().getExpandNetworth();
    var sectionList = await SharedPreferencesModel().getProfileSectionOrder();

    setState(() {
      _nukeReviveEnabled = useNuke;
      _warnAboutChainsEnabled = warnChains;
      _shortcutsEnabled = shortcuts;
      _dedicatedTravelCard = dedTravel;
      _disableTravelSection = disableTravel;
      _expandEvents = expandEvents;
      _eventsNumber = eventsNumber;
      _expandMessages = expandMessages;
      _messagesNumber = messagesNumber;
      _expandBasicInfo = expandBasicInfo;
      _expandNetworth = expandNetworth;
      _sectionList = sectionList;
    });
  }

  Future<void> _shortcutsDisableConfirmationDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          content: SingleChildScrollView(
            child: Stack(
              children: <Widget>[
                SingleChildScrollView(
                  child: Container(
                    padding: EdgeInsets.only(
                      top: 45,
                      bottom: 16,
                      left: 16,
                      right: 16,
                    ),
                    margin: EdgeInsets.only(top: 15),
                    decoration: new BoxDecoration(
                      color: _themeProvider.background,
                      shape: BoxShape.rectangle,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10.0,
                          offset: const Offset(0.0, 10.0),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize:
                          MainAxisSize.min, // To make the card compact
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            "Caution: you have active shortcuts, if you disable this "
                            "feature you will erase the list as well. Are you sure?",
                            style: TextStyle(
                                fontSize: 12, color: _themeProvider.mainText),
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              child: Text("Disable!"),
                              onPressed: () {
                                context
                                    .read<ShortcutsProvider>()
                                    .wipeAllShortcuts();
                                SharedPreferencesModel()
                                    .setEnableShortcuts(false);
                                setState(() {
                                  _shortcutsEnabled = false;
                                });
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: Text("Oh no!"),
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  child: CircleAvatar(
                    radius: 26,
                    backgroundColor: _themeProvider.background,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider.background,
                      radius: 22,
                      child: SizedBox(
                        height: 34,
                        width: 34,
                        child: Icon(Icons.delete_forever_outlined),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<bool> _willPopCallback() async {
    Navigator.of(context).pop(
      ProfileOptionsReturn()
        ..nukeReviveEnabled = _nukeReviveEnabled
        ..warnAboutChainsEnabled = _warnAboutChainsEnabled
        ..shortcutsEnabled = _shortcutsEnabled
        ..dedicatedTravelCard = _dedicatedTravelCard
        ..disableTravelSection = _disableTravelSection
        ..expandEvents = _expandEvents
        ..eventsShowNumber = _eventsNumber
        ..expandMessages = _expandMessages
        ..messagesShowNumber = _messagesNumber
        ..expandBasicInfo = _expandBasicInfo
        ..expandNetworth = _expandNetworth
        ..sectionSort = _sectionList,
    );
    return true;
  }

  List<Widget> _currentSectionSort() {
    var myList = <Widget>[];
    for (var section in _sectionList) {
      myList.add(
        SizedBox(
          height: 40,
          key: UniqueKey(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Card(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 15),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      section,
                      style: TextStyle(
                        fontSize: 13,
                      ),
                    ),
                    Icon(Icons.menu, size: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return myList;
  }
}
