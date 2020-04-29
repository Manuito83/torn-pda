import 'package:flutter/material.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

enum BrowserSetting {
  app,
  external
}


class SettingsProvider extends ChangeNotifier {
  Color background;
  Color mainText;
  Color buttonText;
  Color navSelected;

  SettingsProvider() {
    _restoreSharedPreferences();
  }

  var _currentBrowser = BrowserSetting.app;
  BrowserSetting get currentBrowser => _currentBrowser;
  set changeBrowser(BrowserSetting browserType) {
    _currentBrowser = browserType;
    _saveThemeSharedPrefs();
    notifyListeners();
  }

  void _saveThemeSharedPrefs() {
    String browserSave;
    switch (_currentBrowser) {
      case BrowserSetting.app:
        browserSave = 'app';
        break;
      case BrowserSetting.external:
        browserSave = 'external';
        break;
    }
    SharedPreferencesModel().setDefaultBrowser(browserSave);
  }

  Future<void> _restoreSharedPreferences() async {
    String restoredBrowser = await SharedPreferencesModel().getDefaultBrowser();
    switch (restoredBrowser) {
      case 'app':
        _currentBrowser = BrowserSetting.app;
        break;
      case 'external':
        _currentBrowser = BrowserSetting.external;
        break;
    }
    notifyListeners();
  }
}
