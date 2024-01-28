enum BackupPrefs {
  shortcuts,
  userscripts,
  targets,
}

class BackupPrefsGroups {
  static final List<List<String>> _validKeys = [
    // Shortcuts
    ['pda_activeShortcutsList', 'pda_shortcutMenu', 'pda_shortcutTile'],
    // Userscripts
    ['pda_userScriptsList'],
    // Targets
    ['pda_targetsList'],
  ];

  static bool assessIncoming(Map<String, dynamic> serverPrefs, BackupPrefs pref) {
    final validKeys = _validKeys[pref.index];
    return validKeys.any((key) => serverPrefs.containsKey(key));
  }
}
