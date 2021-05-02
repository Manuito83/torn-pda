// Flutter imports:
import 'package:flutter/material.dart';

// Project imports:
import 'package:torn_pda/models/crimes/crime_model.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

class CrimesProvider extends ChangeNotifier {
  var activeCrimesList = <Crime>[];

  CrimesProvider() {
    _loadSavedCrimes();
  }

  void activateCrime(Crime newCrime) {
    activeCrimesList.add(newCrime);
    activeCrimesList.sort((a, b) => a.nerve.compareTo(b.nerve));
    _saveListAfterChanges();
    notifyListeners();
  }

  void deactivateCrime(Crime oldCrime) {
    activeCrimesList
        .removeWhere((element) => element.shortName == oldCrime.shortName);
    _saveListAfterChanges();
    notifyListeners();
  }

  void deactivateAllCrimes() {
    activeCrimesList.clear();
    _saveListAfterChanges();
    notifyListeners();
  }

  void _saveListAfterChanges() {
    var saveList = <String>[];
    for (var crime in activeCrimesList) {
      var save = crimeToJson(crime);
      saveList.add(save);
    }
    Prefs().setActiveCrimesList(saveList);
  }

  Future<void> _loadSavedCrimes() async {
    // Load crimes from shared preferences
    var rawLoad = await Prefs().getActiveCrimesList();
    for (var rawCrime in rawLoad) {
      activeCrimesList.add(crimeFromJson(rawCrime));
    }
    // Notification
    notifyListeners();
  }
}
