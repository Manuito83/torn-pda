import 'package:torn_pda/models/profile_model.dart';

class FirebaseUserModel extends ProfileModel {
  String token;
  bool energyNotification = false, travelNotification = false;

  FirebaseUserModel();

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
      "travelNotificaion": travelNotification,
      "energyNotification": energyNotification,
    };
  }

  static FirebaseUserModel fromMap(Map data) {
    return FirebaseUserModel()
      ..energyNotification = data["energyNotification"] ?? false
      ..travelNotification = data["travelNotificaion"] ?? false
      ..lastAction = data["lastAction"]
      ..playerId = data["playerId"]
      ..status = data["status"]
      ..gender = data["gender"]
      ..level = data["level"]
      ..rank = data["rank"]
      ..name = data["name"]
      ..life = data["life"];
  }
}
