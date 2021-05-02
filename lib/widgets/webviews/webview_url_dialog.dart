// Dart imports:
import 'dart:async';

// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/models/profile/shortcuts_model.dart';
import 'package:torn_pda/providers/shortcuts_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/webviews/webview_shortcuts_dialog.dart';

class WebviewUrlDialog extends StatefulWidget {
  final Function callFindInPage;
  final String title;
  final String url;
  final InAppWebViewController webview;

  WebviewUrlDialog({
    @required this.callFindInPage,
    @required this.title,
    @required this.url,
    @required this.webview,
  });

  @override
  _WebviewUrlDialogState createState() => _WebviewUrlDialogState();
}

class _WebviewUrlDialogState extends State<WebviewUrlDialog> {
  ThemeProvider _themeProvider;
  ShortcutsProvider _shortcutsProvider;

  final _customURLController = new TextEditingController();
  var _customURLKey = GlobalKey<FormState>();

  final _customShortcutNameController = new TextEditingController();
  final _customShortcutURLController = new TextEditingController();
  var _customShortcutNameKey = GlobalKey<FormState>();
  var _customShortcutURLKey = GlobalKey<FormState>();

  String _currentUrl;
  String _pageTitle;

  @override
  void initState() {
    super.initState();

    _currentUrl = widget.url;
    _pageTitle = widget.title;

    _shortcutsProvider = Provider.of<ShortcutsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
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
                        "OPTIONS",
                        style: TextStyle(
                            fontSize: 12, color: _themeProvider.mainText),
                      ),
                    ),
                    SizedBox(height: 15),
                    Row(
                      children: [
                        Flexible(
                          child: Form(
                            key: _customURLKey,
                            child: Column(
                              mainAxisSize:
                                  MainAxisSize.min, // To make the card compact
                              children: <Widget>[
                                TextFormField(
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _themeProvider.mainText,
                                  ),
                                  controller: _customURLController,
                                  maxLength: 300,
                                  maxLines: 1,
                                  textInputAction: TextInputAction.go,
                                  onFieldSubmitted: (value) {
                                    onCustomURLSubmitted();
                                  },
                                  decoration: InputDecoration(
                                    counterText: "",
                                    isDense: true,
                                    border: OutlineInputBorder(),
                                    labelText: 'Browse URL',
                                  ),
                                  validator: (value) {
                                    if (value.replaceAll(' ', '').isEmpty) {
                                      return "Cannot be empty!";
                                    }
                                    // Try to force https
                                    if (value
                                        .toLowerCase()
                                        .contains('http://')) {
                                      _customURLController.text
                                          .replaceAll('http://', 'https://');
                                    }
                                    if (!value
                                        .toLowerCase()
                                        .contains('https://')) {
                                      _customURLController.text = 'https://' +
                                          _customURLController.text;
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.double_arrow_outlined),
                          onPressed: () async {
                            onCustomURLSubmitted();
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        //mainAxisAlignment: MainAxisAlign,
                        children: [
                          Icon(Icons.copy),
                          SizedBox(width: 5),
                          Text('Copy URL'),
                        ],
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _currentUrl));

                        // Avoid copying _currentUrl directly unless we await,
                        // otherwise we can change _currentUrl while the copy
                        // is being performed and hang the app
                        var copied = _currentUrl;
                        if (_currentUrl.length > 60) {
                          copied = _currentUrl.substring(0, 60) + "...";
                        }

                        BotToast.showText(
                          text: "Current URL copied to "
                              "the clipboard [$copied]",
                          textStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.white,
                          ),
                          contentColor: Colors.green,
                          duration: Duration(seconds: 5),
                          contentPadding: EdgeInsets.all(10),
                        );
                        _customURLController.text = "";
                        Navigator.of(context).pop();
                      },
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          //mainAxisAlignment: MainAxisAlign,
                          children: [
                            Image.asset(
                              'images/icons/heart.png',
                              width: 22,
                              color:
                                  _shortcutsProvider.activeShortcuts.length > 0
                                      ? Colors.white
                                      : Colors.grey,
                            ),
                            SizedBox(width: 5),
                            Text('Browse shortcuts'),
                          ],
                        ),
                        onPressed: _shortcutsProvider.activeShortcuts.length > 0
                            ? () {
                                Navigator.of(context).pop();
                                _openShortcutsDialog();
                                _customURLController.text = "";
                              }
                            : null),
                    SizedBox(height: 10),
                    ElevatedButton(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        //mainAxisAlignment: MainAxisAlign,
                        children: [
                          Image.asset(
                            'images/icons/heart_add.png',
                            width: 22,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8),
                          Text('Save as shortcut'),
                        ],
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _openCustomShortcutDialog(_pageTitle, _currentUrl);
                        _customURLController.text = "";
                      },
                    ),
                    SizedBox(height: 10),
                    ElevatedButton(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        //mainAxisAlignment: MainAxisAlign,
                        children: [
                          Icon(Icons.search),
                          SizedBox(width: 8),
                          Text('Find in page'),
                        ],
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        widget.callFindInPage();
                      },
                    ),
                    SizedBox(height: 8),
                    TextButton(
                      child: Text("Close"),
                      onPressed: () {
                        _customURLController.text = "";
                        Navigator.of(context).pop();
                      },
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
                  backgroundColor: _themeProvider.background,
                  radius: 22,
                  child: SizedBox(
                    height: 25,
                    width: 25,
                    child: Image.asset(
                      "images/icons/pda_icon.png",
                      width: 18,
                      height: 18,
                      color: _themeProvider.mainText,
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

  void onCustomURLSubmitted() {
    if (_customURLKey.currentState.validate()) {
      widget.webview.loadUrl(
        urlRequest: URLRequest(
          url: Uri.parse(_customURLController.text),
        ),
      );
      _customURLController.text = "";
      Navigator.of(context).pop();
    }
  }

  Future<void> _openCustomShortcutDialog(String title, String url) {
    _customShortcutNameController.text = title;
    _customShortcutURLController.text = url;
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
                            "Add a name and URL for your custom shortcut. Note: "
                            "ensure URL begins with 'https://'",
                            style: TextStyle(
                                fontSize: 12, color: _themeProvider.mainText),
                          ),
                        ),
                        SizedBox(height: 15),
                        Form(
                          key: _customShortcutNameKey,
                          child: Column(
                            mainAxisSize:
                                MainAxisSize.min, // To make the card compact
                            children: <Widget>[
                              TextFormField(
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _themeProvider.mainText,
                                ),
                                textCapitalization:
                                    TextCapitalization.sentences,
                                controller: _customShortcutNameController,
                                maxLength: 20,
                                maxLines: 1,
                                decoration: InputDecoration(
                                  counterText: "",
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  labelText: 'Name',
                                ),
                                validator: (value) {
                                  if (value.replaceAll(' ', '').isEmpty) {
                                    return "Cannot be empty!";
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 15),
                        Row(
                          children: [
                            Flexible(
                              child: Form(
                                key: _customShortcutURLKey,
                                child: Column(
                                  mainAxisSize: MainAxisSize
                                      .min, // To make the card compact
                                  children: <Widget>[
                                    TextFormField(
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: _themeProvider.mainText,
                                      ),
                                      controller: _customShortcutURLController,
                                      maxLength: 300,
                                      maxLines: 1,
                                      decoration: InputDecoration(
                                        counterText: "",
                                        isDense: true,
                                        border: OutlineInputBorder(),
                                        labelText: 'URL',
                                      ),
                                      validator: (value) {
                                        if (value.replaceAll(' ', '').isEmpty) {
                                          return "Cannot be empty!";
                                        }
                                        if (!value
                                            .toLowerCase()
                                            .contains('https://')) {
                                          if (value
                                              .toLowerCase()
                                              .contains('http://')) {
                                            return "Invalid, HTTPS needed!";
                                          }
                                        }
                                        return null;
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              child: Text("Add"),
                              onPressed: () {
                                if (!_customShortcutURLKey.currentState
                                    .validate()) {
                                  return;
                                }
                                if (!_customShortcutNameKey.currentState
                                    .validate()) {
                                  return;
                                }

                                var customShortcut = Shortcut()
                                  ..name = _customShortcutNameController.text
                                  ..nickname =
                                      _customShortcutNameController.text
                                  ..url = _customShortcutURLController.text
                                  ..iconUrl = 'images/icons/pda_icon.png'
                                  ..color = Colors.orange[500]
                                  ..isCustom = true;

                                _shortcutsProvider
                                    .activateShortcut(customShortcut);
                                Navigator.of(context).pop();
                                _customShortcutNameController.text = '';
                                _customURLController.text = '';
                              },
                            ),
                            TextButton(
                              child: Text("Close"),
                              onPressed: () {
                                Navigator.of(context).pop();
                                _customShortcutNameController.text = '';
                                _customURLController.text = '';
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
                        height: 25,
                        width: 25,
                        child: Image.asset(
                          "images/icons/pda_icon.png",
                          width: 18,
                          height: 18,
                          color: _themeProvider.mainText,
                        ),
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

  Future<void> _openShortcutsDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return WebviewShortcutsDialog(
          webview: widget.webview,
        );
      },
    );
  }
}
