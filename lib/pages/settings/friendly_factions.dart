// Flutter imports:
// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/models/chaining/target_model.dart';
// Project imports:
import 'package:torn_pda/models/faction/faction_model.dart';
import 'package:torn_pda/models/faction/friendly_faction_model.dart';
import 'package:torn_pda/providers/api/api_v1_calls.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/html_parser.dart';

class FriendlyFactionsPage extends StatefulWidget {
  @override
  FriendlyFactionsPageState createState() => FriendlyFactionsPageState();
}

class FriendlyFactionsPageState extends State<FriendlyFactionsPage> {
  ThemeProvider? _themeProvider;
  SettingsProvider? _settingsProvider;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    routeWithDrawer = false;
    routeName = "friendly_factions";
    _settingsProvider!.willPopShouldGoBackStream.stream.listen((event) {
      if (mounted && routeName == "friendly_factions") _goBack();
    });
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      color: _themeProvider!.currentTheme == AppTheme.light
          ? MediaQuery.orientationOf(context) == Orientation.portrait
              ? Colors.blueGrey
              : _themeProvider!.canvas
          : _themeProvider!.canvas,
      child: SafeArea(
        right: context.read<WebViewProvider>().webViewSplitActive &&
            context.read<WebViewProvider>().splitScreenPosition == WebViewSplitPosition.left,
        left: context.read<WebViewProvider>().webViewSplitActive &&
            context.read<WebViewProvider>().splitScreenPosition == WebViewSplitPosition.right,
        child: Scaffold(
          backgroundColor: _themeProvider!.canvas,
          appBar: _settingsProvider!.appBarTop ? buildAppBar() : null,
          bottomNavigationBar: !_settingsProvider!.appBarTop
              ? SizedBox(
                  height: AppBar().preferredSize.height,
                  child: buildAppBar(),
                )
              : null,
          body: Container(
            color: _themeProvider!.canvas,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 15),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ButtonTheme(
                        minWidth: 1.0,
                        child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all<Color?>(_themeProvider!.secondBackground),
                            shape: WidgetStateProperty.all<OutlinedBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: const BorderSide(width: 2, color: Colors.blueGrey),
                              ),
                            ),
                          ),
                          child: Icon(
                            Icons.add,
                            size: 20,
                            color: _themeProvider!.mainText,
                          ),
                          onPressed: () {
                            _showAddDialog(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 15),
                      ButtonTheme(
                        minWidth: 1.0,
                        child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all<Color?>(_themeProvider!.secondBackground),
                            shape: WidgetStateProperty.all<OutlinedBorder>(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: const BorderSide(
                                  width: 2,
                                  color: Colors.blueGrey,
                                ),
                              ),
                            ),
                          ),
                          child: Icon(
                            Icons.delete_outline,
                            size: 20,
                            color: _themeProvider!.mainText,
                          ),
                          onPressed: () {
                            _openWipeDialog();
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      "Use the '+' button to add new friendly factions to the list. "
                      'Players in said factions will be flagged as allied when you visit their '
                      'profiles or try to attack them.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
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
    final factionList = <Widget>[];
    for (final fact in _settingsProvider!.friendlyFactions) {
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
                    Text(HtmlParser.fix(fact.name)),
                    Text(
                      "[${fact.id}]",
                      style: const TextStyle(
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
                        final currentFactions = _settingsProvider!.friendlyFactions;
                        currentFactions.removeWhere((element) => element.id == fact.id);
                        _settingsProvider!.setFriendlyFactions = currentFactions;

                        BotToast.showText(
                          text: 'Removed ${fact.name}!',
                          textStyle: const TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          contentColor: Colors.green,
                          duration: const Duration(seconds: 3),
                          contentPadding: const EdgeInsets.all(10),
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
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider!.appBarTop ? 2 : 0,
      toolbarHeight: 50,
      title: const Text('Friendly factions', style: TextStyle(color: Colors.white)),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          _goBack();
        },
      ),
    );
  }

  Future<void> _showAddDialog(BuildContext _) {
    return showDialog<void>(
      context: _,
      builder: (BuildContext context) {
        return AddFriendlyFactionDialog(
          themeProvider: _themeProvider,
          settingsProvider: _settingsProvider,
        );
      },
    );
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
                    padding: const EdgeInsets.only(
                      top: 45,
                      bottom: 16,
                      left: 16,
                      right: 16,
                    ),
                    margin: const EdgeInsets.only(top: 15),
                    decoration: BoxDecoration(
                      color: _themeProvider!.secondBackground,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 10.0,
                          offset: Offset(0.0, 10.0),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min, // To make the card compact
                      children: <Widget>[
                        const Flexible(
                          child: Text(
                            "CAUTION",
                            style: TextStyle(fontSize: 13, color: Colors.red),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Flexible(
                          child: Text(
                            "This will remove all friendly factions!",
                            style: TextStyle(fontSize: 12, color: _themeProvider!.mainText),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Flexible(
                          child: Text(
                            "Are you sure?",
                            style: TextStyle(fontSize: 12, color: _themeProvider!.mainText),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              child: const Text("Do it!"),
                              onPressed: () {
                                _settingsProvider!.setFriendlyFactions = <FriendlyFaction>[];
                                Navigator.of(context).pop();
                              },
                            ),
                            TextButton(
                              child: const Text("Oh no!"),
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
                    backgroundColor: _themeProvider!.secondBackground,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider!.secondBackground,
                      radius: 22,
                      child: const SizedBox(
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

  _goBack() {
    routeWithDrawer = false;
    routeName = "settings_browser";
    Navigator.of(context).pop();
  }
}

class AddFriendlyFactionDialog extends StatefulWidget {
  final ThemeProvider? themeProvider;
  final SettingsProvider? settingsProvider;

  const AddFriendlyFactionDialog({
    required this.themeProvider,
    required this.settingsProvider,
    super.key,
  });

  @override
  AddFriendlyFactionDialogState createState() => AddFriendlyFactionDialogState();
}

class AddFriendlyFactionDialogState extends State<AddFriendlyFactionDialog> {
  bool _addFromUserId = false;
  final _addIdController = TextEditingController();
  final _addFormKey = GlobalKey<FormState>();

  @override
  Future dispose() async {
    _addIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                padding: const EdgeInsets.only(
                  top: 45,
                  bottom: 16,
                  left: 16,
                  right: 16,
                ),
                margin: const EdgeInsets.only(top: 30),
                decoration: BoxDecoration(
                  color: widget.themeProvider!.secondBackground,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10.0,
                      offset: Offset(0.0, 10.0),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 5),
                    Text(
                      'You can find the faction ID in the browser address bar when visiting '
                      'another faction. If in doubt, press the icon to the right to switch between faction ID '
                      'and player ID input',
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Form(
                      key: _addFormKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // To make the card compact
                        children: <Widget>[
                          Row(
                            children: [
                              Flexible(
                                child: TextFormField(
                                  style: const TextStyle(fontSize: 14),
                                  controller: _addIdController,
                                  maxLength: 8,
                                  minLines: 1,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.digitsOnly],
                                  decoration: InputDecoration(
                                    counterText: "",
                                    border: const OutlineInputBorder(),
                                    labelText: !_addFromUserId ? 'Insert faction ID' : 'Insert user ID',
                                  ),
                                  validator: (value) {
                                    if (value!.isEmpty || value == "0") {
                                      return "Enter a valid ID!";
                                    }
                                    _addIdController.text = value.trim();
                                    return null;
                                  },
                                ),
                              ),
                              IconButton(
                                icon: _addFromUserId
                                    ? Image.asset(
                                        'images/icons/faction.png',
                                        color: widget.themeProvider!.mainText,
                                        width: 16,
                                      )
                                    : const Icon(Icons.person),
                                onPressed: () {
                                  setState(() {
                                    _addFromUserId = !_addFromUserId;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 16.0),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              TextButton(
                                child: const Text("Add"),
                                onPressed: () async {
                                  await _addPressed(context);
                                },
                              ),
                              TextButton(
                                child: const Text("Cancel"),
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
                backgroundColor: widget.themeProvider!.secondBackground,
                child: CircleAvatar(
                  backgroundColor: widget.themeProvider!.mainText,
                  radius: 22,
                  child: SizedBox(
                    height: 20,
                    width: 20,
                    child: Image.asset(
                      'images/icons/faction.png',
                      color: widget.themeProvider!.secondBackground,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addPressed(BuildContext context) async {
    if (_addFormKey.currentState!.validate()) {
      // Get rid of dialog first, so that it can't
      // be pressed twice
      Navigator.of(context).pop();
      // Copy controller's text ot local variable
      // early and delete the global, so that text
      // does not appear again in case of failure
      var inputId = _addIdController.text;
      _addIdController.text = '';

      final userProv = context.read<UserDetailsProvider>();

      // If an user ID was inserted, we need to transform it first
      if (_addFromUserId) {
        final dynamic target = await ApiCallsV1.getTarget(playerId: inputId);
        String convertError = "";
        if (target is TargetModel) {
          inputId = target.faction!.factionId.toString();
          if (inputId == "0") {
            convertError = "${target.name} does not belong to a faction!";
          }
        } else {
          convertError = "Can't locate the given target!";
        }

        if (convertError.isNotEmpty) {
          BotToast.showText(
            text: convertError,
            textStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.orange[700]!,
            duration: const Duration(seconds: 3),
            contentPadding: const EdgeInsets.all(10),
          );
          return;
        }
      }

      if (inputId == userProv.basic!.faction!.factionId.toString()) {
        BotToast.showText(
          text: 'There is no need to add your own faction, you will be '
              'alerted about it by default!',
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.orange[700]!,
          duration: const Duration(seconds: 4),
          contentPadding: const EdgeInsets.all(10),
        );
        return;
      }

      for (final faction in widget.settingsProvider!.friendlyFactions) {
        if (faction.id.toString() == inputId) {
          BotToast.showText(
            text: 'This faction is already in the list!',
            textStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.orange[700]!,
            duration: const Duration(seconds: 4),
            contentPadding: const EdgeInsets.all(10),
          );
          return;
        }
      }

      final retrievedFaction = await ApiCallsV1.getFaction(factionId: inputId);

      if (retrievedFaction is FactionModel) {
        if (retrievedFaction.name!.isNotEmpty) {
          final currentFactions = widget.settingsProvider!.friendlyFactions;
          currentFactions.add(
            FriendlyFaction()
              ..name = retrievedFaction.name
              ..id = retrievedFaction.id,
          );

          currentFactions.sort((a, b) => a.name!.compareTo(b.name!));

          widget.settingsProvider!.setFriendlyFactions = currentFactions;

          BotToast.showText(
            text: 'Added ${retrievedFaction.name}!',
            textStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.green,
            duration: const Duration(seconds: 3),
            contentPadding: const EdgeInsets.all(10),
          );
        } else {
          BotToast.showText(
            text: 'Could not retrieved any faction matching id $inputId!',
            textStyle: const TextStyle(
              fontSize: 14,
              color: Colors.white,
            ),
            contentColor: Colors.green,
            duration: const Duration(seconds: 3),
            contentPadding: const EdgeInsets.all(10),
          );
        }
      } else {
        BotToast.showText(
          text: 'Error contacting API, please try again later!',
          textStyle: const TextStyle(
            fontSize: 14,
            color: Colors.white,
          ),
          contentColor: Colors.red[700]!,
          duration: const Duration(seconds: 3),
          contentPadding: const EdgeInsets.all(10),
        );
      }
    }
  }
}
