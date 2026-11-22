import 'package:flutter/services.dart';
import 'package:torn_pda/models/app_orientations.dart';
import 'package:torn_pda/providers/settings_provider.dart';

class TerritoryMapOrientation {
  TerritoryMapOrientation(this._settings);

  final SettingsProvider _settings;
  bool _landscape = false;

  bool get landscape => _landscape;

  void toggle() {
    _landscape = !_landscape;
    _apply();
  }

  void release() =>
      SystemChrome.setPreferredOrientations(appOrientations(allowRotation: _settings.allowScreenRotation));

  void resume() => _apply();

  void _apply() {
    if (_landscape) {
      SystemChrome.setPreferredOrientations(landscapeOrientations);
    } else {
      release();
    }
  }
}
