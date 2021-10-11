// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/models/faction/faction_model.dart';
import 'package:torn_pda/models/faction/friendly_faction_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/api_caller.dart';

class FriendlyFactionsPage extends StatefulWidget {
  @override
  _FriendlyFactionsPageState createState() => _FriendlyFactionsPageState();
}

class _FriendlyFactionsPageState extends State<FriendlyFactionsPage> {
  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;

  final _addIdController = new TextEditingController();
  var _addFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
  }

  @override
  Future dispose() async {
    _addIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return WillPopScope(
      onWillPop: _willPopCallback,
      child: Container(
        color: _themeProvider.currentTheme == AppTheme.light
            ? MediaQuery.of(context).orientation == Orientation.portrait
                ? Colors.blueGrey
                : Colors.grey[900]
            : Colors.grey[900],
        child: SafeArea(
          top: _settingsProvider.appBarTop ? false : true,
          bottom: true,
          child: Scaffold(
            drawer: new Drawer(),
            appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
            bottomNavigationBar: !_settingsProvider.appBarTop
                ? SizedBox(
                    height: AppBar().preferredSize.height,
                    child: buildAppBar(),
                  )
                : null,
            body: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
              child: Column(
                children: <Widget>[
                  SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ButtonTheme(
                        minWidth: 1.0,
                        child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(_themeProvider.background),
                            shape: MaterialStateProperty.all<OutlinedBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: BorderSide(width: 2, color: Colors.blueGrey),
                              ),
                            ),
                          ),
                          child: Icon(
                            Icons.add,
                            size: 20,
                            color: _themeProvider.mainText,
                          ),
                          onPressed: () {
                            _showAddDialog(context);
                          },
                        ),
                      ),
                      SizedBox(width: 15),
                      ButtonTheme(
                        minWidth: 1.0,
                        child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.all<Color>(_themeProvider.background),
                            shape: MaterialStateProperty.all<OutlinedBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: BorderSide(
                                  width: 2,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: _themeProvider.mainText,
                          ),
                          onPressed: () {
                            _openWipeDialog();
                          },
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      'Use the \'+\' button to add new friendly factions to the list. '
                      'Players in said factions will be flagged as allied when you visit their '
                      'profiles or try to attack them.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  Flexible(
                    child: Consumer<SettingsProvider>(
                      builder: (context, settingsProvider, child) => factions(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  ListView factions() {
    var factionList = <Widget>[];
    for (var fact in _settingsProvider.friendlyFactions) {
      factionList.add(
        Card(
          key: UniqueKey(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fact.name),
                    Text(
                      "[${fact.id}]",
                      style: TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        color: Colors.red[300],
                      ),
                      onPressed: () {
                        var currentFactions = _settingsProvider.friendlyFactions;
                        currentFactions.removeWhere((element) => element.id == fact.id);
                        _settingsProvider.setFriendlyFactions = currentFactions;

                        BotToast.showText(
                          text: 'Removed ${fact.name}!',
                          textStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          contentColor: Colors.green,
                          duration: Duration(seconds: 3),
                          contentPadding: EdgeInsets.all(10),
                        );
                      },
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      children: factionList,
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      //brightness: Brightness.dark, // For downgrade to Flutter 2.2.3
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      toolbarHeight: 50,
      title: Text('Friendly factions'),
      leading: new IconButton(
        icon: new Icon(Icons.arrow_back),
        onPressed: () {
          _willPopCallback();
        },
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext _) {
    return showDialog<void>(
        context: _,
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
                      margin: EdgeInsets.only(top: 30),
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
                        children: [
                          Text(
                            'You can find the faction ID in the browser address bar when visiting '
                            'another faction',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          SizedBox(height: 10),
                          Form(
                            key: _addFormKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min, // To make the card compact
                              children: <Widget>[
                                TextFormField(
                                  style: TextStyle(fontSize: 14),
                                  controller: _addIdController,
                                  maxLength: 8,
                                  minLines: 1,
                                  maxLines: 1,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                                  decoration: InputDecoration(
                                    counterText: "",
                                    border: OutlineInputBorder(),
                                    labelText: 'Insert faction ID',
                                  ),
                                  validator: (value) {
                                    if (value.isEmpty || value == "0") {
                                      return "Enter a valid ID!";
                                    }
                                    _addIdController.text = value.trim();
                                    return null;
                                  },
                                ),
                                SizedBox(height: 16.0),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: <Widget>[
                                    TextButton(
                                      child: Text("Add"),
                                      onPressed: () async {
                                        await _addPressed(context);
                                      },
                                    ),
                                    TextButton(
                                      child: Text("Cancel"),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                        _addIdController.text = '';
                                      },
                                    ),
                                  ],
                                )
                              ],
                            ),
                          ),
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
                        backgroundColor: _themeProvider.mainText,
                        radius: 22,
                        child: SizedBox(
                          height: 20,
                          width: 20,
                          child: Image.asset(
                            'images/icons/faction.png',
                            color: _themeProvider.background,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }

  Future<void> _addPressed(BuildContext context) async {
    if (_addFormKey.currentState.validate()) {
      // Get rid of dialog first, so that it can't
      // be pressed twice
      Navigator.of(context).pop();
      // Copy controller's text ot local variable
      // early and delete the global, so that text
      // does not appear again in case of failure
      var inputId = _addIdController.text;
      _addIdController.text = '';

      var userProv = context.read<UserDetailsProvider>();

      if (inputId == userProv.basic.faction.factionId.toString()) {
        BotToast.showText(
          text: 'There is no need to add your own faction, you will be '
              'alerted about it by default!',
          textStyle: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.orange[700],
          duration: Duration(seconds: 4),
          contentPadding: EdgeInsets.all(10),
        );
        return;
      }

      for (var faction in _settingsProvider.friendlyFactions) {
        if (faction.id.toString() == inputId) {
          BotToast.showText(
            text: 'This faction is already in the list!',
            textStyle: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.orange[700],
            duration: Duration(seconds: 4),
            contentPadding: EdgeInsets.all(10),
          );
          return;
        }
      }

      var retrievedFaction = await TornApiCaller.faction(
        userProv.basic.userApiKey,
        inputId,
      ).getFaction;

      if (retrievedFaction is FactionModel) {
        if (retrievedFaction.name.isNotEmpty) {
          var currentFactions = _settingsProvider.friendlyFactions;
          currentFactions.add(FriendlyFaction()
            ..name = retrievedFaction.name
            ..id = retrievedFaction.id);

          currentFactions.sort((a, b) => a.name.compareTo(b.name));

          _settingsProvider.setFriendlyFactions = currentFactions;

          BotToast.showText(
            text: 'Added ${retrievedFaction.name}!',
            textStyle: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.green,
            duration: Duration(seconds: 3),
            contentPadding: EdgeInsets.all(10),
          );
        } else {
          BotToast.showText(
            text: 'Could not any retrievedFaction matching id $inputId!',
            textStyle: TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.green,
            duration: Duration(seconds: 3),
            contentPadding: EdgeInsets.all(10),
          );
        }
      } else {
        BotToast.showText(
          text: 'Error contacting API, please try again later!',
          textStyle: TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.red[700],
          duration: Duration(seconds: 3),
          contentPadding: EdgeInsets.all(10),
        );
      }
    }
  }

  Future<void> _openWipeDialog() {
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
                      mainAxisSize: MainAxisSize.min, // To make the card compact
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            "CAUTION",
                            style: TextStyle(fontSize: 13, color: Colors.red),
                          ),
                        ),
                        SizedBox(height: 10),
                        Flexible(
                          child: Text(
                            "This will remove all friendly factions!",
                            style: TextStyle(fontSize: 12, color: _themeProvider.mainText),
                          ),
                        ),
                        SizedBox(height: 10),
                        Flexible(
                          child: Text(
                            "Are you sure?",
                            style: TextStyle(fontSize: 12, color: _themeProvider.mainText),
                          ),
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              child: Text("Do it!"),
                              onPressed: () {
                                _settingsProvider.setFriendlyFactions = <FriendlyFaction>[];
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
    Navigator.of(context).pop();
    return true;
  }
}
