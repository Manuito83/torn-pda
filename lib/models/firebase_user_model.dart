import 'package:torn_pda/models/profile_model.dart';

class FirebaseUserModel extends ProfileModel {
  String token;
  bool energyFullReminder = false;
  FirebaseUserModel.fromProfileModel(ProfileModel model) {
    playerId = model.playerId;
    lastAction = model.lastAction;
    gender = model.gender;
    level = model.level;
    status = model.status;
    rank = model.rank;
    name = model.name;
    life = model.life;
  }

  toMap() {
    return {
      "name": name,
      "rank": rank,
      "life": life,
      "level": level,
      "token": token,
      "gender": gender,
      "status": status,
      "lastAction": lastAction,
      "energyFullReminder": energyFullReminder,
    };
  }
}
