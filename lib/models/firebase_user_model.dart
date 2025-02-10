// Project imports:
import 'package:torn_pda/models/profile/own_profile_model.dart';

class FirebaseUserModel extends OwnProfileExtended {
  String? token;
  String? uid;
  bool discreet = false;
  bool? travelNotification = false;
  bool? foreignRestockNotification = false;
  bool? foreignRestockNotificationOnlyCurrentCountry = false;
  bool? energyNotification = false;
  bool energyLastCheckFull = true;
  bool? nerveNotification = false;
  bool nerveLastCheckFull = true;
  bool? lifeNotification = false;
  bool lifeLastCheckFull = true;
  List lootAlerts = [];
  bool? lootRangersAlerts = false;
  bool? hospitalNotification = false;
  bool? drugsNotification = false;
  bool drugsInfluence = false;
  bool? medicalNotification = false;
  bool medicalInfluence = false;
  bool? boosterNotification = false;
  bool boosterInfluence = false;
  bool? racingNotification = false;
  bool? messagesNotification = false;
  bool? eventsNotification = false;
  List eventsFilter = [];
  bool? refillsNotification = false;
  int? refillsTime = 22;
  List refillsRequested = [];
  bool racingSent = true;
  bool? stockMarketNotification = false;
  List stockMarketShares = [];
  bool? factionAssistMessage = true;
  bool? retalsNotification = false;
  bool? retalsNotificationDonor = false;
  bool? forumsSubscription = false;

  FirebaseUserModel();

  FirebaseUserModel.fromProfileModel(OwnProfileExtended model) {
    playerId = model.playerId;
    level = model.level;
    status = model.status;
    name = model.name;
    life = model.life;
  }

  Map<String, Object?> toMap() {
    return {
      "uid": uid,
      "name": name,
      "life": life,
      "level": level,
      "token": token,
      "status": status,
      "discrete": discreet, // We need to accept this typo (discreet)
      "travelNotification": travelNotification,
      "foreignRestockNotification": foreignRestockNotification,
      "foreignRestockNotificationOnlyCurrentCountry": foreignRestockNotificationOnlyCurrentCountry,
      "energyNotification": energyNotification,
      "energyLastCheckFull": energyLastCheckFull,
      "nerveNotification": nerveNotification,
      "nerveLastCheckFull": nerveLastCheckFull,
      "lifeNotification": lifeNotification,
      "lifeLastCheckFull": lifeLastCheckFull,
      "lootAlerts": lootAlerts,
      "lootRangersNotification": lootRangersAlerts,
      "hospitalNotification": hospitalNotification,
      "drugsNotification": drugsNotification,
      "drugsInfluence": drugsInfluence,
      "medicalNotification": medicalNotification,
      "medicalInfluence": medicalInfluence,
      "boosterNotification": boosterNotification,
      "boosterInfluence": boosterInfluence,
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
      "retalsNotification": retalsNotification,
      "retalsNotificationDonor": retalsNotificationDonor,
      "forumsSubscriptionsNotification": forumsSubscription,
    };
  }

  static FirebaseUserModel fromMap(Map data) {
    return FirebaseUserModel()
      ..discreet = data["discrete"] ?? false // We need to accept this typo (discreet)
      ..travelNotification = data["travelNotification"] ?? false
      ..foreignRestockNotification = data["foreignRestockNotification"] ?? false
      ..foreignRestockNotificationOnlyCurrentCountry = data["foreignRestockNotificationOnlyCurrentCountry"] ?? false
      ..energyNotification = data["energyNotification"] ?? false
      ..energyLastCheckFull = data["energyLastCheckFull"] ?? false
      ..nerveNotification = data["nerveNotification"] ?? false
      ..nerveLastCheckFull = data["nerveLastCheckFull"] ?? false
      ..lifeNotification = data["lifeNotification"] ?? false
      ..lifeLastCheckFull = data["lifeLastCheckFull"] ?? false
      ..lootAlerts = data["lootAlerts"] ?? []
      ..lootRangersAlerts = data["lootRangersNotification"] ?? false
      ..hospitalNotification = data["hospitalNotification"] ?? false
      ..drugsNotification = data["drugsNotification"] ?? false
      ..drugsInfluence = data["drugsInfluence"] ?? false
      ..medicalNotification = data["medicalNotification"] ?? false
      ..medicalInfluence = data["medicalInfluence"] ?? false
      ..boosterNotification = data["boosterNotification"] ?? false
      ..boosterInfluence = data["boosterInfluence"] ?? false
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
      ..life!.current = data["life"]
      ..stockMarketNotification = data["stockMarketNotification"] ?? false
      ..stockMarketShares = data["stockMarketShares"] ?? []
      ..factionAssistMessage = data["factionAssistMessage"] ?? true
      ..retalsNotification = data["retalsNotification"] ?? false
      ..retalsNotificationDonor = data["retalsNotificationDonor"] ?? false
      ..forumsSubscription = data["forumsSubscriptionsNotification"] ?? false;
  }
}
