class ChainingPayload {
  late List<String> attackIdList;
  late List<String?> attackNameList;
  late List<String?> attackNotesList;
  late List<String?> attackNotesColorList;
  Function(List<String>)? attacksCallback;
  bool war = false;
  bool panic = false;
  bool skipAutoUpdate = false;
  late bool showNotes;
  late bool showBlankNotes;
  late bool showOnlineFactionWarning;
}
