import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class StocksOptionsDialog extends StatefulWidget {
  final int capacity;
  final Function callBack;
  final bool inventoryEnabled;

  StocksOptionsDialog({
    @required this.capacity,
    @required this.callBack,
    @required this.inventoryEnabled,
  });

  @override
  _StocksOptionsDialogState createState() => _StocksOptionsDialogState();
}

class _StocksOptionsDialogState extends State<StocksOptionsDialog> {
  ThemeProvider _themeProvider;

  int _capacity;
  bool _inventoryEnabled;

  @override
  void initState() {
    super.initState();
    _capacity = widget.capacity;
    _inventoryEnabled = widget.inventoryEnabled;
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return SingleChildScrollView(
      child: Stack(
        children: <Widget>[
          SingleChildScrollView(
            child: Container(
              padding: EdgeInsets.only(
                top: 45,
                bottom: 16,
                left: 16,
                right: 16,
              ),
              margin: EdgeInsets.only(top: 30),
              decoration: new BoxDecoration(
                color: _themeProvider.background,
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10.0,
                    offset: const Offset(0.0, 10.0),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min, // To make the card compact
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          "Show inventory quantities",
                          style: TextStyle(
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Switch(
                        value: _inventoryEnabled,
                        onChanged: (value) {
                          setState(() {
                            _inventoryEnabled = value;
                          });
                          _callBackValues();
                        },
                        activeTrackColor: Colors.lightGreenAccent,
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                  Text(
                    'If active, you\'ll be shown the quantity of each item you '
                    'already possess in your inventory',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 10),
                  Divider(),
                  SizedBox(height: 10),
                  Text(
                    'Set your item capacity (affects profit per hour calculation)',
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(height: 16.0),
                  Text(
                    "Capacity: ${_capacity.round().toString()}",
                    style: TextStyle(
                      fontSize: 14,
                    ),
                  ),
                  Slider(
                    value: _capacity.toDouble(),
                    min: 1,
                    max: 44,
                    label: _capacity.round().toString(),
                    divisions: 44,
                    onChanged: (double newCapacity) {
                      setState(() {
                        _capacity = newCapacity.round();
                      });
                      _callBackValues();
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      FlatButton(
                        child: Text("Close"),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            child: CircleAvatar(
              radius: 26,
              backgroundColor: _themeProvider.background,
              child: CircleAvatar(
                backgroundColor: _themeProvider.mainText,
                radius: 22,
                child: SizedBox(
                  height: 28,
                  width: 28,
                  child: Icon(
                    Icons.settings,
                    color: _themeProvider.background,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _callBackValues() {
    widget.callBack(_capacity, _inventoryEnabled);
    SharedPreferencesModel().setStockCapacity(_capacity);
    SharedPreferencesModel().setShowForeignInventory(_inventoryEnabled);
  }
}
