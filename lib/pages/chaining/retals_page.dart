// Dart imports:
import 'dart:async';
// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/retal_model.dart';
// Project imports:
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/retals_controller.dart';
import 'package:torn_pda/widgets/chaining/chain_widget.dart';
import 'package:torn_pda/widgets/chaining/retal_card.dart';
import 'package:torn_pda/widgets/countdown.dart';

class WarOptions {
  String description;
  IconData iconData;

  WarOptions({this.description}) {
    switch (description) {
      case "Toggle chain widget":
        iconData = MdiIcons.linkVariant;
        break;
      case "Hidden targets":
        iconData = Icons.undo_outlined;
        break;
      case "Nuke revive":
        // Own icon in widget
        break;
      case "UHC revive":
        // Own icon in widget
        break;
    }
  }
}

class RetalsPage extends StatefulWidget {
  //final Function tabCallback;

  const RetalsPage({
    Key key,
    //@required this.tabCallback,
  }) : super(key: key);

  @override
  _RetalsPageState createState() => _RetalsPageState();
}

class _RetalsPageState extends State<RetalsPage> {
  final _chainWidgetKey = GlobalKey();

  RetalsController _r;
  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
  }

  @override
  Future dispose() async {
    Get.delete<RetalsController>();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_r == null) {
      _r = Get.put(RetalsController());
    }

    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Scaffold(
      backgroundColor: _themeProvider.canvas,
      drawer: const Drawer(),
      appBar: _settingsProvider.appBarTop ? buildAppBar(context) : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(context),
            )
          : null,
      body: GetBuilder<RetalsController>(
        builder: (r) => Container(
          color: _themeProvider.currentTheme == AppTheme.extraDark ? Colors.black : Colors.transparent,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
            child: MediaQuery.of(context).orientation == Orientation.portrait
                ? Column(
                    children: [
                      _topWidgets(r),
                      Flexible(child: _mainCards(r)),
                    ],
                  )
                : r.retaliationList.isEmpty
                    ? Column(
                        children: [
                          _topWidgets(r),
                          Flexible(child: _mainCards(r)),
                        ],
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            _topWidgets(r),
                            _mainCards(r),
                          ],
                        ),
                      ),
          ),
        ),
      ),
    );
  }

  Widget _topWidgets(RetalsController r) {
    return Column(
      children: <Widget>[
        ChainWidget(
          key: _chainWidgetKey,
          alwaysDarkBackground: false,
          callBackOptions: _callBackChainOptions,
        ),
        r.updating
            ? CircularProgressIndicator()
            : Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Next update in "),
                    Countdown(
                      seconds: 20,
                      callback: _updateRetal,
                    ),
                    Text(" seconds"),
                  ],
                ),
              ),
      ],
    );
  }

  Widget _mainCards(RetalsController r) {
    return Column(
      children: <Widget>[
        const SizedBox(height: 5),
        r.retaliationList.isEmpty
            ? Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 100),
                      child: Text("No retaliation targets found!"),
                    ),
                  ],
                ),
              )
            : context.orientation == Orientation.portrait
                ? Flexible(
                    child: RetalsTargetsList(
                      retalsController: r,
                    ),
                  )
                : RetalsTargetsList(
                    retalsController: r,
                  ),
        if (_settingsProvider.appBarTop) SizedBox(height: 50),
      ],
    );
  }

  AppBar buildAppBar(BuildContext _) {
    return AppBar(
      //brightness: Brightness.dark, // For downgrade to Flutter 2.2.3
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: const Text("Retaliation"),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          final ScaffoldState scaffoldState = context.findRootAncestorStateOfType();
          scaffoldState.openDrawer();
        },
      ),
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: GetBuilder<RetalsController>(
            builder: (r) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  child: Icon(Icons.info_outline_rounded),
                  // Quick update
                  onTap: () async {
                    await showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return _disclaimerDialog();
                      },
                    );
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: GetBuilder<RetalsController>(
            builder: (r) {
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  child: Icon(Icons.refresh),
                  onTap: r.updating
                      ? null
                      : () {
                          r.retrieveRetals(context);
                        },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _callBackChainOptions() {
    setState(() {
      // Makes sure to update cards' border when out of panic options
    });
  }

  _updateRetal() {
    if (_r.browserIsOpen) return;
    _r.retrieveRetals(context);
  }

  _disclaimerDialog() {
    return AlertDialog(
      title: Text("Retaliation"),
      content: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "A retaliation hit is an attack (hospitalisation only) made on someone that has attacked one of "
                  "your faction members within the last 5 minutes. Retaliations provide a multiplier of 1.5x, and can "
                  "only be claimed once on a player until they attack your faction again.",
                  style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic),
                ),
                SizedBox(height: 25),
                Text(
                  "This section shows targets that:\n",
                  style: TextStyle(fontSize: 13),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    "- Attacked your faction in the last 5 minutes",
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    "- Won the attack",
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    "- Have not been retaliated yet",
                    style: TextStyle(fontSize: 13),
                  ),
                ),
                SizedBox(height: 25),
                Text(
                  "IMPORTANT",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
                Text(
                  "\nPlease note that this section can potentially make a intensive use of the API if there are "
                  "lots of targets available to retaliate.\n\nIt will auto-update every few seconds; any attempt to "
                  "manually update at lower intervals could result in the API limits being reached in this or other "
                  "sections.",
                  style: TextStyle(fontSize: 13),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: TextButton(
            child: Text("Understood"),
            onPressed: () {
              Navigator.of(context).pop('exit');
            },
          ),
        ),
      ],
    );
  }
}

class RetalsTargetsList extends StatelessWidget {
  RetalsTargetsList({
    @required this.retalsController,
  });

  final RetalsController retalsController;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      return ListView(
        shrinkWrap: true,
        children: getChildrenTargets(),
      );
    } else {
      return ListView(
        children: getChildrenTargets(),
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
      );
    }
  }

  List<Widget> getChildrenTargets() {
    List<RetalCard> filteredCards = <RetalCard>[];

    for (Retal thisRetal in retalsController.retaliationList) {
      filteredCards.add(
        RetalCard(
          key: UniqueKey(),
          retalModel: thisRetal,
          expiryTimeStamp: thisRetal.retalExpiry,
        ),
      );
    }

    filteredCards.sort((a, b) => b.expiryTimeStamp.compareTo(a.expiryTimeStamp));

    retalsController.orderedCardsDetails.clear();
    for (int i = 0; i < filteredCards.length; i++) {
      RetalsCardDetails details = RetalsCardDetails()
        ..cardPosition = i + 1
        ..retalId = filteredCards[i].retalModel.retalId
        ..name = filteredCards[i].retalModel.name
        ..personalNote = filteredCards[i].retalModel.personalNote
        ..personalNoteColor = filteredCards[i].retalModel.personalNoteColor;

      retalsController.orderedCardsDetails.add(details);
    }

    return filteredCards;
  }
}
