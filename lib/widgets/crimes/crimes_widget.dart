// Flutter imports:
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';

// Package imports:
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';

// Project imports:
import 'package:torn_pda/pages/crimes/crimes_options.dart';
import 'package:torn_pda/providers/crimes_provider.dart';
import 'package:torn_pda/utils/js_snippets.dart';

class CrimesWidget extends StatefulWidget {
  final InAppWebViewController? controller;

  const CrimesWidget({
    super.key,
    required this.controller,
  });

  @override
  CrimesWidgetState createState() => CrimesWidgetState();
}

class CrimesWidgetState extends State<CrimesWidget> {
  late CrimesProvider _crimesProvider;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    _crimesProvider = Provider.of<CrimesProvider>(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: ConstrainedBox(
              constraints: BoxConstraints.loose(
                Size.fromHeight(
                      MediaQuery.sizeOf(context).height - kToolbarHeight - AppBar().preferredSize.height,
                    ) /
                    3,
              ),
              child: Scrollbar(
                child: SingleChildScrollView(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 5,
                    runSpacing: -10,
                    children: _crimeButtons(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _crimeButtons() {
    final myList = <Widget>[];
    for (final crime in _crimesProvider.activeCrimesList) {
      String doCrime;
      if (crime.nerve! <= 3) {
        doCrime = '2';
      } else {
        doCrime = '4';
      }
      Color? nerveColor;
      if (crime.nerve! < 11) {
        nerveColor = Colors.green[300];
      } else if (crime.nerve! < 15) {
        nerveColor = Colors.orange;
      } else {
        nerveColor = Colors.red;
      }

      myList.add(
        Tooltip(
          message: '${crimesCategories[crime.nerve]}: ${crime.fullName}',
          textStyle: const TextStyle(color: Colors.white),
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.all(20),
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
              crime.shortName!,
              style: const TextStyle(fontSize: 12),
            ),
            onPressed: () async {
              final myCrime = easyCrimesJS(
                nerve: crime.nerve.toString(),
                crime: crime.action,
                doCrime: doCrime,
              );
              await widget.controller!.evaluateJavascript(source: myCrime);
            },
          ),
        ),
      );
    }

    if (myList.isEmpty) {
      myList.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Configure your preferred quick crimes",
                style: TextStyle(
                  color: Colors.orangeAccent,
                  fontSize: 12,
                ),
              ),
              _settingsIcon(),
            ],
          ),
        ),
      );
    }

    return myList;
  }

  Widget _settingsIcon() {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: OpenContainer(
        transitionDuration: const Duration(milliseconds: 500),
        transitionType: ContainerTransitionType.fadeThrough,
        openBuilder: (BuildContext context, VoidCallback _) {
          return CrimesOptions();
        },
        closedElevation: 0,
        closedShape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(
            Radius.circular(56 / 2),
          ),
        ),
        closedColor: Colors.transparent,
        closedBuilder: (BuildContext context, VoidCallback openContainer) {
          return const Padding(
            padding: EdgeInsets.only(right: 5),
            child: SizedBox(
              height: 20,
              width: 20,
              child: Icon(Icons.settings, size: 16, color: Colors.orange),
            ),
          );
        },
      ),
    );
  }
}
