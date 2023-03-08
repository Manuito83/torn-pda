class ChainingPayload {
  List<String> attackIdList;
  List<String> attackNameList;
  List<String> attackNotesList;
  List<String> attackNotesColorList;
  Function(List<String>) attacksCallback;
  bool war = false;
  bool panic = false;
  bool showNotes;
  bool showBlankNotes;
  bool showOnlineFactionWarning;
}
