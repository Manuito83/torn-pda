import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:intl/intl.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:torn_pda/utils/html_parser.dart';
import 'package:torn_pda/models/awards/awards_model.dart';
import 'package:torn_pda/providers/awards_provider.dart';

class AwardCard extends StatefulWidget {
  AwardCard({@required this.award, @required this.pinConditionChange});

  final Award award;
  final Function pinConditionChange;

  @override
  _AwardCardState createState() => _AwardCardState();
}

class _AwardCardState extends State<AwardCard> {
  ThemeProvider _themeProvider;
  AwardsProvider _pinProvider;

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    _pinProvider = Provider.of<AwardsProvider>(context, listen: true);

    var award = widget.award;

    Color borderColor = Colors.transparent;
    if (award.achieve == 1) {
      borderColor = Colors.green;
    }

    Row titleRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        award.type == "Honor" ? award.image : Text(award.name.trim()),
        Row(
          children: [
            if (award.doubleMerit != null ||
                award.tripleMerit != null ||
                award.nextCrime != null)
              GestureDetector(
                onTap: () {
                  String special = "";

                  if (award.nextCrime != null) {
                    special = "Next crime to do!";
                  } else if (award.tripleMerit != null) {
                    special = "Triple merit!";
                  } else if (award.doubleMerit != null) {
                    special = "Double merit!";
                  }

                  BotToast.showText(
                    text: special,
                    textStyle: TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                    ),
                    contentColor: Colors.green[800],
                    duration: Duration(seconds: 6),
                    contentPadding: EdgeInsets.all(10),
                  );
                },
                child: Image.asset(
                  award.nextCrime != null
                      ? 'images/awards/trophy.png'
                      : award.tripleMerit != null
                          ? 'images/awards/triple_merit.png'
                          : 'images/awards/double_merit.png',
                  color: _themeProvider.mainText,
                  height: 18,
                ),
              )
            else
              SizedBox.shrink(),
            if (award.achieve < 1)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: GestureDetector(
                  onTap: () {
                    String action = '';
                    Color actionColor;

                    // TODO: replace with comment when syncing with YATA
                    action = 'Pins are not being synchronized with YATA yet, please '
                        'pin or unpin your awards in YATA\'s website and refresh '
                        'this section to see the changes.';
                    actionColor = Colors.grey[700];

                    /*
                    // TODO: add YATA post call and checks
                    if (_pinProvider.pinnedNames.contains(award.name)) {
                      setState(() {
                        award.pinned = false;
                      });
                      _pinProvider.removePinned(award);
                      widget.pinConditionChange();
                      action = 'Unpinned ${award.name}!';
                      actionColor = Colors.red;
                    } else {
                      setState(() {
                        award.pinned = true;
                      });
                      _pinProvider.addPinned(award);
                      widget.pinConditionChange();
                      action = 'Pinned ${award.name}!';
                      actionColor = Colors.green;
                    }
                    */

                    BotToast.showText(
                      text: action,
                      textStyle: TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      contentColor: actionColor,
                      duration: Duration(seconds: 6),
                      contentPadding: EdgeInsets.all(10),
                    );
                  },
                  child: _pinProvider.pinnedNames.contains(award.name)
                      ? Icon(
                          MdiIcons.pin,
                          color: Colors.green,
                          size: 20,
                        )
                      : Icon(
                          MdiIcons.pinOutline,
                          size: 20,
                        ),
                ),
              )
            else
              SizedBox.shrink()
          ],
        )
      ],
    );

    Row descriptionRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            '${award.description}',
            style: TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );

    Widget commentIconRow = SizedBox.shrink();
    if (award.comment != null && award.comment.trim() != "") {
      award.comment = HtmlParser.fix(
          award.comment.replaceAll("<br>", "\n").replaceAll("  ", ""));
      commentIconRow = Row(
        children: [
          SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              BotToast.showText(
                text: award.comment,
                textStyle: TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                ),
                contentColor: Colors.grey[700],
                duration: Duration(seconds: 6),
                contentPadding: EdgeInsets.all(10),
              );
            },
            child: Icon(
              Icons.info_outline,
              size: 19,
            ),
          ),
        ],
      );
    }

    var achievedPercentage = (award.achieve * 100).truncate();
    final decimalFormat = new NumberFormat("#,##0", "en_US");
    final rarityFormat = new NumberFormat("##0.0000", "en_US");
    Widget detailsRow = Row(
      children: [
        Expanded(
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "$achievedPercentage%",
                    style: TextStyle(
                      fontSize: 12,
                      color: achievedPercentage == 100
                          ? Colors.green
                          : _themeProvider.mainText,
                    ),
                  ),
                  Text(
                    ' - ${decimalFormat.format(award.current.ceil())}'
                    '/${decimalFormat.format(award.goal.ceil())}',
                    style: TextStyle(fontSize: 12),
                  ),
                  if (award.daysLeft != -99)
                    award.daysLeft > 0 && award.daysLeft < double.maxFinite
                        ? Text(
                            " - ${decimalFormat.format(award.daysLeft.round())} "
                            "days",
                            style: TextStyle(fontSize: 12),
                          )
                        : award.daysLeft == double.maxFinite
                            ? Row(
                                children: [
                                  Text(' - '),
                                  Icon(Icons.all_inclusive, size: 19),
                                ],
                              )
                            : Text(
                                " - ${(DateFormat('yyyy-MM-dd').format(
                                  DateTime.fromMillisecondsSinceEpoch(
                                      award.dateAwarded.round() * 1000),
                                ))}",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              )
                  else
                    SizedBox.shrink(),
                  commentIconRow,
                ],
              ),
              Container(width: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "${decimalFormat.format(award.circulation)}",
                    style: TextStyle(fontSize: 12),
                  ),
                  SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      BotToast.showText(
                        text:
                            "Circulation: ${decimalFormat.format(award.circulation)}\n\n "
                            "Rarity: ${award.rarity}\n\n"
                            "Score: ${rarityFormat.format(award.rScore)}%",
                        textStyle: TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                        contentColor: Colors.grey[700],
                        duration: Duration(seconds: 6),
                        contentPadding: EdgeInsets.all(10),
                      );
                    },
                    child: Icon(
                      Icons.info_outline,
                      size: 19,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    ConstrainedBox category = ConstrainedBox(
      constraints: BoxConstraints(maxHeight: 50),
      child: RotatedBox(
        quarterTurns: 3,
        child: Text(
          award.subCategory.toUpperCase(),
          softWrap: true,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: TextStyle(
            fontSize: 7,
          ),
        ),
      ),
    );

    // MAIN CARD
    if (award.type == "Honor") {
      return Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: Row(
            children: [
              category,
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleRow,
                    SizedBox(height: 5),
                    descriptionRow,
                    SizedBox(height: 5),
                    detailsRow,
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else if (award.type == "Medal") {
      return Card(
        shape: RoundedRectangleBorder(
          side: BorderSide(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(4.0),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: Row(
            children: [
              category,
              SizedBox(width: 5),
              award.image,
              SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleRow,
                    SizedBox(height: 5),
                    descriptionRow,
                    SizedBox(height: 5),
                    detailsRow,
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }
}
