// Flutter imports:
import 'dart:io';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:easy_rich_text/easy_rich_text.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
// Project imports:
import 'package:torn_pda/models/userscript_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/userscripts_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/settings/userscripts_add_dialog.dart';
import 'package:torn_pda/widgets/settings/userscripts_revert_dialog.dart';
import 'package:torn_pda/widgets/pda_browser_icon.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';
import 'package:url_launcher/url_launcher.dart';

class UserScriptsPage extends StatefulWidget {
  @override
  UserScriptsPageState createState() => UserScriptsPageState();
}

class UserScriptsPageState extends State<UserScriptsPage> {
  late ThemeProvider _themeProvider;
  late SettingsProvider _settingsProvider;
  late UserScriptsProvider _userScriptsProvider;
  late WebViewProvider _webViewProvider;

  bool _firstTimeNotAccepted = false;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _userScriptsProvider = Provider.of<UserScriptsProvider>(context, listen: false);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_userScriptsProvider.scriptsFirstTime) {
        await showDialog(
          useRootNavigator: false,
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return _firstTimeDialog();
          },
        );

        if (_firstTimeNotAccepted) {
          _goBack();
        }
      }
    });

    routeWithDrawer = false;
    routeName = "userscripts";
    _settingsProvider.willPopShouldGoBackStream.stream.listen((event) {
      if (mounted && routeName == "userscripts") _goBack();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    _webViewProvider = Provider.of<WebViewProvider>(context);
    return Container(
      color: _themeProvider.currentTheme == AppTheme.light
          ? MediaQuery.orientationOf(context) == Orientation.portrait
              ? Colors.blueGrey
              : _themeProvider.canvas
          : _themeProvider.canvas,
      child: SafeArea(
        right: _webViewProvider.webViewSplitActive && _webViewProvider.splitScreenPosition == WebViewSplitPosition.left,
        left: _webViewProvider.webViewSplitActive && _webViewProvider.splitScreenPosition == WebViewSplitPosition.right,
        child: Scaffold(
          backgroundColor: _themeProvider.canvas,
          appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
          bottomNavigationBar: !_settingsProvider.appBarTop
              ? SizedBox(
                  height: AppBar().preferredSize.height,
                  child: buildAppBar(),
                )
              : null,
          body: Container(
            color: _themeProvider.canvas,
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
                            backgroundColor: WidgetStateProperty.all<Color?>(_themeProvider.secondBackground),
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
                            color: _themeProvider.mainText,
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
                              backgroundColor: WidgetStateProperty.all<Color?>(_themeProvider.secondBackground),
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
                              Icons.refresh,
                              size: 20,
                              color: _themeProvider.mainText,
                            ),
                            onPressed: () => _userScriptsProvider.checkForUpdates().then((i) => BotToast.showText(
                                  text: i > 0
                                      ? "$i script${i == 1 ? " is" : "s are"} ready to update"
                                      : "No updates found",
                                  textStyle: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                  contentColor: i > 0 ? Colors.green[800]! : Colors.grey[800]!,
                                  contentPadding: const EdgeInsets.all(10),
                                )),
                          )),
                      const SizedBox(width: 15),
                      ButtonTheme(
                        minWidth: 1.0,
                        child: ElevatedButton(
                          style: ButtonStyle(
                            backgroundColor: WidgetStateProperty.all<Color?>(_themeProvider.secondBackground),
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
                            color: _themeProvider.mainText,
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
                      'Preexisting scripts might require modifications to work with Torn PDA. '
                      'Please ensure that you use scripts responsibly and '
                      'understand the hazards. Tap the exclamation mark for more information.',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Flexible(
                    child: Consumer<UserScriptsProvider>(
                      builder: (context, settingsProvider, child) => scriptsCards(),
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

  ListView scriptsCards() {
    final scriptList = <Widget>[];
    for (final script in _userScriptsProvider.userScriptList) {
      scriptList.add(
        Card(
          key: UniqueKey(),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      SizedBox(
                        height: 20,
                        width: 60,
                        child: Switch(
                          value: script.enabled,
                          activeTrackColor: Colors.green[100],
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.red[100],
                          onChanged: (value) {
                            _userScriptsProvider.changeUserScriptEnabled(script, value);
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Flexible(child: Text(script.name, style: const TextStyle(fontSize: 13))),
                    ],
                  ),
                ),
                Row(
                  children: [
                    if (script.updateStatus == UserScriptUpdateStatus.noRemote)
                      GestureDetector(
                        child: const Icon(
                          MdiIcons.alphaC,
                          color: Colors.grey,
                          size: 20,
                        ),
                        onTap: () async {
                          BotToast.showText(
                            text:
                                'This is a custom script without an update URL. It will not be updated automatically.',
                            textStyle: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            contentColor: Colors.grey[800]!,
                            contentPadding: const EdgeInsets.all(10),
                          );
                        },
                      )
                    else if (script.updateStatus == UserScriptUpdateStatus.localModified)
                      GestureDetector(
                          child: Icon(
                            script.isExample ? MdiIcons.lockOff : MdiIcons.earthOff,
                            color: Colors.orange,
                            size: 20,
                          ),
                          onTap: () async {
                            BotToast.showText(
                              text:
                                  "This is a${script.isExample ? "n example" : ""} script that you have edited, so it will not update. Reset changes to enable updates again.",
                              textStyle: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              contentColor: Colors.grey[800]!,
                              contentPadding: const EdgeInsets.all(10),
                            );
                          })
                    else if (script.updateStatus == UserScriptUpdateStatus.upToDate)
                      GestureDetector(
                          child: Icon(script.isExample ? MdiIcons.lock : MdiIcons.earth, color: Colors.green, size: 20),
                          onTap: () async {
                            BotToast.showText(
                              text:
                                  "This ${script.isExample ? "example " : ""}script is up-to-date (v${script.version})",
                              textStyle: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              contentColor: Colors.grey[800]!,
                              contentPadding: const EdgeInsets.all(10),
                            );
                          })
                    else if (script.updateStatus == UserScriptUpdateStatus.updateAvailable)
                      GestureDetector(
                          child: Icon(script.isExample ? MdiIcons.lockPlus : MdiIcons.earthPlus,
                              color: Colors.red, size: 20),
                          onTap: () async {
                            BotToast.showText(
                              text: "An update is available (currently on v${script.version})",
                              textStyle: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              contentColor: Colors.grey[800]!,
                              contentPadding: const EdgeInsets.all(10),
                            );
                            showDialog(
                                builder: (c) => UserScriptsAddDialog(
                                      editScript: script,
                                      editExisting: true,
                                      defaultPage: 1,
                                    ),
                                context: context);
                          })
                    else if (script.updateStatus == UserScriptUpdateStatus.error)
                      GestureDetector(
                          child: const Icon(MdiIcons.earthRemove, color: Colors.red, size: 20),
                          onTap: () async {
                            BotToast.showText(
                              text: "An error occurred while checking for updates. Please try again later.",
                              textStyle: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                              ),
                              contentColor: Colors.grey[800]!,
                              contentPadding: const EdgeInsets.all(10),
                            );
                          })
                    else if (script.updateStatus == UserScriptUpdateStatus.updating)
                      GestureDetector(
                          child: const SizedBox(width: 20, height: 20, child: CircularProgressIndicator()),
                          onTap: () async => BotToast.showText(
                                text: "Checking for updates...",
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                contentColor: Colors.grey[800]!,
                                contentPadding: const EdgeInsets.all(10),
                              ))
                    else
                      GestureDetector(
                        child: const Icon(MdiIcons.helpCircle, color: Colors.blue, size: 20),
                        onTap: () async {
                          BotToast.showText(
                            text: "The update status of this script could not be determined.",
                            textStyle: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            contentColor: Colors.grey[800]!,
                            contentPadding: const EdgeInsets.all(10),
                          );
                        },
                      ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      child: const Icon(Icons.edit, size: 20),
                      onTap: () {
                        showDialog<void>(
                          context: context,
                          barrierDismissible: false, // user must tap button!
                          builder: (BuildContext context) {
                            return UserScriptsAddDialog(
                              editExisting: true,
                              editScript: script,
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      child: Icon(
                        Icons.delete_outlined,
                        color: Colors.red[300],
                        size: 20,
                      ),
                      onTap: () async {
                        _openDeleteSingleDialog(script);
                      },
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView(
      children: scriptList,
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      toolbarHeight: 50,
      title: const Text('User scripts', style: TextStyle(color: Colors.white)),
      leadingWidth: _webViewProvider.webViewSplitActive ? 50 : 88,
      leading: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _goBack();
            },
          ),
          if (!_webViewProvider.webViewSplitActive) const PdaBrowserIcon() else Container(),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(
            MdiIcons.backupRestore,
          ),
          onPressed: () async {
            _openRestoreDialog();
          },
        ),
        IconButton(
          icon: Icon(
            MdiIcons.alertDecagramOutline,
            color: Colors.orange[300],
          ),
          onPressed: () async {
            await showDialog(
              useRootNavigator: false,
              context: context,
              builder: (BuildContext context) {
                return _disclaimerDialog();
              },
            );
          },
        ),
      ],
    );
  }

  Future<void> _showAddDialog(BuildContext _) {
    return showDialog<void>(
      context: _,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return const UserScriptsAddDialog(editExisting: false);
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
                        const Flexible(
                          child: Text(
                            "CAUTION",
                            style: TextStyle(fontSize: 13, color: Colors.red),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Flexible(
                          child: Text(
                            "This will remove all user scripts!",
                            style: TextStyle(fontSize: 12, color: _themeProvider.mainText),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Flexible(
                          child: Text(
                            "Are you sure?",
                            style: TextStyle(fontSize: 12, color: _themeProvider.mainText),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              child: const Text("Do it!"),
                              onPressed: () {
                                _userScriptsProvider.wipe();
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
                    backgroundColor: _themeProvider.secondBackground,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider.secondBackground,
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

  Future<void> _openDeleteSingleDialog(UserScriptModel script) {
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
                        Flexible(
                          child: Text(
                            "Remove ${script.name}?",
                            style: TextStyle(fontSize: 12, color: _themeProvider.mainText),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: <Widget>[
                            TextButton(
                              child: const Text("Do it!"),
                              onPressed: () {
                                _userScriptsProvider.removeUserScript(script);
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
                    backgroundColor: _themeProvider.secondBackground,
                    child: CircleAvatar(
                      backgroundColor: _themeProvider.secondBackground,
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

  Future<void> _openRestoreDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return UserScriptsRevertDialog();
      },
    );
  }

  AlertDialog _disclaimerDialog() {
    return AlertDialog(
      title: const Text("DISCLAIMER"),
      content: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "User scripts are small programs written in JavaScript that enhance the browser's "
                  "functionalities. Be careful when using them and ensure that you understand the code "
                  "and what the script accomplishes; otherwise, ensure they come from a reliable "
                  "source and have been checked by someone you trust.\n\n"
                  "As in any other browser, user scripts might be used maliciously to get information "
                  "from your Torn account or other websites you visit.",
                  style: TextStyle(
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  "TIPS",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                EasyRichText(
                  "Join our Discord server if you need help or are willing to contribute with new userscripts ideas or working code. "
                  "There is a list of tested userscripts in our GitHub repository.",
                  patternList: [
                    EasyRichTextPattern(
                      targetString: 'Discord server',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Colors.blue[400],
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          const url = 'https://discord.gg/vyP23kJ';
                          if (await canLaunchUrl(Uri.parse(url))) {
                            await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                          }
                        },
                    ),
                    EasyRichTextPattern(
                      targetString: 'list of tested userscripts',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Colors.blue[400],
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () async {
                          const url = 'https://github.com/Manuito83/torn-pda/tree/master/userscripts';
                          await context.read<WebViewProvider>().openBrowserPreference(
                                context: context,
                                url: url,
                                browserTapType: BrowserTapType.short,
                              );
                        },
                    ),
                  ],
                  defaultStyle: TextStyle(
                    fontSize: 13,
                    color: _themeProvider.mainText,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  "Any remote script needs to have a valid header, or else the remote install will fail. "
                  "Local UserScripts do not have this constraint, although without a valid header the match pattern "
                  "will not be validated and the script will be injected in all pages.",
                  style: TextStyle(
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                    "The remote URL can be any URL that returns a plaintext file with a valid userscript header. "
                    "However, the popup will only be added automatically on requests with the \"text/javascript\" "
                    "content-type header. If you want to add a script that does not have this header (such as "
                    "raw GitHub links) you must copy the url and navigate to the userscript section to add it.",
                    style: TextStyle(fontSize: 13)),
                const SizedBox(height: 10),
                const Text(
                    "You can use the text '###PDA-APIKEY###' in a script instead of your real API key. "
                    "Torn PDA will replace it with your API key in runtime.",
                    style: TextStyle(fontSize: 13)),
                const SizedBox(height: 10),
                const Text(
                    "User scripts are isolated from one another on runtime and executed inside anonymous functions. "
                    "There is no need for you to adapt them this way.",
                    style: TextStyle(fontSize: 13)),
                const SizedBox(height: 25),
                const Text(
                  "TROUBLESHOOTING",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                    "Preexisting Torn user scripts (e.g. for GreaseMonkey) may require some "
                    "code changes to work with Torn PDA if external libraries were used. If you are an advanced user, "
                    "please scroll down to the 'GM handlers' section for more information an alternatives.\n\n"
                    "If a script does not work as intended after changing its code in Torn PDA, please "
                    "try resetting your browser cache in the advanced browser settings section.",
                    style: TextStyle(fontSize: 13)),
                const SizedBox(height: 25),
                const Text(
                  "INJECTION CONSTRAINTS",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text(
                    "Torn PDA injects user scripts by using the native WebView of your device. It will try to comply "
                    "as much as possible with script injection times and URLs. However, due to the different limitations "
                    "imposed by the native platform, scripts might be injected twice in certain pages, or will need to "
                    "be injected again in pages with pagination (e.g.: jail, hospital, forums...). Also, reloading the "
                    "page might result in scripts being injected multiple times.\n\n"
                    "Hence, it's the script developer's responsibility to control all these constraints. A few ideas: "
                    "make sure that that the script is prepared for multiple injection retries by adding a variable to "
                    "the main container; make sure that pagination works by adding click listeners; make sure that no "
                    "conflicts exist with other scripts (variable names, etc.) by enclosing the script in an "
                    "anonymous function.",
                    style: TextStyle(fontSize: 13)),
                const SizedBox(height: 25),
                const Text(
                  "SCRIPT INJECTION TIME",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                const Text.rich(
                  TextSpan(
                    text: "Torn PDA can try to inject user scripts at two different moments: before the HTML Document "
                        "loads (START) and after the load has been completed (END). The user can select when each "
                        "script should be loaded by editing its details.\n\n"
                        "By loading the script at the ",
                    style: TextStyle(
                      fontSize: 13,
                    ),
                    children: [
                      TextSpan(
                        text: "START",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: ", you might be able to fetch resources loading and ajax calls, for example. However, "
                            "Torn PDA will inject the script even before the HTML Document or jQuery are available; "
                            "therefore, you need to plan for this and check their availability before doing any work. "
                            "This can be accomplished with ",
                      ),
                      TextSpan(
                        text: "intervals",
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      TextSpan(
                        text: " or properties such as ",
                      ),
                      TextSpan(
                        text: "'Document.readyState'",
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      TextSpan(
                        text: " or checks like ",
                      ),
                      TextSpan(
                        text: "'typeof window.jQuery'",
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      TextSpan(
                        text: ".",
                      ),
                      TextSpan(
                        text: "\n\n"
                            "By loading the script at the ",
                        style: TextStyle(
                          fontSize: 13,
                        ),
                        children: [
                          TextSpan(
                            text: "END",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: ", Torn PDA will wait until the main HTML Document has loaded to inject the script. "
                                "However, please be aware that there might be some items being dynamically "
                                "loaded (e.g.: items list, jail and hospital lists, etc.), so it might still be "
                                "necessary to ensure that certain elements are available before doing any work.",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                if (Platform.isIOS)
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "UNSUPPORTED WINDOWS (iOS)",
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Be aware that user scripts injection at LOAD START is NOT supported on iOS when a tab has been opened as a 'new window' (e.g. "
                        "when a link is long-pressed and 'open in a new window' is selected, when a pop-up window opens, or when a new tab "
                        "is opened automatically from the HTML code)."
                        "\n\nIn these cases, a warning will appear in the Terminal. "
                        "The only work-around is to open pages as standard tabs by adding them manually if you need user script support. Alternatively, "
                        "injection at LOAD END should work with no issues.",
                        style: TextStyle(
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(height: 25),
                    ],
                  ),
                const Text(
                  "CROSS-ORIGIN REQUESTS (ADVANCED)",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    text: "Torn limits cross-origin requests via the content-security-policy header. In order to "
                        "allow other APIs to be called from within the browser (though an userscript), Torn PDA "
                        "incorporates its own JavasScript API.\n\n"
                        "For more information regarding GET and POST calls, please visit the ",
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                    children: [
                      TextSpan(
                        text: "JavasScript API implementation",
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            const String scriptApiUrl =
                                "https://github.com/Manuito83/torn-pda/tree/master/userscripts/TornPDA_API.js";
                            if (await canLaunchUrl(Uri.parse(scriptApiUrl))) {
                              await launchUrl(Uri.parse(scriptApiUrl), mode: LaunchMode.externalApplication);
                            }
                          },
                      ),
                      const TextSpan(
                        text: ".",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  "JAVASCRIPT HANDLER (ADVANCED)",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    text: "Torn limits the use of the eval() function in javascript via the content-security-policy "
                        "header. In order to allow the execution of javascript code retrieved at runtime by userscripts, "
                        " Torn PDA incorporates a handler through which source code can be passed which is then "
                        "evaluated directly from the app.\n\n"
                        "For more information, please visit the ",
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                    children: [
                      TextSpan(
                        text: "EvaluateJavascript Handler implementation",
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            const String scriptApiUrl =
                                "https://github.com/Manuito83/torn-pda/tree/master/userscripts/TornPDA_EvaluateJavascript.js";
                            if (await canLaunchUrl(Uri.parse(scriptApiUrl))) {
                              await launchUrl(Uri.parse(scriptApiUrl), mode: LaunchMode.externalApplication);
                            }
                          },
                      ),
                      const TextSpan(
                        text: ".",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  "GM HANDLERS (ADVANCED)",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    text: "As a general rule, Torn PDA supports standard Javascript and jQuery, but it does not "
                        "include any external libraries that are served in frameworks such as GM or TM. Therefore, "
                        "if you are trying to use a script that was developed for another platform or that won't even "
                        "work in your (desktop) browser console, you might need to adapt the code.\n\n"
                        "However, Torn PDA incorporates basic GM handlers to make life easier when converting scripts, "
                        "supporting dot notation (e.g.: 'GM.addStyle') and underscode notation (e.g.: 'GM_addStyle').\n\n"
                        "Whilst these handlers supply vanilla JS counterparts to the GM_ functions, they cannot prepare "
                        "your script to run on mobile devices: viewports are different, the page looks different, "
                        "some selectors change, etcetera. So even if using these handlers, be prepared to adapt "
                        "your script as necessary.\n\n"
                        "For more information on how to proceed, please visit the ",
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                    children: [
                      TextSpan(
                        text: "GM-For-PDA handler implementation",
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            const String scriptApiUrl =
                                "https://github.com/Manuito83/torn-pda/blob/master/userscripts/GMforPDA.user.js";
                            if (await canLaunchUrl(Uri.parse(scriptApiUrl))) {
                              await launchUrl(Uri.parse(scriptApiUrl), mode: LaunchMode.externalApplication);
                            }
                          },
                      ),
                      const TextSpan(
                        text: ".\n\nAlso, in case of doubt, please head to our Discord server where "
                            "we will be delighted to support you with this.\n\n"
                            "Credit goes to Kwack for the development and testing of this integration.\n\n",
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),
                const Text(
                  "NOTIFICATION HANDLERS (ADVANCED)",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text.rich(
                  TextSpan(
                    text: "You can schedule native notifications (+ alarms and timers on Android) from JS code "
                        "by using the notification handlers. To learn more about this and the different handlers avaiblable "
                        ", please visit the docs section in Github\n\n",
                    style: const TextStyle(
                      fontSize: 13,
                    ),
                    children: [
                      TextSpan(
                        text: "Notification Handlers wiki",
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            const String url =
                                "https://github.com/Manuito83/torn-pda/blob/develop/docs/webview/notification-handlers.md";
                            await context.read<WebViewProvider>().openBrowserPreference(
                                  context: context,
                                  url: url,
                                  browserTapType: BrowserTapType.short,
                                );
                          },
                      ),
                      const TextSpan(
                        text: "\n\nAlso, you can access this website to try out the different paramenters and "
                            "trigger a real action in your mobile device: ",
                      ),
                      TextSpan(
                        text: "\n\nNotification Handlers test website",
                        style: const TextStyle(
                          decoration: TextDecoration.underline,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () async {
                            const String url = "https://info.tornpda.com/notifications-test.html";
                            await context.read<WebViewProvider>().openBrowserPreference(
                                  context: context,
                                  url: url,
                                  browserTapType: BrowserTapType.short,
                                );
                          },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            child: const Text("Understood"),
            onPressed: () {
              Navigator.of(context).pop('exit');
            },
          ),
        ),
      ],
    );
  }

  WillPopScope _firstTimeDialog() {
    // Will show for users updating to V2, as well as new users.
    return WillPopScope(
      onWillPop: () async => false,
      child: AlertDialog(
        title: const Text("CAUTION"),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Be careful when using user scripts and ensure that you understand the code "
                "and what it accomplishes; otherwise, ensure they come from a reliable "
                "source and have been checked by someone you trust.\n\n"
                "As in any other browser, user scripts might be used maliciously to get information "
                "from your Torn account or other websites you visit.",
                style: TextStyle(
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Torn PDA has recently added support for remote scripts. Even though these scripts "
                "may have been safe previously, malicious updates can be added. Ensure you verify all changes "
                "before you install any updates from scripts. If you are unsure, please reach out in the "
                "UserScripts section of the Discord server.",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Please, read the disclaimer by pressing the warning icon in the app bar for "
                "more information.",
                style: TextStyle(
                  fontSize: 13,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "Do you understand the risk?",
                style: TextStyle(
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              child: const Text("Yes, I promise!"),
              onPressed: () {
                _userScriptsProvider.changeScriptsFirstTime(false);
                Navigator.of(context).pop('exit');
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextButton(
              child: const Text("What?!"),
              onPressed: () {
                _firstTimeNotAccepted = true;
                BotToast.showText(
                  text: 'Returning...!',
                  textStyle: const TextStyle(
                    fontSize: 14,
                    color: Colors.white,
                  ),
                  contentColor: Colors.orange[800]!,
                  contentPadding: const EdgeInsets.all(10),
                );
                Navigator.of(context).pop('exit');
              },
            ),
          ),
        ],
      ),
    );
  }

  _goBack() {
    routeWithDrawer = false;
    routeName = "settings_browser";
    Navigator.of(context).pop();
  }
}
