import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/crimes_provider.dart';
import 'package:torn_pda/utils/js_snippets.dart';
import 'package:torn_pda/pages/crimes/crimes_options.dart';
import 'package:torn_pda/widgets/webviews/explanation_dialog.dart';


class CrimesWidget extends StatefulWidget {
  final InAppWebViewController controller;
  final bool appBarTop;
  final bool browserDialog;

  CrimesWidget({
    @required this.controller,
    @required this.appBarTop,
    @required this.browserDialog,
  });

  @override
  _CrimesWidgetState createState() => _CrimesWidgetState();
}

class _CrimesWidgetState extends State<CrimesWidget> {
  CrimesProvider _crimesProvider;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _crimesProvider = Provider.of<CrimesProvider>(context, listen: true);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Align(
        alignment: Alignment.center,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 5,
          runSpacing: -10,
          children: _crimeButtons(),
        ),
      ),
    );
  }

  List<Widget> _crimeButtons() {
    var myList = <Widget>[];
    for (var crime in _crimesProvider.activeCrimesList) {
      String doCrime;
      if (crime.nerve <= 3) {
        doCrime = '2';
      } else {
        doCrime = '4';
      }
      Color nerveColor;
      if (crime.nerve < 11) {
        nerveColor = Colors.green[300];
      } else if (crime.nerve < 15) {
        nerveColor = Colors.orange;
      } else {
        nerveColor = Colors.red;
      }

      myList.add(
        Tooltip(
          message: '${crimesCategories[crime.nerve]}: ${crime.fullName}',
          textStyle: TextStyle(color: Colors.white),
          padding: EdgeInsets.all(20),
          margin: EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.grey[700]),
          child: ActionChip(
            elevation: 3,
            avatar: CircleAvatar(
              child: Text(
                '${crime.nerve}',
                style: TextStyle(
                  fontSize: 12,
                  color: nerveColor,
                ),
              ),
            ),
            label: Text(
              crime.shortName,
              style: TextStyle(fontSize: 12),
            ),
            onPressed: () async {
              var myCrime = easyCrimesJS(
                nerve: crime.nerve.toString(),
                crime: crime.action,
                doCrime: doCrime,
              );
              await widget.controller.evaluateJavascript(source: myCrime);
            },
          ),
        ),
      );
    }

    if (myList.isEmpty) {
      String appBarPosition = "above";
      if (!widget.appBarTop) {
        appBarPosition = "below";
      }

      String explanation =
          "Use the fingerprint icon $appBarPosition to configure quick crimes";
      if (widget.browserDialog) {
        explanation = "Use the full browser to configure your quick crimes";
      }

      myList.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                explanation,
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 12,
                ),
              ),
              if (widget.browserDialog)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: GestureDetector(
                    onTap: () async {
                      await showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return BrowserExplanationDialog();
                        },
                      );
                    },
                    child: Icon(
                      Icons.info_outline,
                      size: 18,
                      color: Colors.orangeAccent,
                    ),
                  ),
                )
              else
                SizedBox.shrink(),
            ],
          ),
        ),
      );
    }

    return myList;
  }
}
