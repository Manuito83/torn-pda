import 'package:flutter/material.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

enum AppTheme {
  light,
  dark,
}

class ThemeProvider extends ChangeNotifier {
  Color background;
  Color mainText;
  Color buttonText;
  Color navSelected;

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
  var _colorBackgroundLIGHT = Colors.grey[200];
  var _colorMainTextLIGHT = Colors.black;
  var _colorButtonTextLIGHT = Colors.white;
  var _colorNavSelectedLIGHT = Colors.blueGrey[100];

  // COLORS ##DARK##
  var _colorBackgroundDARK = Colors.grey[800];
  var _colorMainTextDARK = Colors.grey[50];
  var _colorButtonTextDARK = Colors.grey[200];
  var _colorNavSelectedDARK = Colors.blueGrey[600];

  void _getColors() {
    switch (_currentTheme) {
      case AppTheme.light:
        background = _colorBackgroundLIGHT;
        mainText = _colorMainTextLIGHT;
        buttonText = _colorButtonTextLIGHT;
        navSelected = _colorNavSelectedLIGHT;
        break;
      case AppTheme.dark:
        background = _colorBackgroundDARK;
        mainText = _colorMainTextDARK;
        buttonText = _colorButtonTextDARK;
        navSelected = _colorNavSelectedDARK;
        break;
    }
  }

  void _saveThemeSharedPrefs() {
    String themeSave;
    switch (_currentTheme) {
      case AppTheme.light:
        themeSave = 'light';
        break;
      case AppTheme.dark:
        themeSave = 'dark';
        break;
    }
    SharedPreferencesModel().setAppTheme(themeSave);
  }

  Future<void> _restoreSharedPreferences() async {
    String restoredTheme = await SharedPreferencesModel().getAppTheme();
    switch (restoredTheme) {
      case 'light':
        _currentTheme = AppTheme.light;
        break;
      case 'dark':
        _currentTheme = AppTheme.dark;
        break;
    }
    _getColors();
    notifyListeners();
  }
}
