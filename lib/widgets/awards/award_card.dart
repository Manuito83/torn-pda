// Flutter imports:
// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
// Project imports:
import 'package:torn_pda/models/awards/awards_model.dart';
import 'package:torn_pda/providers/awards_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/html_parser.dart';

class AwardCard extends StatefulWidget {
  const AwardCard({required this.award, required this.pinConditionChange});

  final Award award;
  final Function pinConditionChange;

  @override
  AwardCardState createState() => AwardCardState();
}

class AwardCardState extends State<AwardCard> {
  late ThemeProvider _themeProvider;
  late AwardsProvider _pinProvider;

  bool _pinActive = true;

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    _pinProvider = Provider.of<AwardsProvider>(context);

    final award = widget.award;

    Color borderColor = Colors.transparent;
    if (award.achieve == 1) {
      borderColor = Colors.green;
    }

    final Row titleRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (award.type == "Honor") award.image! else Text(award.name!.trim()),
        Row(
          children: [
            if (award.doubleMerit != null || award.tripleMerit != null || award.nextCrime != null)
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
                    textStyle: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                    ),
                    contentColor: Colors.green[800]!,
                    duration: const Duration(seconds: 6),
                    contentPadding: const EdgeInsets.all(10),
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
              const SizedBox.shrink(),
            if (award.achieve! < 1)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: GestureDetector(
                  onTap: _pinActive
                      ? () async {
                          var resultString = "";
                          Color? resultColor = Colors.transparent;

                          setState(() {
                            _pinActive = false;
                          });

                          // If the award is pinned, try to unpin
                          if (_pinProvider.pinnedNames.contains(award.name)) {
                            final result = await _pinProvider.removePinned(award);

                            if (result) {
                              // Callback to rebuild widget list
                              widget.pinConditionChange();
                              resultString = "Unpinned ${award.name}!";
                              resultColor = Colors.green[700];
                            } else {
                              resultString = "Error unpinning ${award.name}! "
                                  "Please try again or do it directly in YATA";
                              resultColor = Colors.red[700];
                            }
                            // If the award is not pinned, pin it
                          } else {
                            if (_pinProvider.pinnedAwards.length >= 3) {
                              resultString = "Could not pin ${award.name}! Only 3 "
                                  "pinned awards are allowed!";
                              resultColor = Colors.red[700];
                            } else {
                              final result = await _pinProvider.addPinned(
                                award,
                              );

                              if (result) {
                                resultString = "Pinned ${award.name}!";
                                resultColor = Colors.green[700];
                              } else {
                                resultString = "Error pinning ${award.name}! "
                                    "Please try again or do it directly in YATA";
                                resultColor = Colors.red[700];
                              }

                              // Callback to rebuild widget list
                              widget.pinConditionChange();
                            }
                          }

                          if (mounted) {
                            setState(() {
                              _pinActive = true;
                            });
                          }

                          BotToast.showText(
                            text: resultString,
                            textStyle: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                            contentColor: resultColor!,
                            duration: const Duration(seconds: 6),
                            contentPadding: const EdgeInsets.all(10),
                          );
                        }
                      : null,
                  child: _pinActive
                      ? _pinProvider.pinnedNames.contains(award.name)
                          ? const Icon(
                              MdiIcons.pin,
                              color: Colors.green,
                              size: 20,
                            )
                          : const Icon(
                              MdiIcons.pinOutline,
                              size: 20,
                            )
                      : const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(),
                        ),
                ),
              )
            else
              const SizedBox.shrink()
          ],
        )
      ],
    );

    final Row descriptionRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            '${award.description}',
            style: const TextStyle(
              fontSize: 12,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );

    Widget commentIconRow = const SizedBox.shrink();
    if (award.comment != null && award.comment!.trim() != "") {
      award.comment = HtmlParser.fix(award.comment!.replaceAll("<br>", "\n").replaceAll("  ", ""));
      commentIconRow = Row(
        children: [
          const SizedBox(width: 4),
          GestureDetector(
            onTap: () {
              BotToast.showText(
                text: award.comment!,
                textStyle: const TextStyle(
                  fontSize: 13,
                  color: Colors.white,
                ),
                contentColor: Colors.grey[700]!,
                duration: const Duration(seconds: 6),
                contentPadding: const EdgeInsets.all(10),
              );
            },
            child: const Icon(
              Icons.info_outline,
              size: 19,
            ),
          ),
        ],
      );
    }

    final achievedPercentage = (award.achieve! * 100).truncate();
    final decimalFormat = NumberFormat("#,##0", "en_US");
    final rarityFormat = NumberFormat("##0.0000", "en_US");
    final Widget detailsRow = Row(
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
                      color: achievedPercentage == 100 ? Colors.green : _themeProvider.mainText,
                    ),
                  ),
                  Text(
                    ' - ${decimalFormat.format(award.current!.ceil())}'
                    '/${decimalFormat.format(award.goal!.ceil())}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  if (award.daysLeft != -99)
                    award.daysLeft! > 0 && award.daysLeft! < double.maxFinite
                        ? Text(
                            " - ${decimalFormat.format(award.daysLeft!.round())} "
                            "days",
                            style: const TextStyle(fontSize: 12),
                          )
                        : award.daysLeft == double.maxFinite
                            ? const Row(
                                children: [
                                  Text(' - '),
                                  Icon(Icons.all_inclusive, size: 19),
                                ],
                              )
                            : Text(
                                " - ${DateFormat('yyyy-MM-dd').format(
                                  DateTime.fromMillisecondsSinceEpoch(award.dateAwarded!.round() * 1000),
                                )}",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              )
                  else
                    const SizedBox.shrink(),
                  commentIconRow,
                ],
              ),
              Container(width: 10),
              Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    decimalFormat.format(award.circulation),
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 5),
                  GestureDetector(
                    onTap: () {
                      BotToast.showText(
                        text: "Circulation: ${decimalFormat.format(award.circulation)}\n\n "
                            "Rarity: ${award.rarity}\n\n"
                            "Score: ${rarityFormat.format(award.rScore)}%",
                        textStyle: const TextStyle(
                          fontSize: 13,
                          color: Colors.white,
                        ),
                        contentColor: Colors.grey[700]!,
                        duration: const Duration(seconds: 6),
                        contentPadding: const EdgeInsets.all(10),
                      );
                    },
                    child: const Icon(
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

    final ConstrainedBox category = ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 50),
      child: RotatedBox(
        quarterTurns: 3,
        child: Text(
          award.subCategory.toUpperCase(),
          softWrap: true,
          textAlign: TextAlign.center,
          maxLines: 2,
          style: const TextStyle(
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
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: Row(
            children: [
              category,
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleRow,
                    const SizedBox(height: 5),
                    descriptionRow,
                    const SizedBox(height: 5),
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
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: Row(
            children: [
              category,
              const SizedBox(width: 5),
              award.image!,
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleRow,
                    const SizedBox(height: 5),
                    descriptionRow,
                    const SizedBox(height: 5),
                    detailsRow,
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}
