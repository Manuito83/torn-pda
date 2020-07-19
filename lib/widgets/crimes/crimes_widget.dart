import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/crimes_provider.dart';
import 'package:torn_pda/utils/js_snippets.dart';

class CrimesWidget extends StatefulWidget {
  final InAppWebViewController controller;

  CrimesWidget({
    @required this.controller,
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
    return Wrap(
      spacing: 8,
      runSpacing: -10,
      children: _crimeButtons(),
    );
  }

  List<Widget> _crimeButtons() {
    var myList = List<Widget>();
    for (var crime in _crimesProvider.activeCrimesList) {
      myList.add(
        ActionChip(
          avatar: CircleAvatar(
            child: Text(
              '-${crime.nerve}',
              style: TextStyle(fontSize: 12),
            ),
          ),
          label: Text(
            crime.shortName,
            style: TextStyle(fontSize: 12),
          ),
          onPressed: () async {
            var myCrime = easyCrimesJS(
              crime.nerve.toString(),
              crime.action,
            );
            await widget.controller.evaluateJavascript(source: myCrime);
          },
        ),
      );
    }

    if (myList.isEmpty) {
      myList.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
          child: Text('You can configure easy crimes in the top menu',
            style: TextStyle(color: Colors.orangeAccent),
          ),
        ),
      );
    }

    return myList;
  }
}
