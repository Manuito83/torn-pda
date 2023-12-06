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
  Color? cardSurfaceTintColor;
  Color? statusBar;

  bool _useMaterial3 = true;
  bool get useMaterial3 => _useMaterial3;
  set useMaterial3(bool value) {
    _useMaterial3 = value;
    Prefs().setUseMaterial3(value);
    notifyListeners();
  }

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
  final _canvasBackgroundLIGHT = Colors.grey[50];
  final _colorBackgroundLIGHT = Colors.grey[200];
  final _colorMainTextLIGHT = Colors.black;
  final _colorButtonTextLIGHT = Colors.white;
  final _colorNavSelectedLIGHT = Colors.blueGrey[100];
  final _colorStatusBarLIGHT = Colors.blueGrey;
  // Cards
  final _colorCardLIGHT = Colors.white;
  final _surfaceTintCardLIGHT = Colors.white;

  // COLORS ##DARK##
  final _canvasBackgroundDARK = Colors.grey[900];
  final _colorBackgroundDARK = Colors.grey[800];
  final _colorMainTextDARK = Colors.grey[50];
  final _colorButtonTextDARK = Colors.grey[200];
  final _colorNavSelectedDARK = Colors.blueGrey[600];
  final _colorStatusBarDARK = Color.fromARGB(255, 37, 37, 37);
  // Cards
  final _colorCardDARK = Colors.grey[800];
  final _surfaceTintCardDARK = Colors.grey[800];

  // COLORS ##EXTRA DARK##
  final _canvasBackgroundExtraDARK = Colors.black;
  final _colorBackgroundExtraDARK = Color(0xFF0C0C0C);
  final _colorMainTextExtraDARK = Colors.grey[50];
  final _colorButtonTextExtraDARK = Colors.grey[200];
  final _colorNavSelectedExtraDARK = Colors.blueGrey[800];
  final _colorStatusBarExtraDARK = Color(0xFF0C0C0C);
  // Cards
  final _colorCardExtraDARK = Color.fromARGB(255, 14, 14, 14);
  final _surfaceTintCardExtraDARK = Color.fromARGB(255, 14, 14, 14);

  void _getColors() {
    switch (_currentTheme) {
      case AppTheme.light:
        canvas = _canvasBackgroundLIGHT;
        secondBackground = _colorBackgroundLIGHT;
        mainText = _colorMainTextLIGHT;
        buttonText = _colorButtonTextLIGHT;
        navSelected = _colorNavSelectedLIGHT;
        cardColor = _colorCardLIGHT;
        cardSurfaceTintColor = _surfaceTintCardLIGHT;
        statusBar = _colorStatusBarLIGHT;
      case AppTheme.dark:
        canvas = _canvasBackgroundDARK;
        secondBackground = _colorBackgroundDARK;
        mainText = _colorMainTextDARK;
        buttonText = _colorButtonTextDARK;
        navSelected = _colorNavSelectedDARK;
        cardColor = _colorCardDARK;
        cardSurfaceTintColor = _surfaceTintCardDARK;
        statusBar = _colorStatusBarDARK;
      case AppTheme.extraDark:
        canvas = _canvasBackgroundExtraDARK;
        secondBackground = _colorBackgroundExtraDARK;
        mainText = _colorMainTextExtraDARK;
        buttonText = _colorButtonTextExtraDARK;
        navSelected = _colorNavSelectedExtraDARK;
        cardColor = _colorCardExtraDARK;
        cardSurfaceTintColor = _surfaceTintCardExtraDARK;
        statusBar = _colorStatusBarExtraDARK;
    }
  }

  void _saveThemeSharedPrefs() {
    late String themeSave;
    switch (_currentTheme) {
      case AppTheme.light:
        themeSave = 'light';
      case AppTheme.dark:
        themeSave = 'dark';
      case AppTheme.extraDark:
        themeSave = 'extraDark';
    }
    Prefs().setAppTheme(themeSave);
  }

  Future<void> _restoreSharedPreferences() async {
    final String restoredTheme = await Prefs().getAppTheme();
    await analytics.setUserProperty(name: "theme", value: restoredTheme);
    switch (restoredTheme) {
      case 'light':
        _currentTheme = AppTheme.light;
      case 'dark':
        _currentTheme = AppTheme.dark;
      case 'extraDark':
        _currentTheme = AppTheme.extraDark;
    }

    useMaterial3 = await Prefs().getUseMaterial3();

    _getColors();
    notifyListeners();
  }
}
