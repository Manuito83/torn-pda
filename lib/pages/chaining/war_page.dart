// Dart imports:
import 'dart:async';
// Package imports:
import 'package:bot_toast/bot_toast.dart';
// Flutter imports:
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
// Project imports:
import 'package:torn_pda/models/chaining/war_sort.dart';
import 'package:torn_pda/models/faction/faction_model.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/providers/war_controller.dart';
import 'package:torn_pda/widgets/chaining/chain_widget.dart';
import 'package:torn_pda/widgets/chaining/war_card.dart';
import '../../main.dart';

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
      case "Information":
        iconData = Icons.info_outline_rounded;
        break;
    }
  }
}

class WarPage extends StatefulWidget {
  final String userKey;
  //final Function tabCallback;

  const WarPage({
    Key key,
    @required this.userKey,
    //@required this.tabCallback,
  }) : super(key: key);

  @override
  _WarPageState createState() => _WarPageState();
}

class _WarPageState extends State<WarPage> {
  final _searchController = TextEditingController();
  final _addIdController = TextEditingController();

  final _addFormKey = GlobalKey<FormState>();

  final _chainWidgetKey = GlobalKey();

  final WarController _w = Get.put(WarController());
  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;

  final _popupSortChoices = <WarSort>[
    WarSort(type: WarSortType.levelDes),
    WarSort(type: WarSortType.levelAsc),
    WarSort(type: WarSortType.respectDes),
    WarSort(type: WarSortType.respectAsc),
    WarSort(type: WarSortType.nameDes),
    WarSort(type: WarSortType.nameAsc),
    WarSort(type: WarSortType.colorAsc),
    WarSort(type: WarSortType.colorDes),
  ];

