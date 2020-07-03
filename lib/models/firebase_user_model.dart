import 'package:torn_pda/models/own_profile_model.dart';

class FirebaseUserModel extends OwnProfileModel {
  String token;
  bool energyNotification = false;
  bool travelNotification = false;

  FirebaseUserModel();

  FirebaseUserModel.fromProfileModel(OwnProfileModel model) {
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
      "travelNotification": travelNotification,
      "energyNotification": energyNotification,
    };
  }

  static FirebaseUserModel fromMap(Map data) {
    return FirebaseUserModel()
      ..energyNotification = data["energyNotification"] ?? false
      ..travelNotification = data["travelNotification"] ?? false
      ..playerId = data["playerId"]
      ..gender = data["gender"]
      ..level = data["level"]
      ..name = data["name"]
      ..life = Life()
      ..life.current = data["life"];
  }
}
