// Dart imports:
import 'dart:async';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:torn_pda/drawer.dart';
// Project imports:
import 'package:torn_pda/models/friends/friends_backup_model.dart';
import 'package:torn_pda/providers/friends_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';

class FriendsBackupPage extends StatefulWidget {
  @override
  FriendsBackupPageState createState() => FriendsBackupPageState();
}

class FriendsBackupPageState extends State<FriendsBackupPage> {
  late FriendsProvider _friendsProvider;
  late ThemeProvider _themeProvider;
  late SettingsProvider _settingsProvider;

  late FriendsBackupModel _tentativeImportModel;

  bool _importActive = false;
  int _importSuccessEvents = 0;

  final _importFormKey = GlobalKey<FormState>();
  final _importInputController = TextEditingController();

  final String _exportInfo = "In order to export & backup your friends, you can either copy/paste "
      "to a text file manually, or share and save it at your desired location. "
      "In any case, please keep the text original structure.";

  final String _importInfo = "In order to import friends, please paste here the string that "
      "you exported in the past. You can make changes outside of Torn PDA, "
      "but ensure that the main structure is kept!";

  final String _importChoiceString = "you can either add them to your current list, or replace everything "
      "(you'll lose your current friends!).\n\nChoose wisely.";

  Color? _importHintStyle = Colors.black;
  String _importHintText = 'Paste here previously exported data';
  FontWeight _importHintWeight = FontWeight.normal;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);

    routeWithDrawer = false;
    routeName = "friends_backup";
    _settingsProvider.willPopShouldGoBackStream.stream.listen((event) {
      if (mounted && routeName == "friends_backup") _goBack();
    });
  }

  @override
  Widget build(BuildContext context) {
    _friendsProvider = Provider.of<FriendsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context);
    _importHintStyle = _themeProvider.mainText;
    return Container(
      color: _themeProvider.currentTheme == AppTheme.light
          ? MediaQuery.orientationOf(context) == Orientation.portrait
              ? Colors.blueGrey
              : _themeProvider.canvas
          : _themeProvider.canvas,
      child: SafeArea(
        right: context.read<WebViewProvider>().webViewSplitActive &&
            context.read<WebViewProvider>().splitScreenPosition == WebViewSplitPosition.left,
        left: context.read<WebViewProvider>().webViewSplitActive &&
            context.read<WebViewProvider>().splitScreenPosition == WebViewSplitPosition.right,
        child: Scaffold(
          backgroundColor: _themeProvider.canvas,
          appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
          bottomNavigationBar: !_settingsProvider.appBarTop
              ? SizedBox(
                  height: AppBar().preferredSize.height,
                  child: buildAppBar(),
                )
              : null,
          body: Builder(
            builder: (BuildContext context) {
              return Container(
                color: _themeProvider.currentTheme == AppTheme.extraDark ? Colors.black : Colors.transparent,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
                  child: SingleChildScrollView(
                    child: Column(
                      children: <Widget>[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(15, 30, 20, 15),
                          child: Text(
                            "HOW TO EXPORT friends",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(30, 10, 30, 15),
                          child: Text(
                            _exportInfo,
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Wrap(
                          alignment: WrapAlignment.center,
                          children: <Widget>[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.share),
                                label: const Text("Export"),
                                onPressed: () async {
                                  final export = _friendsProvider.exportFriends();
                                  if (export == '') {
                                    BotToast.showText(
                                      text: 'No friends to export!',
                                      textStyle: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                      contentColor: Colors.red,
                                      duration: const Duration(seconds: 3),
                                      contentPadding: const EdgeInsets.all(10),
                                    );
                                  } else {
                                    Share.share(
                                      export,
                                      sharePositionOrigin: Rect.fromLTWH(
                                        0,
                                        0,
                                        MediaQuery.of(context).size.width,
                                        MediaQuery.of(context).size.height / 2,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.content_copy),
                                label: const Text("Clipboard"),
                                onPressed: () async {
                                  final export = _friendsProvider.exportFriends();
                                  if (export == '') {
                                    BotToast.showText(
                                      text: 'No friends to export!',
                                      textStyle: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                      contentColor: Colors.red,
                                      duration: const Duration(seconds: 3),
                                      contentPadding: const EdgeInsets.all(10),
                                    );
                                  } else {
                                    Clipboard.setData(ClipboardData(text: export));
                                    BotToast.showText(
                                      text: "${_friendsProvider.getFriendNumber()} "
                                          "Friends copied to clipboard!",
                                      textStyle: const TextStyle(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                      contentColor: Colors.green,
                                      duration: const Duration(seconds: 3),
                                      contentPadding: const EdgeInsets.all(10),
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(0, 30, 0, 30),
                          child: Divider(),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(15, 0, 20, 15),
                          child: Text(
                            "HOW TO IMPORT friends",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(30, 10, 30, 15),
                          child: Text(
                            _importInfo,
                            style: const TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ),
                        _importProgressWidget(),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                          child: Form(
                            key: _importFormKey,
                            child: Column(
                              children: <Widget>[
                                TextFormField(
                                  controller: _importInputController,
                                  maxLines: 6,
                                  style: const TextStyle(fontSize: 12),
                                  decoration: InputDecoration(
                                    counterText: "",
                                    border: const OutlineInputBorder(),
                                    hintText: _importHintText,
                                    hintStyle: TextStyle(
                                      color: _importHintStyle,
                                      fontWeight: _importHintWeight,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value!.isEmpty) {
                                      return "Cannot be empty!";
                                    }
                                    return null;
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.file_download),
                                    label: const Text("Import"),
                                    onPressed: () {
                                      if (_importFormKey.currentState!.validate()) {
                                        final numberImported = _importChecker();
                                        if (numberImported == 0) {
                                          BotToast.showText(
                                            text: 'No friends to import! '
                                                'Is the file structure correct?',
                                            textStyle: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                            contentColor: Colors.red,
                                            duration: const Duration(seconds: 3),
                                            contentPadding: const EdgeInsets.all(10),
                                          );
                                        } else {
                                          FocusScope.of(context).requestFocus(FocusNode());
                                          _showImportDialog();
                                        }
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      title: const Text("Import & Export", style: TextStyle(color: Colors.white)),
    );
  }

  @override
  Future dispose() async {
    _importInputController.dispose();
    routeWithDrawer = true;
    routeName = "friends";
    super.dispose();
  }

  Widget _importProgressWidget() {
    if (!_importActive) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
      child: LinearPercentIndicator(
        padding: const EdgeInsets.all(0),
        barRadius: const Radius.circular(10),
        alignment: MainAxisAlignment.center,
        width: 200,
        lineHeight: 16,
        progressColor: Colors.green[200],
        backgroundColor: Colors.red[200],
        center: Text(
          '$_importSuccessEvents/${_tentativeImportModel.friendBackup!.length}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        percent: _importSuccessEvents / _tentativeImportModel.friendBackup!.length,
      ),
    );
  }

  int _importChecker() {
    try {
      final String inputString = _importInputController.text;
      final FriendsBackupModel inputModel = friendsBackupModelFromJson(inputString);
      for (final tar in inputModel.friendBackup!) {
        if (tar.notesColor!.length > 10) {
          tar.notesColor = tar.notesColor!.substring(0, 9);
        }
        if (tar.notesColor!.length > 200) {
          tar.notesColor = tar.notesColor!.substring(0, 199);
        }
        if (tar.notesColor != "red" && tar.notesColor != "green" && tar.notesColor != "blue") {
          tar.notesColor = "";
        }
      }
      _tentativeImportModel = inputModel;
      return _tentativeImportModel.friendBackup!.length;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _showImportDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0.0,
          backgroundColor: Colors.transparent,
          content: SingleChildScrollView(
            child: Container(
              padding: const EdgeInsets.only(
                top: 12,
                bottom: 16,
                left: 16,
                right: 16,
              ),
              //margin: EdgeInsets.only(top: 30),
              decoration: BoxDecoration(
                color: _themeProvider.secondBackground,
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
                  const Padding(
                    padding: EdgeInsets.fromLTRB(15, 30, 20, 15),
                    child: Text(
                      "How would you like to import?",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(30, 10, 30, 20),
                    child: Text(
                      "${_tentativeImportModel.friendBackup!.length} new friends were found, $_importChoiceString",
                      style: const TextStyle(
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ElevatedButton(
                        child: const Text("Add"),
                        onPressed: () async {
                          Navigator.of(context).pop();
                          onImportPressed(replace: false);
                        },
                      ),
                      const Padding(
                        padding: EdgeInsets.only(left: 5, right: 5),
                      ),
                      ElevatedButton(
                        child: const Text("Replace"),
                        onPressed: () {
                          Navigator.of(context).pop();
                          onImportPressed(replace: true);
                        },
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 30, right: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text("Cancel import"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> onImportPressed({required bool replace}) async {
    String existing = ' to the existing list';
    if (replace) {
      existing = '';
      _friendsProvider.wipeAllFriends();
    }
    await _importFriends();
    if (mounted) {
      setState(() {
        // More readable variables makes it easier
        final total = _tentativeImportModel.friendBackup!.length;
        final numWorked = _importSuccessEvents;
        _importInputController.text = "";
        if (numWorked == 0) {
          _importHintText = "Import of all $total friends failed! "
              "Probably repeated or incorrect IDs?";
          _importHintStyle = Colors.red;
          _importHintWeight = FontWeight.bold;
        } else if (numWorked == total) {
          _importHintText = "Imported $numWorked new friends$existing!";
          _importHintStyle = Colors.green;
          _importHintWeight = FontWeight.bold;
        } else {
          _importHintText = "Imported $numWorked new friends$existing, "
              "but there were ${total - _importSuccessEvents} "
              "friends that failed to import! "
              "Probably repeated or incorrect IDs?";
          _importHintStyle = Colors.red;
          _importHintWeight = FontWeight.bold;
        }
      });
    }
  }

  Future<void> _importFriends() async {
    _importActive = true; // Show import status
    _importSuccessEvents = 0;
    for (final import in _tentativeImportModel.friendBackup!) {
      final importResult = await _friendsProvider.addFriend(
        import.id.toString(),
        notes: import.notes,
        notesColor: import.notesColor,
      );
      if (importResult.success) {
        if (mounted) {
          setState(() {
            _importSuccessEvents++;
          });
        }
      }
      // Avoid issues with API limits
      if (_tentativeImportModel.friendBackup!.length > 60) {
        await Future.delayed(const Duration(seconds: 1), () {});
      }
    }
  }

  _goBack() {
    routeWithDrawer = true;
    routeName = "friends";
    Navigator.of(context).pop();
  }
}