  final _popupOptionsChoices = <WarOptions>[
    WarOptions(description: "Toggle chain widget"),
    WarOptions(description: "Hidden targets"),
    WarOptions(description: "Information"),
  ];

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    analytics.logEvent(name: 'section_changed', parameters: {'section': 'war'});
  }

  @override
  Future dispose() async {
    _addIdController.dispose();
    _searchController.dispose();
    _w.stopUpdate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Scaffold(
      drawer: const Drawer(),
      appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(
              height: AppBar().preferredSize.height,
              child: buildAppBar(),
            )
          : null,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
        child: MediaQuery.of(context).orientation == Orientation.portrait
            ? _mainColumn()
            : SingleChildScrollView(
                child: _mainColumn(),
              ),
      ),
    );
  }

  Widget _mainColumn() {
    return GetBuilder<WarController>(builder: (w) {
      int hiddenMembers = w.getHiddenMembersNumber();
      return Column(
        children: <Widget>[
          if (w.factions.where((f) => f.hidden).length > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "${w.factions.where((f) => f.hidden).length} "
                "${w.factions.where((f) => f.hidden).length == 1 ? 'faction is' : 'factions are'} filtered out",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange[700],
                ),
              ),
            ),
          if (hiddenMembers > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                "${hiddenMembers} ${hiddenMembers == 1 ? 'target is' : 'targets are'} hidden",
                style: TextStyle(
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 5),
          if (w.showChainWidget)
            ChainWidget(
              key: _chainWidgetKey,
              userKey: widget.userKey,
              alwaysDarkBackground: false,
            ),
          context.orientation == Orientation.portrait
              ? Flexible(
                  child: WarTargetsList(warController: w),
                )
              : WarTargetsList(warController: w),
          SizedBox(height: 50),
        ],
      );
    });
  }

  AppBar buildAppBar() {
    return AppBar(
      brightness: Brightness.dark,
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      title: const Text("War"),
      leading: IconButton(
        icon: const Icon(Icons.menu),
        onPressed: () {
          final ScaffoldState scaffoldState = context.findRootAncestorStateOfType();
          scaffoldState.openDrawer();
        },
      ),
      actions: <Widget>[
        IconButton(
          icon: Image.asset(
            'images/icons/faction.png',
            width: 18,
            height: 18,
            color: Colors.white,
          ),
          onPressed: () {
            _showAddDialog(context);
          },
        ),
        GetBuilder<WarController>(
          builder: (w) {
            if (w.updating)
              return IconButton(
                icon: Icon(
                  MdiIcons.closeOctagonOutline,
                  color: Colors.orange[700],
                ),
                onPressed: () async {
                  _w.stopUpdate();
                },
              );
            else
              return IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () async {
                  String message = "";
                  Color messageColor = Colors.green;
                  // Count all members
                  int allMembers = 0;
                  int updatedMembers = 0;
                  for (FactionModel f in _w.factions.where((f) => !f.hidden)) {
                    allMembers += f.members.values.where((m) => !m.hidden).length;
                  }

                  if (allMembers == 0) {
                    message = "No targets to update!";
                    messageColor = Colors.orange[700];
                  } else {
                    if (allMembers > 60) {
                      BotToast.showText(
                        text: "Updating $allMembers war targets, this might take a while. Extra time needed to avoid "
                            "issues with API request limits!",
                        textStyle: const TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                        ),
                        contentColor: messageColor,
                        duration: const Duration(seconds: 3),
                        contentPadding: const EdgeInsets.all(10),
                      );
                    }
                    updatedMembers = await _w.updateAllMembers(widget.userKey);
                  }

                  if (updatedMembers > 0 && updatedMembers == allMembers) {
                    message = 'Successfully updated $updatedMembers war targets!';
                  } else if (updatedMembers > 0 && updatedMembers < allMembers) {
                    message = 'Updated $updatedMembers war targets, but ${allMembers - updatedMembers} failed!';
                    messageColor = Colors.orange[700];
                  }

                  if (mounted) {
                    BotToast.showText(
                      text: message,
                      textStyle: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      contentColor: messageColor,
                      duration: const Duration(seconds: 3),
                      contentPadding: const EdgeInsets.all(10),
                    );
                  }
                },
              );
          },
        ),
        PopupMenuButton<WarSort>(
          icon: const Icon(
            Icons.sort,
          ),
          onSelected: _selectSortPopup,
          itemBuilder: (BuildContext context) {
            return _popupSortChoices.map((WarSort choice) {
              return PopupMenuItem<WarSort>(
                value: choice,
                child: Text(
                  choice.description,
                  style: const TextStyle(
                    fontSize: 13,
                  ),
                ),
              );
            }).toList();
          },
        ),
        PopupMenuButton<WarOptions>(
          icon: const Icon(Icons.settings),
          onSelected: (selection) {
            switch (selection.description) {
              case "Toggle chain widget":
                _w.toggleChainWidget();
                break;
              case "Hidden targets":
                _showHiddenMembersDialogs(context);
                break;
              case "Information":
                print("3"); // TODO
                break;
            }
          },
          itemBuilder: (BuildContext context) {
            return _popupOptionsChoices.map((WarOptions choice) {
              if (choice.description.contains("Hidden") && _w.getHiddenMembersNumber() == 0) {
                return null;
              }
              return PopupMenuItem<WarOptions>(
                value: choice,
                child: Row(
                  children: [
                    Icon(choice.iconData, size: 20, color: _themeProvider.mainText),
                    const SizedBox(width: 10),
                    Text(choice.description),
                  ],
                ),
              );
            }).toList();
          },
        )
      ],
    );
  }

  Future<void> _showAddDialog(BuildContext _) {
    return showDialog<void>(
      context: _,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return GetBuilder<WarController>(
          builder: (w) => AddFactionDialog(
            themeProvider: _themeProvider,
            addFormKey: _addFormKey,
            addIdController: _addIdController,
            warController: w,
          ),
        );
      },
    );
  }

  Future<void> _showHiddenMembersDialogs(BuildContext _) {
    return showDialog<void>(
      context: _,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return GetBuilder<WarController>(
          builder: (w) => HiddenMembersDialog(
            themeProvider: _themeProvider,
            warController: w,
          ),
        );
      },
    );
  }

  void _selectSortPopup(WarSort choice) {
    switch (choice.type) {
      case WarSortType.levelDes:
        _w.sortTargets(WarSortType.levelDes);
        break;
      case WarSortType.levelAsc:
        _w.sortTargets(WarSortType.levelAsc);
        break;
      case WarSortType.respectDes:
        _w.sortTargets(WarSortType.respectDes);
        break;
      case WarSortType.respectAsc:
        _w.sortTargets(WarSortType.respectAsc);
        break;
      case WarSortType.nameDes:
        _w.sortTargets(WarSortType.nameDes);
        break;
      case WarSortType.nameAsc:
        _w.sortTargets(WarSortType.nameAsc);
        break;
      case WarSortType.colorDes:
        _w.sortTargets(WarSortType.colorDes);
        break;
      case WarSortType.colorAsc:
        _w.sortTargets(WarSortType.colorAsc);
        break;
    }
  }
}

