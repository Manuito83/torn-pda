import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';


class StocksOptionsDialog extends StatefulWidget {
  final int capacity;
  final Function callBack;

  StocksOptionsDialog({@required this.capacity, @required this.callBack});

  @override
  _StocksOptionsDialogState createState() => _StocksOptionsDialogState();
}


class _StocksOptionsDialogState extends State<StocksOptionsDialog> {
  ThemeProvider _themeProvider;

  int _capacity;

  @override
  void initState() {
    super.initState();
    _capacity = widget.capacity;
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
                  Text(
                    'Set your item capacity (affects profit per hour calculation)',
                    style: TextStyle(fontSize: 13),
                  ),
                  SizedBox(height: 16.0),
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
                      _callBackValue();
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

  void _callBackValue() {
    widget.callBack(_capacity);
    SharedPreferencesModel().setStockCapacity(_capacity);
  }

}
