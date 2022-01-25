// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/models/awards/awards_model.dart';
import 'package:torn_pda/providers/awards_provider.dart';
import 'package:torn_pda/providers/user_details_provider.dart';
import 'package:torn_pda/utils/html_parser.dart';

class AwardCardPin extends StatefulWidget {
  AwardCardPin({@required this.award, @required this.pinConditionChange});

  final Award award;
  final Function pinConditionChange;

  @override
  _AwardCardPinState createState() => _AwardCardPinState();
}

class _AwardCardPinState extends State<AwardCardPin> {
  AwardsProvider _pinProvider;
  UserDetailsProvider _userProvider;

  bool _pinActive = true;

  @override
  void initState() {
    super.initState();
    _userProvider = Provider.of<UserDetailsProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    _pinProvider = Provider.of<AwardsProvider>(context, listen: true);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(widget.award.name),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        BotToast.showText(
                          text: widget.award.description,
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
                GestureDetector(
                  onTap: _pinActive
                      ? () async {
                          setState(() {
                            _pinActive = false;
                          });

                          var result = await _pinProvider.removePinned(
                            widget.award,
                          );

                          var resultString = "";
                          Color resultColor = Colors.transparent;
                          if (result) {
                            widget.pinConditionChange();
                            resultString = "Unpinned ${widget.award.name}!";
                            resultColor = Colors.green[700];
                          } else {
                            resultString =
                                "Error unpinning ${widget.award.name}! "
                                "Please try again or do it directly in YATA";
                            resultColor = Colors.red[700];
                          }

                          if (mounted) {
                            setState(() {
                              _pinActive = true;
                            });
                          }

                          BotToast.showText(
                            text: resultString,
                            textStyle: TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            contentColor: resultColor,
                            duration: Duration(seconds: 6),
                            contentPadding: EdgeInsets.all(10),
                          );
                        }
                      : null,
                  child: _pinActive
                      ? Icon(
                          MdiIcons.pin,
                          color: Colors.green,
                          size: 20,
                        )
                      : SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(),
                        ),
                ),
              ],
            ),
            pinDetails(),
          ],
        ),
      ),
    );
  }

  Widget pinDetails() {
    var achievedPercentage = (widget.award.achieve * 100).truncate();
    final decimalFormat = new NumberFormat("#,##0", "en_US");

    Widget commentIconRow = SizedBox.shrink();
    if (widget.award.comment != null && widget.award.comment.trim() != "") {
      widget.award.comment = HtmlParser.fix(
          widget.award.comment.replaceAll("<br>", "\n").replaceAll("  ", ""));
      commentIconRow = Row(
        children: [
          SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              BotToast.showText(
                text: widget.award.comment,
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

    return Row(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "$achievedPercentage%",
              style: TextStyle(
                fontSize: 12,
              ),
            ),
            Text(
              ' - ${decimalFormat.format(widget.award.current.ceil())}'
              '/${decimalFormat.format(widget.award.goal.ceil())}',
              style: TextStyle(fontSize: 12),
            ),
            if (widget.award.daysLeft != -99)
              widget.award.daysLeft > 0 &&
                      widget.award.daysLeft < double.maxFinite
                  ? Text(
                      " - ${decimalFormat.format(widget.award.daysLeft.round())} "
                      "days",
                      style: TextStyle(fontSize: 12),
                    )
                  : widget.award.daysLeft == double.maxFinite
                      ? Row(
                          children: [
                            Text(' - '),
                            Icon(Icons.all_inclusive, size: 19),
                          ],
                        )
                      : Text(
                          " - ${(DateFormat('yyyy-MM-dd').format(
                            DateTime.fromMillisecondsSinceEpoch(
                                widget.award.dateAwarded.round() * 1000),
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
      ],
    );
  }
}
