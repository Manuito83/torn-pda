// Flutter imports:
import 'package:flutter/material.dart';
import 'package:torn_pda/main.dart';

// Project imports:
import 'package:torn_pda/utils/shared_prefs.dart';

enum AppTheme {
  light,
  dark,
  extraDark,
}

class ThemeProvider extends ChangeNotifier {
  Color? canvas;
  Color? secondBackground;
  Color? mainText;
  Color? buttonText;
  Color? navSelected;
  Color? cardColor;
  Color? statusBar;

  ThemeProvider() {
    _restoreSharedPreferences();
  }

  var _currentTheme = AppTheme.light;
  AppTheme get currentTheme => _currentTheme;
  set changeTheme(AppTheme themeType) {
    _currentTheme = themeType;
    _getColors();
    _saveThemeSharedPrefs();
    notifyListeners();
  }

  // COLORS ##LIGHT##
  var _canvasBackgroundLIGHT = Colors.grey[50];
  var _colorBackgroundLIGHT = Colors.grey[200];
  var _colorMainTextLIGHT = Colors.black;
  var _colorButtonTextLIGHT = Colors.white;
  var _colorNavSelectedLIGHT = Colors.blueGrey[100];
  var _colorCardLIGHT = Colors.white;
  var _colorStatusBarLIGHT = Colors.blueGrey;

  // COLORS ##DARK##
  var _canvasBackgroundDARK = Colors.grey[900];
  var _colorBackgroundDARK = Colors.grey[800];
  var _colorMainTextDARK = Colors.grey[50];
  var _colorButtonTextDARK = Colors.grey[200];
  var _colorNavSelectedDARK = Colors.blueGrey[600];
  var _colorCardDARK = Colors.grey[800];
  var _colorStatusBarDARK = Color.fromARGB(255, 37, 37, 37);

  // COLORS ##EXTRA DARK##
  var _canvasBackgroundExtraDARK = Colors.black;
  var _colorBackgroundExtraDARK = Color(0xFF0C0C0C);
  var _colorMainTextExtraDARK = Colors.grey[50];
  var _colorButtonTextExtraDARK = Colors.grey[200];
  var _colorNavSelectedExtraDARK = Colors.blueGrey[800];
  var _colorCardExtraDARK = Color(0xFF131313);
  var _colorStatusBarExtraDARK = Color(0xFF0C0C0C);

  void _getColors() {
    switch (_currentTheme) {
      case AppTheme.light:
        canvas = _canvasBackgroundLIGHT;
        secondBackground = _colorBackgroundLIGHT;
        mainText = _colorMainTextLIGHT;
        buttonText = _colorButtonTextLIGHT;
        navSelected = _colorNavSelectedLIGHT;
        cardColor = _colorCardLIGHT;
        statusBar = _colorStatusBarLIGHT;
        break;
      case AppTheme.dark:
        canvas = _canvasBackgroundDARK;
        secondBackground = _colorBackgroundDARK;
        mainText = _colorMainTextDARK;
        buttonText = _colorButtonTextDARK;
        navSelected = _colorNavSelectedDARK;
        cardColor = _colorCardDARK;
        statusBar = _colorStatusBarDARK;
        break;
      case AppTheme.extraDark:
        canvas = _canvasBackgroundExtraDARK;
        secondBackground = _colorBackgroundExtraDARK;
        mainText = _colorMainTextExtraDARK;
        buttonText = _colorButtonTextExtraDARK;
        navSelected = _colorNavSelectedExtraDARK;
        cardColor = _colorCardExtraDARK;
        statusBar = _colorStatusBarExtraDARK;
        break;
    }
  }

  void _saveThemeSharedPrefs() {
    late String themeSave;
    switch (_currentTheme) {
      case AppTheme.light:
        themeSave = 'light';
        break;
      case AppTheme.dark:
        themeSave = 'dark';
        break;
      case AppTheme.extraDark:
        themeSave = 'extraDark';
        break;
    }
    Prefs().setAppTheme(themeSave);
  }

  Future<void> _restoreSharedPreferences() async {
    String restoredTheme = await Prefs().getAppTheme();
    await analytics.setUserProperty(name: "theme", value: restoredTheme);
    switch (restoredTheme) {
      case 'light':
        _currentTheme = AppTheme.light;
        break;
      case 'dark':
        _currentTheme = AppTheme.dark;
        break;
      case 'extraDark':
        _currentTheme = AppTheme.extraDark;
        break;
    }

    _getColors();
    notifyListeners();
  }
}
