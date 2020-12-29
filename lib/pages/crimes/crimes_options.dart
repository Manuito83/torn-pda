import 'package:bot_toast/bot_toast.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/crimes/crime_model.dart';
import 'package:torn_pda/providers/crimes_provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

Map crimesCategories = {
  2: 'Search for cash',
  3: 'Sell copied media',
  4: 'Shoplift',
  5: 'Pickpocket someone',
  6: 'Larceny',
  7: 'Armed Robberies',
  8: 'Transport drugs',
  9: 'Plant a computer virus',
  10: 'Assassination',
  11: 'Arson',
  12: 'Grand Theft Auto',
  13: 'Pawn Shop',
  14: 'Counterfeiting',
  15: 'Kidnapping',
  16: 'Arms Trafficking',
  17: 'Bombings',
  18: 'Hacking',
};

class CrimesOptions extends StatefulWidget {
  @override
  _CrimesOptionsState createState() => _CrimesOptionsState();
}

class _CrimesOptionsState extends State<CrimesOptions> {
  var _mainCrimeList = List<Crime>();
  var _titleCrimeString = List<String>();

  CrimesProvider _crimesProvider;
  ThemeProvider _themeProvider;
  SettingsProvider _settingsProvider;
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
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: true);
    return Container(
      color: _themeProvider.currentTheme == AppTheme.light
          ? Colors.blueGrey
          : Colors.grey[900],
      child: SafeArea(
        top: _settingsProvider.appBarTop ? false : true,
        bottom: true,
        child: Scaffold(
          appBar: _settingsProvider.appBarTop ? buildAppBar() : null,
          bottomNavigationBar: !_settingsProvider.appBarTop
              ? SizedBox(
                  height: AppBar().preferredSize.height,
                  child: buildAppBar(),
                )
              : null,
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
        ),
      ),
    );
  }

  AppBar buildAppBar() {
    return AppBar(
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      brightness: Brightness.dark,
      title: Text("Quick Crimes"),
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
            BotToast.showText(
              text: 'All crimes deactivated!',
              textStyle: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
              duration: Duration(seconds: 3),
              contentColor: Colors.grey[700],
              contentPadding: EdgeInsets.all(10),
            );
          },
        ),
      ],
    );
  }

  Widget _crimesCards() {
    var cardList = List<Card>();
    // Loop all categories and fill in cards
    crimesCategories.forEach((catNerve, catName) {
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
    _mainCrimeList.addAll([
      // NERVE 2
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
        nerve: 2,
        fullName: 'Search the bins',
        shortName: 'Search Bins',
        action: 'searchbins',
        active: false,
      ),
      Crime(
        nerve: 2,
        fullName: 'Search the water fountain',
        shortName: 'Search Fountain',
        action: 'searchfountain',
        active: false,
      ),
      Crime(
        nerve: 2,
        fullName: 'Search the dumpsters',
        shortName: 'Search Dumpsters',
        action: 'searchdumpster',
        active: false,
      ),
      Crime(
        nerve: 2,
        fullName: 'Search the movie theater',
        shortName: 'Search Theater',
        action: 'searchmovie',
        active: false,
      ),

      // NERVE 3
      Crime(
        nerve: 3,
        fullName: 'Rock CDs',
        shortName: 'Rock CD',
        action: 'cdrock',
        active: false,
      ),
      Crime(
        nerve: 3,
        fullName: 'Heavy metal CDs',
        shortName: 'Heavy CD',
        action: 'cdheavymetal',
        active: false,
      ),
      Crime(
        nerve: 3,
        fullName: 'Pop CDs',
        shortName: 'Pop CD',
        action: 'cdpop',
        active: false,
      ),
      Crime(
        nerve: 3,
        fullName: 'Rap CDs',
        shortName: 'Rap CD',
        action: 'cdrap',
        active: false,
      ),
      Crime(
        nerve: 3,
        fullName: 'Reggae CDs',
        shortName: 'Reggae CD',
        action: 'cdreggae',
        active: false,
      ),
      Crime(
        nerve: 3,
        fullName: 'Horror DVDs',
        shortName: 'Horror DVD',
        action: 'dvdhorror',
        active: false,
      ),
      Crime(
        nerve: 3,
        fullName: 'Action DVDs',
        shortName: 'Action DVD',
        action: 'dvdaction',
        active: false,
      ),
      Crime(
        nerve: 3,
        fullName: 'Romance DVDs',
        shortName: 'Romance DVD',
        action: 'dvdromance',
        active: false,
      ),
      Crime(
        nerve: 3,
        fullName: 'SciFi DVDs',
        shortName: 'SciFi DVD',
        action: 'dvdsci',
        active: false,
      ),
      Crime(
        nerve: 3,
        fullName: 'Thriller DVDs',
        shortName: 'Thriller DVD',
        action: 'dvdthriller',
        active: false,
      ),

      // NERVE 4.1
      Crime(
        nerve: 4,
        fullName: 'Sweet shop: chocolate bars',
        shortName: 'Chocolate',
        action: 'chocolatebars',
        active: false,
      ),
      Crime(
        nerve: 4,
        fullName: 'Sweet shop: bonbons',
        shortName: 'Bonbons',
        action: 'bonbons',
        active: false,
      ),
      Crime(
        nerve: 4,
        fullName: 'Sweet shop: mints',
        shortName: 'Mints',
        action: 'extrastrongmints',
        active: false,
      ),

      // NERVE 4.2
      Crime(
        nerve: 4,
        fullName: 'Market stall: music',
        shortName: 'Music',
        action: 'musicstall',
        active: false,
      ),
      Crime(
        nerve: 4,
        fullName: 'Market stall: electronics',
        shortName: 'Electronics',
        action: 'electronicsstall',
        active: false,
      ),
      Crime(
        nerve: 4,
        fullName: 'Market stall: computer',
        shortName: 'Computer',
        action: 'computerstall',
        active: false,
      ),

      // NERVE 4.3
      Crime(
        nerve: 4,
        fullName: 'Clothes shop: tank top',
        shortName: 'Tank Top',
        action: 'tanktop',
        active: false,
      ),
      Crime(
        nerve: 4,
        fullName: 'Clothes shop: trainers',
        shortName: 'Trainers',
        action: 'trainers',
        active: false,
      ),
      Crime(
        nerve: 4,
        fullName: 'Clothes shop: jackets',
        shortName: 'Jacket',
        action: 'jacket',
        active: false,
      ),

      // NERVE 4.4
      Crime(
        nerve: 4,
        fullName: 'Jewelry shop: watch',
        shortName: 'Watch',
        action: 'watch',
        active: false,
      ),
      Crime(
        nerve: 4,
        fullName: 'Jewelry shop: necklace',
        shortName: 'Necklace',
        action: 'necklace',
        active: false,
      ),
      Crime(
        nerve: 4,
        fullName: 'Jewelry shop: ring',
        shortName: 'Ring',
        action: 'ring',
        active: false,
      ),

      // NERVE 5
      Crime(
        nerve: 5,
        fullName: 'Hobo',
        shortName: 'Hobo',
        action: 'hobo',
        active: false,
      ),
      Crime(
        nerve: 5,
        fullName: 'Kid',
        shortName: 'Kid',
        action: 'kid',
        active: false,
      ),
      Crime(
        nerve: 5,
        fullName: 'Old woman',
        shortName: 'Woman',
        action: 'oldwoman',
        active: false,
      ),
      Crime(
        nerve: 5,
        fullName: 'Businessman',
        shortName: 'Businessman',
        action: 'businessman',
        active: false,
      ),
      Crime(
        nerve: 5,
        fullName: 'Lawyer',
        shortName: 'Lawyer',
        action: 'lawyer',
        active: false,
      ),

      // NERVE 6
      Crime(
        nerve: 6,
        fullName: 'Apartment',
        shortName: 'Apartment',
        action: 'apartment',
        active: false,
      ),
      Crime(
        nerve: 6,
        fullName: 'Detached house',
        shortName: 'House',
        action: 'house',
        active: false,
      ),
      Crime(
        nerve: 6,
        fullName: 'Mansion',
        shortName: 'Mansion',
        action: 'mansion',
        active: false,
      ),
      Crime(
        nerve: 6,
        fullName: 'Cars',
        shortName: 'Cars',
        action: 'cartheft',
        active: false,
      ),
      Crime(
        nerve: 6,
        fullName: 'Office',
        shortName: 'Office',
        action: 'office',
        active: false,
      ),

      // NERVE 7
      Crime(
        nerve: 7,
        fullName: 'Swift robbery',
        shortName: 'Swt Robbery',
        action: 'swiftrobbery',
        active: false,
      ),
      Crime(
        nerve: 7,
        fullName: 'Thorough robbery',
        shortName: 'Tgh Robbery',
        action: 'thoroughrobbery',
        active: false,
      ),
      Crime(
        nerve: 7,
        fullName: 'Swift convenience',
        shortName: 'Swt Convenience',
        action: 'swiftconvenient',
        active: false,
      ),
      Crime(
        nerve: 7,
        fullName: 'Thorough convenience',
        shortName: 'Tgh Convenience',
        action: 'thoroughconvenient',
        active: false,
      ),
      Crime(
        nerve: 7,
        fullName: 'Swift bank',
        shortName: 'Swt Bank',
        action: 'swiftbank',
        active: false,
      ),
      Crime(
        nerve: 7,
        fullName: 'Thorough bank',
        shortName: 'Tgh Bank',
        action: 'thoroughbank',
        active: false,
      ),
      Crime(
        nerve: 7,
        fullName: 'Swift armored car',
        shortName: 'Swt Car',
        action: 'swiftcar',
        active: false,
      ),
      Crime(
        nerve: 7,
        fullName: 'Thorough armored car',
        shortName: 'Tgh Car',
        action: 'thoroughcar',
        active: false,
      ),

      // NERVE 8
      Crime(
        nerve: 8,
        fullName: 'Transport cannabis',
        shortName: 'Cannabis',
        action: 'cannabis',
        active: false,
      ),
      Crime(
        nerve: 8,
        fullName: 'Transport amphetamines',
        shortName: 'Amphetamines',
        action: 'amphetamines',
        active: false,
      ),
      Crime(
        nerve: 8,
        fullName: 'Transport cocaine',
        shortName: 'Cocaine',
        action: 'cocaine',
        active: false,
      ),
      Crime(
        nerve: 8,
        fullName: 'Sell cannabis',
        shortName: 'Cannabis',
        action: 'drugscanabis',
        active: false,
      ),
      Crime(
        nerve: 8,
        fullName: 'Sell pills',
        shortName: 'Pills',
        action: 'drugspills',
        active: false,
      ),
      Crime(
        nerve: 8,
        fullName: 'Sell cocaine',
        shortName: 'Cocaine',
        action: 'drugscocaine',
        active: false,
      ),

      // NERVE 9
      Crime(
        nerve: 9,
        fullName: 'Simple virus',
        shortName: 'Spl. Virus',
        action: 'simplevirus',
        active: false,
      ),
      Crime(
        nerve: 9,
        fullName: 'Polymorphic virus',
        shortName: 'Pol. Virus',
        action: 'polymorphicvirus',
        active: false,
      ),
      Crime(
        nerve: 9,
        fullName: 'Tunneling virus',
        shortName: 'Tun. Virus',
        action: 'tunnelingvirus',
        active: false,
      ),
      Crime(
        nerve: 9,
        fullName: 'Armored Virus',
        shortName: 'Arm. Virus',
        action: 'armoredvirus',
        active: false,
      ),
      Crime(
        nerve: 9,
        fullName: 'Stealth virus',
        shortName: 'Sth. Virus',
        action: 'stealthvirus',
        active: false,
      ),

      // NERVE 10
      Crime(
        nerve: 10,
        fullName: 'Assassinate a target',
        shortName: 'Assassinate',
        action: 'assasination',
        active: false,
      ),
      Crime(
        nerve: 10,
        fullName: 'Drive by shooting',
        shortName: 'Shooting',
        action: 'driveby',
        active: false,
      ),
      Crime(
        nerve: 10,
        fullName: 'Car bomb',
        shortName: 'Car Bomb',
        action: 'carbomb',
        active: false,
      ),
      Crime(
        nerve: 10,
        fullName: 'Mob boss',
        shortName: 'Mob Boss',
        action: 'murdermobboss',
        active: false,
      ),

      // NERVE 11
      Crime(
        nerve: 11,
        fullName: 'Home',
        shortName: 'Home',
        action: 'home',
        active: false,
      ),
      Crime(
        nerve: 11,
        fullName: 'Car lot',
        shortName: 'Car Lot',
        action: 'car-lot',
        active: false,
      ),
      Crime(
        nerve: 11,
        fullName: 'Office building',
        shortName: 'Office',
        action: 'office-building',
        active: false,
      ),
      Crime(
        nerve: 11,
        fullName: 'Apartment building',
        shortName: 'Apartment',
        action: 'apartment-building',
        active: false,
      ),
      Crime(
        nerve: 11,
        fullName: 'Warehouse',
        shortName: 'Warehouse',
        action: 'warehouse',
        active: false,
      ),
      Crime(
        nerve: 11,
        fullName: 'Motel',
        shortName: 'Motel',
        action: 'motel',
        active: false,
      ),
      Crime(
        nerve: 11,
        fullName: 'Government building',
        shortName: 'Government',
        action: 'government-building',
        active: false,
      ),

      // NERVE 12
      Crime(
        nerve: 12,
        fullName: 'Steal a parked car',
        shortName: 'Steal Parked',
        action: 'parkedcar',
        active: false,
      ),
      Crime(
        nerve: 12,
        fullName: 'Hijack a car',
        shortName: 'Hijack Car',
        action: 'movingcar',
        active: false,
      ),
      Crime(
        nerve: 12,
        fullName: 'Steal car from showroom',
        shortName: 'Steal Showroom',
        action: 'carshop',
        active: false,
      ),

      // NERVE 13
      Crime(
        nerve: 13,
        fullName: 'Side door',
        shortName: 'Side Door',
        action: 'pawnshop',
        active: false,
      ),
      Crime(
        nerve: 13,
        fullName: 'Rear door',
        shortName: 'Rear Door',
        action: 'pawnshopcash',
        active: false,
      ),

      // NERVE 14
      Crime(
        nerve: 14,
        fullName: 'Money',
        shortName: 'Money',
        action: 'makemoney2',
        active: false,
      ),
      Crime(
        nerve: 14,
        fullName: 'Casino tokens',
        shortName: 'Casino',
        action: 'maketokens2',
        active: false,
      ),
      Crime(
        nerve: 14,
        fullName: 'Credit card',
        shortName: 'Credit Card',
        action: 'makecard',
        active: false,
      ),

      // NERVE 15
      Crime(
        nerve: 15,
        fullName: 'Kidnap kid',
        shortName: 'Knp Kid',
        action: 'napkid',
        active: false,
      ),
      Crime(
        nerve: 15,
        fullName: 'Kidnap woman',
        shortName: 'Knp Woman',
        action: 'napwomen',
        active: false,
      ),
      Crime(
        nerve: 15,
        fullName: 'Kidnap undercover cop',
        shortName: 'Knp Cop',
        action: 'napcop',
        active: false,
      ),
      Crime(
        nerve: 15,
        fullName: 'Kidnap mayor',
        shortName: 'Knp Mayor',
        action: 'napmayor',
        active: false,
      ),

      // NERVE 16
      Crime(
        nerve: 16,
        fullName: 'Explosives',
        shortName: 'Explosives',
        action: 'trafficbomb',
        active: false,
      ),
      Crime(
        nerve: 16,
        fullName: 'Firearms',
        shortName: 'Firearms',
        action: 'trafficarms',
        active: false,
      ),

      // NERVE 17
      Crime(
        nerve: 17,
        fullName: 'Bomb a factory',
        shortName: 'Bomb Factory',
        action: 'bombfactory',
        active: false,
      ),
      Crime(
        nerve: 17,
        fullName: 'Bomb a government building',
        shortName: 'Bomb Gov.',
        action: 'bombbuilding',
        active: false,
      ),

      // NERVE 18
      Crime(
        nerve: 18,
        fullName: 'Hack into a bank mainframe',
        shortName: 'Hack Bank',
        action: 'hackbank',
        active: false,
      ),
      Crime(
        nerve: 18,
        fullName: 'Hack the F.B.I. mainframe',
        shortName: 'Hack FBI',
        action: 'hackfbi',
        active: false,
      ),

    ]);
  }
}
