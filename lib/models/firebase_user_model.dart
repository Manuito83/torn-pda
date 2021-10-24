// Project imports:
import 'package:torn_pda/models/profile/own_profile_model.dart';

class FirebaseUserModel extends OwnProfileExtended {
  String token;
  String uid;
  bool travelNotification = false;
  bool foreignRestockNotification = false;
  bool energyNotification = false;
  bool energyLastCheckFull = false;
  bool nerveNotification = false;
  bool nerveLastCheckFull = false;
  bool hospitalNotification = false;
  bool drugsNotification = false;
  bool drugsInfluence = false;
  bool racingNotification = false;
  bool messagesNotification = false;
  bool eventsNotification = false;
  List eventsFilter = [];
  bool refillsNotification = false;
  int refillsTime = 22;
  List refillsRequested = [];
  bool racingSent = false;
  bool stockMarketNotification = false;
  List stockMarketShares = [];
  bool factionAssistMessage = true;

  FirebaseUserModel();

  FirebaseUserModel.fromProfileModel(OwnProfileExtended model) {
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
      "foreignRestockNotification": foreignRestockNotification,
      "energyNotification": energyNotification,
      "energyLastCheckFull": energyLastCheckFull,
      "nerveNotification": nerveNotification,
      "nerveLastCheckFull": nerveLastCheckFull,
      "hospitalNotification": hospitalNotification,
      "drugsNotification": drugsNotification,
      "drugsInfluence": drugsInfluence,
      "racingNotification": racingNotification,
      "messagesNotification": messagesNotification,
      "eventsNotification": eventsNotification,
      "eventsFilter": eventsFilter,
      "refillsNotification": refillsNotification,
      "refillsTime": refillsTime,
      "refillsRequested": refillsRequested,
      "racingSent": racingSent,
      "stockMarketNotification": stockMarketNotification,
      "stockMarketShares": stockMarketShares,
      "factionAssistMessage": factionAssistMessage,
    };
  }

  static FirebaseUserModel fromMap(Map data) {
    return FirebaseUserModel()
      ..travelNotification = data["travelNotification"] ?? false
      ..foreignRestockNotification = data["foreignRestockNotification"] ?? false
      ..energyNotification = data["energyNotification"] ?? false
      ..energyLastCheckFull = data["energyLastCheckFull"] ?? false
      ..nerveNotification = data["nerveNotification"] ?? false
      ..nerveLastCheckFull = data["nerveLastCheckFull"] ?? false
      ..hospitalNotification = data["hospitalNotification"] ?? false
      ..drugsNotification = data["drugsNotification"] ?? false
      ..drugsInfluence = data["drugsInfluence"] ?? false
      ..racingNotification = data["racingNotification"] ?? false
      ..messagesNotification = data["messagesNotification"] ?? false
      ..eventsNotification = data["eventsNotification"] ?? false
      ..eventsFilter = data["eventsFilter"] ?? []
      ..refillsNotification = data["refillsNotification"] ?? false
      ..refillsTime = data["refillsTime"] ?? 22
      ..refillsRequested = data["refillsRequested"] ?? []
      ..racingSent = data["racingSent"] ?? false
      ..playerId = data["playerId"]
      ..level = data["level"]
      ..name = data["name"]
      ..life = Life()
      ..life.current = data["life"]
      ..stockMarketNotification = data["stockMarketNotification"] ?? false
      ..stockMarketShares = data["stockMarketShares"] ?? []
      ..factionAssistMessage = data["factionAssistMessage"] ?? true;
  }
}
