import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/profile/status_icons_wrap.dart';

class IconsFilterPage extends StatefulWidget {
  const IconsFilterPage({@required this.settingsProvider, Key key}) : super(key: key);

  final SettingsProvider settingsProvider;

  @override
  _IconsFilterPageState createState() => _IconsFilterPageState();
}

class _IconsFilterPageState extends State<IconsFilterPage> {
  List<String> filteredIcons = <String>[];
  ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    filteredIcons = widget.settingsProvider.iconsFiltered;

    var s = Provider.of<SettingsProvider>(context, listen: false);
    routeWithDrawer = false;
    routeName = "icons_filter_page";
    s.willPopShouldGoBack.stream.listen((event) {
      if (mounted && routeName == "icons_filter_page") _goBack();
    });
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Container(
      color: _themeProvider.currentTheme == AppTheme.light
          ? MediaQuery.of(context).orientation == Orientation.portrait
              ? Colors.blueGrey
              : _themeProvider.canvas
          : _themeProvider.canvas,
      child: SafeArea(
        child: Scaffold(
          backgroundColor: _themeProvider.canvas,
          appBar: widget.settingsProvider.appBarTop ? buildAppBar() : null,
          bottomNavigationBar: !widget.settingsProvider.appBarTop
              ? SizedBox(
                  height: AppBar().preferredSize.height,
                  child: buildAppBar(),
                )
              : null,
          body: Container(
            color: _themeProvider.canvas,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                    child: Text("Select which icons you would like to include as part of the Profile section's header"),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 50),
                    child: ListView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      itemCount: allowedIcons.length,
                      itemBuilder: (context, i) {
                        String key = allowedIcons.keys.elementAt(i);
                        return _iconFilterCard(key, allowedIcons[key]);
                      },
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

  AppBar buildAppBar() {
    return AppBar(
      //brightness: Brightness.dark, // For downgrade to Flutter 2.2.3
      elevation: widget.settingsProvider.appBarTop ? 2 : 0,
      title: Text("Filter icons"),
      leading: new IconButton(
        icon: new Icon(Icons.arrow_back),
        onPressed: () {
          _goBack();
        },
      ),
    );
  }

  Widget _iconFilterCard(String key, Map<String, String> values) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Image.asset('images/icons/status/${key}.png', width: 24),
                    SizedBox(width: 10),
                    Flexible(
                      child: Text(values["name"]),
                    ),
                  ],
                ),
              ),
              if (values["url"].isNotEmpty)
                IconButton(
                  icon: Icon(Icons.link),
                  onPressed: () {
                    BotToast.showText(
                      text: "This icon will open a browser (on double or long tap) to the appropriate section in game",
                      textStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      contentColor: Colors.blue[700],
                      duration: Duration(seconds: 5),
                      contentPadding: EdgeInsets.all(10),
                    );
                  },
                ),
              Switch(
                activeColor: Colors.green,
                activeTrackColor: Colors.green[200],
                inactiveThumbColor: Colors.red,
                inactiveTrackColor: Colors.red[200],
                value: !widget.settingsProvider.iconsFiltered.contains(key) || false,
                onChanged: (value) {
                  setState(() {
                    List<String> newList = widget.settingsProvider.iconsFiltered;
                    if (value) {
                      newList.remove(key);
                      widget.settingsProvider.changeIconsFiltered = newList;
                    } else {
                      newList.add(key);
                      widget.settingsProvider.changeIconsFiltered = newList;
                    }
                  });
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  _goBack() {
    routeWithDrawer = false;
    routeName = "profile_notifications";
    Navigator.of(context).pop();
  }
}
