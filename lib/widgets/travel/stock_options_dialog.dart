// Flutter imports:
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

// Package imports:
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';

// Project imports:
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/utils/travel/travel_times.dart';

class StocksOptionsDialog extends StatefulWidget {
  final int capacity;
  final Function callBack;
  final bool inventoryEnabled;
  final bool showArrivalTime;
  final bool showBarsCooldownAnalysis;
  final SettingsProvider? settingsProvider;

  StocksOptionsDialog({
    required this.capacity,
    required this.callBack,
    required this.inventoryEnabled,
    required this.showArrivalTime,
    required this.showBarsCooldownAnalysis,
    required this.settingsProvider,
  });

  @override
  _StocksOptionsDialogState createState() => _StocksOptionsDialogState();
}

class _StocksOptionsDialogState extends State<StocksOptionsDialog> {
  late ThemeProvider _themeProvider;

  late int _capacity;
  late bool _inventoryEnabled;
  late bool _showArrivalTime;
  late bool _barsCooldownAnalysis;

  @override
  void initState() {
    super.initState();
    _capacity = widget.capacity;
    _inventoryEnabled = widget.inventoryEnabled;
    _showArrivalTime = widget.showArrivalTime;
    _barsCooldownAnalysis = widget.showBarsCooldownAnalysis;
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
                left: 25,
                right: 25,
              ),
              margin: EdgeInsets.only(top: 30),
              decoration: new BoxDecoration(
                color: _themeProvider.secondBackground,
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
                            fontSize: 13,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          "Show arrival time",
                          style: TextStyle(
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Switch(
                        value: _showArrivalTime,
                        onChanged: (value) {
                          setState(() {
                            _showArrivalTime = value;
                          });
                          _callBackValues();
                        },
                        activeTrackColor: Colors.lightGreenAccent,
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Flexible(
                        child: Text(
                          "Bars/cooldown analysis",
                          style: TextStyle(
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Switch(
                        value: _barsCooldownAnalysis,
                        onChanged: (value) {
                          setState(() {
                            _barsCooldownAnalysis = value;
                          });
                          _callBackValues();
                        },
                        activeTrackColor: Colors.lightGreenAccent,
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Capacity: ${_capacity.round().toString()}",
                        style: TextStyle(
                          fontSize: 13,
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              if (_capacity > 1) {
                                setState(() {
                                  _capacity--;
                                });
                                _callBackValues();
                              }
                            },
                            child: Icon(MdiIcons.minus),
                          ),
                          SizedBox(width: 10),
                          OutlinedButton(
                            onPressed: () {
                              if (_capacity < 44) {
                                setState(() {
                                  _capacity++;
                                });
                                _callBackValues();
                              }
                            },
                            child: Icon(MdiIcons.plus),
                          ),
                        ],
                      )
                    ],
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Affects profit per hour calculation',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Ticket",
                        style: TextStyle(
                          fontSize: 13,
                        ),
                      ),
                      _timeFormatDropdown(),
                    ],
                  ),
                  Text(
                    'Affects all travel time-based calculations. Does not affect '
                    'profit calculation.',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 11,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          child: Text("Close"),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
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
              backgroundColor: _themeProvider.secondBackground,
              child: CircleAvatar(
                backgroundColor: _themeProvider.mainText,
                radius: 22,
                child: SizedBox(
                  height: 28,
                  width: 28,
                  child: Icon(
                    Icons.settings,
                    color: _themeProvider.secondBackground,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DropdownButton _timeFormatDropdown() {
    return DropdownButton<TravelTicket>(
      value: widget.settingsProvider!.travelTicket,
      items: [
        DropdownMenuItem(
          value: TravelTicket.standard,
          child: SizedBox(
            width: 70,
            child: Text(
              "Standard",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: TravelTicket.private,
          child: SizedBox(
            width: 70,
            child: Text(
              "Airstrip",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: TravelTicket.wlt,
          child: SizedBox(
            width: 70,
            child: Text(
              "Private",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
        DropdownMenuItem(
          value: TravelTicket.business,
          child: SizedBox(
            width: 70,
            child: Text(
              "Business",
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ),
      ],
      onChanged: (value) {
        if (value == null) return;
        setState(() {
          widget.settingsProvider!.changeTravelTicket = value;
        });
        _callBackValues();
      },
    );
  }

  void _callBackValues() {
    widget.callBack(_capacity, _inventoryEnabled, _showArrivalTime, _barsCooldownAnalysis);
    Prefs().setStockCapacity(_capacity);
    Prefs().setShowForeignInventory(_inventoryEnabled);
    Prefs().setShowArrivalTime(_showArrivalTime);
    Prefs().setShowBarsCooldownAnalysis(_barsCooldownAnalysis);
  }
}