class AddFactionDialog extends StatelessWidget {
  const AddFactionDialog({
    Key key,
    @required this.themeProvider,
    @required this.addFormKey,
    @required this.addIdController,
    @required this.warController,
  }) : super(key: key);

  final ThemeProvider themeProvider;
  final GlobalKey<FormState> addFormKey;
  final TextEditingController addIdController;
  final WarController warController;

  @override
  Widget build(BuildContext context) {
    final apiKey = context.read<UserDetailsProvider>().basic.userApiKey;
    final targets = context.read<TargetsProvider>().allTargets; // To retrieve existing notes and FF/R
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0.0,
      backgroundColor: Colors.transparent,
      content: Stack(
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
                color: themeProvider.background,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: Offset(0.0, 10.0),
                  ),
                ],
              ),
              child: Form(
                key: addFormKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min, // To make the card compact
                  children: <Widget>[
                    TextFormField(
                      style: const TextStyle(fontSize: 14),
                      controller: addIdController,
                      maxLength: 10,
                      minLines: 1,
                      maxLines: 2,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        isDense: true,
                        counterText: "",
                        border: OutlineInputBorder(),
                        labelText: 'Insert faction ID',
                      ),
                      validator: (value) {
                        if (value.isEmpty) {
                          return "Cannot be empty!";
                        }
                        final n = num.tryParse(value);
                        if (n == null) {
                          return '$value is not a valid ID!';
                        }
                        addIdController.text = value.trim();
                        return null;
                      },
                    ),
                    const SizedBox(height: 16.0),
                    factionCards(),
                    const SizedBox(height: 16.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          child: const Text("Add"),
                          onPressed: () async {
                            if (addFormKey.currentState.validate()) {
                              // Copy controller's text ot local variable
                              // early and delete the global, so that text
                              // does not appear again in case of failure
                              final inputId = addIdController.text;
                              addIdController.text = '';

                              final addFactionResult = await warController.addFaction(apiKey, inputId, targets);

                              Color messageColor = Colors.green;
                              if (addFactionResult.isEmpty || addFactionResult == "error_existing") {
                                messageColor = Colors.orange[700];
                              }

                              String message = 'Added $addFactionResult [$inputId]';
                              if (addFactionResult.isEmpty) {
                                message = 'Error adding $inputId';
                              } else if (addFactionResult == "error_existing") {
                                message = 'Faction $inputId is already in the list!';
                              }

                              BotToast.showText(
                                text: message,
                                textStyle: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                                contentColor: messageColor,
                                duration: const Duration(seconds: 3),
                                contentPadding: const EdgeInsets.all(10),
                              );
                            }
                          },
                        ),
                        TextButton(
                          child: const Text("Close"),
                          onPressed: () {
                            Navigator.of(context).pop();
                            addIdController.text = '';
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            child: CircleAvatar(
              radius: 26,
              backgroundColor: themeProvider.background,
              child: CircleAvatar(
                backgroundColor: themeProvider.mainText,
                radius: 22,
                child: SizedBox(
                  height: 22,
                  width: 22,
                  child: Image.asset(
                    'images/icons/faction.png',
                    color: themeProvider.background,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget factionCards() {
    List<Widget> factionCards = <Widget>[];
    for (FactionModel faction in warController.factions) {
      factionCards.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.max,
          children: [
            GestureDetector(
              onTap: () {
                warController.filterFaction(faction.id);
              },
              child: Icon(
                Icons.remove_red_eye_outlined,
                color: faction.hidden ? Colors.red : themeProvider.mainText,
              ),
            ),
            SizedBox(width: 5),
            Flexible(
              child: Card(
                color: themeProvider.currentTheme == AppTheme.dark ? Colors.grey[700] : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    faction.name,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            SizedBox(width: 5),
            GestureDetector(
              onTap: () {
                warController.removeFaction(faction.id);
              },
              child: Icon(Icons.delete_forever_outlined),
            ),
          ],
        ),
      );
    }
    return Column(children: factionCards);
  }
}

class HiddenMembersDialog extends StatelessWidget {
  const HiddenMembersDialog({
    Key key,
    @required this.themeProvider,
    @required this.warController,
  }) : super(key: key);

  final ThemeProvider themeProvider;
  final WarController warController;

  @override
  Widget build(BuildContext context) {
    final List<Member> hiddenMembers = warController.getHiddenMembersDetails();
    List<Widget> hiddenCards = buildCards(hiddenMembers, context);
    return AlertDialog(
      backgroundColor: themeProvider.background,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      actions: [
        TextButton(
          child: const Text("Close"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
      elevation: 0.0,
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Reset hidden targets",
              style: TextStyle(fontSize: 14),
            ),
            SizedBox(height: 20),
            ListView(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              children: hiddenCards,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> buildCards(List<Member> hiddenMembers, BuildContext context) {
    List<Widget> hiddenCards = <Widget>[];
    for (Member m in hiddenMembers) {
      hiddenCards.add(
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              icon: Icon(Icons.undo),
              onPressed: () {
                warController.unhideMember(m);
                if (warController.getHiddenMembersNumber() == 0) {
                  Navigator.of(context).pop();
                }
              },
            ),
            Expanded(
              child: Card(
                color: themeProvider.currentTheme == AppTheme.dark ? Colors.grey[700] : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 3, 8, 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        mainAxisSize: MainAxisSize.max,
                        children: [
                          Text(
                            m.name,
                            style: TextStyle(fontSize: 13),
                          ),
                          Text(
                            "Level ${m.level}",
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Image.asset(
                            'images/icons/faction.png',
                            width: 11,
                            height: 11,
                            color: themeProvider.mainText,
                          ),
                          SizedBox(width: 5),
                          Text(
                            m.factionName,
                            style: TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return hiddenCards;
  }
}

class WarTargetsList extends StatelessWidget {
  WarTargetsList({@required this.warController});

  final WarController warController;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.of(context).orientation == Orientation.portrait) {
      return ListView(children: getChildrenTargets());
    } else {
      return ListView(
        children: getChildrenTargets(),
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
      );
    }
  }

  List<Widget> getChildrenTargets() {
    List<Member> members = <Member>[];
    warController.factions.forEach((faction) {
      if (!faction.hidden) {
        faction.members.forEach((key, value) {
          value.memberId = int.parse(key);
          value.factionName = faction.name;
          value.factionLeader = faction.leader;
          value.factionColeader = faction.coLeader;
          members.add(value);
        });
      }
    });

    List<WarCard> filteredCards = <WarCard>[];

    for (var thisMember in members) {
      if (!thisMember.hidden)
        filteredCards.add(
          WarCard(
            key: UniqueKey(),
            memberModel: thisMember,
          ),
        );
    }

    switch (warController.currentSort) {
      case WarSortType.levelDes:
        filteredCards.sort((a, b) => b.memberModel.level.compareTo(a.memberModel.level));
        break;
      case WarSortType.levelAsc:
        filteredCards.sort((a, b) => a.memberModel.level.compareTo(b.memberModel.level));
        break;
      case WarSortType.respectDes:
        filteredCards.sort((a, b) => b.memberModel.respectGain.compareTo(a.memberModel.respectGain));
        break;
      case WarSortType.respectAsc:
        filteredCards.sort((a, b) => a.memberModel.respectGain.compareTo(b.memberModel.respectGain));
        break;
      case WarSortType.nameDes:
        filteredCards.sort((a, b) => b.memberModel.name.toLowerCase().compareTo(a.memberModel.name.toLowerCase()));
        break;
      case WarSortType.nameAsc:
        filteredCards.sort((a, b) => a.memberModel.name.toLowerCase().compareTo(b.memberModel.name.toLowerCase()));
        break;
      case WarSortType.colorDes:
        filteredCards.sort((a, b) =>
            b.memberModel.personalNoteColor.toLowerCase().compareTo(a.memberModel.personalNoteColor.toLowerCase()));
        break;
      case WarSortType.colorAsc:
        filteredCards.sort((a, b) =>
            a.memberModel.personalNoteColor.toLowerCase().compareTo(b.memberModel.personalNoteColor.toLowerCase()));
        break;
    }

    warController.orderedCardsDetails.clear();
    for (int i = 0; i < filteredCards.length; i++) {
      WarCardDetails details = WarCardDetails()
        ..cardPosition = i + 1
        ..memberId = filteredCards[i].memberModel.memberId
        ..name = filteredCards[i].memberModel.name
        ..personalNote = filteredCards[i].memberModel.personalNote
        ..personalNoteColor = filteredCards[i].memberModel.personalNoteColor;

      warController.orderedCardsDetails.add(details);
    }

    return filteredCards;
  }
}
