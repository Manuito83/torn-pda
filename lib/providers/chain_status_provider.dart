import 'package:flutter/material.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/chaining/chain_timer.dart';

/// Allows to coordinate between different chain widgets, as only one should be submitting
/// alerts (sounds/vibration) at any given time, but several of them might coexist
/// in children/parent widgets
class ChainStatusProvider extends ChangeNotifier {

  bool preferencesLoaded = false;

  /// This is the last alert that has been reported by the active chain widget
  ChainWatcherColor watcherColorReportedByActive = ChainWatcherColor.off;

  bool watcherActive = false;
  bool watcherActiveTargets = false;
  bool watcherActiveWebView = false;

  bool soundActive = true;
  bool vibrationActive = true;

  // When we switch to targets
  _activateWatcherInTargets() {
     watcherActive = true;
     watcherActiveTargets = true;
     watcherActiveWebView = false;
  }

  // When we launch the webView for attacks
  _activateWatcherInWebView() {
     watcherActive = true;
     watcherActiveTargets = false;
     watcherActiveWebView = true;
  }

  /// Specify with [newParent] which chain watcher becomes active
  /// Use [activate] if you want to activate the watcher manually at the same time (normally only
  /// after user interaction)
  watcherAssignParent({@required ChainTimerParent newParent, bool activate = false}) {
    if (activate) {
      watcherActive = true;
    }
    if (watcherActive) {
      if (newParent == ChainTimerParent.targets) {
        _activateWatcherInTargets();
      } else if (newParent == ChainTimerParent.webView) {
        _activateWatcherInWebView();
      }
    }
  }

  watcherDeactivate () {
    watcherActive = false;
    watcherActiveTargets = false;
    watcherActiveWebView = false;
    watcherColorReportedByActive = ChainWatcherColor.off;
  }

  loadPreferences () async {
    soundActive = await SharedPreferencesModel().getChainWatcherSound();
    vibrationActive = await SharedPreferencesModel().getChainWatcherVibration();
    preferencesLoaded = true;
  }

}