import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/crimes/crime_model.dart';
import 'package:torn_pda/providers/crimes_provider.dart';

class CrimesOptions extends StatefulWidget {
  @override
  _CrimesOptionsState createState() => _CrimesOptionsState();
}

class _CrimesOptionsState extends State<CrimesOptions> {
  var _mainCrimeList = List<Crime>();
  var _titleCrimeString = List<String>();

  var _categoriesMap = Map<int, String>();

  CrimesProvider _crimesProvider;
  Future _preferencesLoaded;

  @override
  void initState() {
    super.initState();
    _initCrimes();
    _crimesProvider = Provider.of<CrimesProvider>(context, listen: false);
    _preferencesLoaded = _restorePreferences();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Crimes Menu"),
        leading: new IconButton(
          icon: new Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.delete_outline),
            onPressed: () {
              _crimesProvider.deactivateAllCrimes();
              setState(() {
                _titleCrimeString.clear();
                for (var crime in _mainCrimeList) {
                  if (crime.active) {
                    crime.active = false;
                  }
                }
              });
            },
          ),
        ],
      ),
      body: Builder(
        builder: (BuildContext context) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => FocusScope.of(context).requestFocus(new FocusNode()),
            child: FutureBuilder(
              future: _preferencesLoaded,
              builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: _titleCrimeString.length > 0
                              ? Text('Active crimes: '
                                  '${_titleCrimeString.join(', ')}')
                              : Text('No active crimes'),
                        ),
                        _crimesCards(),
                        SizedBox(height: 50),
                      ],
                    ),
                  );
                } else {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                }
              },
            ),
          );
        },
      ),
    );
  }

  Widget _crimesCards() {
    var cardList = List<Card>();
    // Loop all categories and fill in cards
    _categoriesMap.forEach((catNerve, catName) {
      // If nerve are equal, add children crimes
      var thisCrimesList = List<Crime>();
      _mainCrimeList.forEach((crime) {
        if (crime.nerve == catNerve) {
          thisCrimesList.add(crime);
        }
      });

      var crimesRows = List<Widget>();
      for (var i = 0; i < thisCrimesList.length; i++) {
        crimesRows.add(
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${thisCrimesList[i].fullName}',
                      style: TextStyle(
                        fontSize: 13,
                        color: thisCrimesList[i].active ? Colors.green : null,
                        fontWeight: thisCrimesList[i].active
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: thisCrimesList[i].active,
                onChanged: (bool value) {
                  setState(() {
                    if (thisCrimesList[i].active) {
                      _deactivateCrime(thisCrimesList, i);
                    } else {
                      _activateCrime(thisCrimesList, i);
                    }
                  });
                },
              ),
            ],
          ),
        );
      }

      // Add one card per category
      cardList.add(
        Card(
          child: ExpandablePanel(
            header: Padding(
              padding: const EdgeInsets.fromLTRB(20, 15, 20, 20),
              child: Row(
                children: <Widget>[
                  Icon(MdiIcons.fingerprint),
                  SizedBox(width: 10),
                  Text('$catName'),
                  SizedBox(width: 10),
                  Text('(-$catNerve nerve)'),
                ],
              ),
            ),
            expanded: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: crimesRows,
              ),
            ),
          ),
        ),
      );
    });

    return Column(
      children: cardList,
    );
  }

  void _activateCrime(List<Crime> thisCrimesList, int i) {
    thisCrimesList[i].active = true;
    _crimesProvider.activateCrime(thisCrimesList[i]);
    _updateTitleString();
  }

  void _deactivateCrime(List<Crime> thisCrimesList, int i) {
    thisCrimesList[i].active = false;
    _crimesProvider.deactivateCrime(thisCrimesList[i]);
    _updateTitleString();
  }

  void _updateTitleString() {
    // We clear the list and create again, so that crimes come sorted from origin
    _titleCrimeString.clear();
    for (var crime in _crimesProvider.activeCrimesList) {
      _titleCrimeString.add('${crime.shortName} (-${crime.nerve})');
    }
  }

  Future _restorePreferences() async {
    // Load crimes from shared preferences
    var activeCrimeList = _crimesProvider.activeCrimesList;
    for (var activeCrime in activeCrimeList) {
      // For every existing crime, if we can find a match with out loaded
      // crimes, we activate that crime
      for (var mainCrime in _mainCrimeList) {
        if (activeCrime.fullName == mainCrime.fullName) {
          mainCrime.active = true;
          _titleCrimeString.add('${activeCrime.shortName} '
              '(-${activeCrime.nerve})');
        }
      }
    }

    setState(() {});
  }

  _initCrimes() {
    _categoriesMap = {
      2: 'Search for cash',
      3: 'Sell copied media',
    };

    _mainCrimeList.addAll([
      Crime(
        nerve: 2,
        fullName: 'Search the train station',
        shortName: 'Search Station',
        action: 'searchtrainstation',
        active: false,
      ),
      Crime(
        nerve: 2,
        fullName: 'Search under the old bridge',
        shortName: 'Search Bridge',
        action: 'searchbridge',
        active: false,
      ),
      Crime(
        nerve: 3,
        fullName: 'Rock CDs',
        shortName: 'Rock CD',
        action: 'cdrock',
        active: false,
      ),
      Crime(
        nerve: 3,
        fullName: 'Heavy Metal CDs',
        shortName: 'Heavy CD',
        action: 'cdheavymetal',
        active: false,
      ),
    ]);
  }
}
