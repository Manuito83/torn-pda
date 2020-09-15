import 'package:flutter/material.dart';

class YataTargetsDistribution extends StatefulWidget {
  final Map<String, String> onlyYata;
  final Map<String, Map<String, String>> onlyLocal;
  final Map<String, Map<String, String>> bothSides;

  YataTargetsDistribution({
    @required this.bothSides,
    @required this.onlyYata,
    @required this.onlyLocal,
  });

  @override
  _YataTargetsDistributionState createState() => _YataTargetsDistributionState();
}

class _YataTargetsDistributionState extends State<YataTargetsDistribution> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(),
      appBar: AppBar(
        title: Text('YATA targets'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: <Widget>[
                Text(
                  'TARGETS ONLY IN YATA',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '(CAN BE IMPORTED)',
                  style: TextStyle(
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: 10),
                Column(
                  children: _returnTargetsOnlyInYata(),
                ),
                SizedBox(height: 10),
                Divider(),
                SizedBox(height: 10),
                Text(
                  'COMMON TARGETS',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '(ONLY NOTES UPDATED)',
                  style: TextStyle(
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: 10),
                Column(
                  children: _returnTargetsBothSides(),
                ),
                SizedBox(height: 10),
                Divider(),
                SizedBox(height: 10),
                Text(
                  'TARGETS ONLY IN TORN PDA',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '(CAN BE EXPORTED)',
                  style: TextStyle(
                    fontSize: 11,
                  ),
                ),
                SizedBox(height: 10),
                Column(
                  children: _returnTargetsOnlyInTornPDA(),
                ),
                SizedBox(height: 10),
                SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _returnTargetsOnlyInYata() {
    var itemList = List<Widget>();

    widget.onlyYata.forEach((key, value) {
      itemList.add(
        Text(
          "$value [$key]",
          style: TextStyle(fontSize: 12),
        ),
      );
    });

    return itemList;
  }

  List<Widget> _returnTargetsBothSides() {
    var itemList = List<Widget>();

    widget.bothSides.forEach((key, value) {
      itemList.add(
        Text(
          "${value.keys.first} [$key]",
          style: TextStyle(fontSize: 12),
        ),
      );
    });

    return itemList;
  }

  List<Widget> _returnTargetsOnlyInTornPDA() {
    var itemList = List<Widget>();

    widget.onlyLocal.forEach((key, value) {
      itemList.add(
        Text(
          "${value.keys.first} [$key]",
          style: TextStyle(fontSize: 12),
        ),
      );
    });

    return itemList;
  }
}
