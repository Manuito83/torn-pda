import 'package:torn_pda/models/own_profile_model.dart';

class FirebaseUserModel extends OwnProfileModel {
  String token;
  String uid;
  bool energyNotification = false;
  bool travelNotification = false;
  bool energyLastCheckFull = false;

  FirebaseUserModel();

  FirebaseUserModel.fromProfileModel(OwnProfileModel model) {
    playerId = model.playerId;
    level = model.level;
    status = model.status;
    name = model.name;
    life = model.life;
  }

  toMap() {
    return {
      "uid": uid,
      "name": name,
      "life": life,
      "level": level,
      "token": token,
      "status": status,
      "travelNotification": travelNotification,
      "energyNotification": energyNotification,
      "energyLastCheckFull": energyLastCheckFull
    };
  }

  static FirebaseUserModel fromMap(Map data) {
    return FirebaseUserModel()
      ..energyNotification = data["energyNotification"] ?? false
      ..travelNotification = data["travelNotification"] ?? false
      ..energyLastCheckFull = data["energyLastCheckFull"] ?? false
      ..playerId = data["playerId"]
      ..level = data["level"]
      ..name = data["name"]
      ..life = Life()
      ..life.current = data["life"];
  }
}
