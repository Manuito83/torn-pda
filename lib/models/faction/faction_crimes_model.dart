// To parse this JSON data, do
//
//     final factionCrimesModel = factionCrimesModelFromJson(jsonString);

// Dart imports:
import 'dart:convert';

import 'package:firebase_crashlytics/firebase_crashlytics.dart';

FactionCrimesModel factionCrimesModelFromJson(String str) => FactionCrimesModel.fromJson("unknown", json.decode(str));

String factionCrimesModelToJson(FactionCrimesModel data) => json.encode(data.toJson());

class FactionCrimesModel {
  FactionCrimesModel({
    this.crimes,
  });

  Map<String, Crime> crimes;

  factory FactionCrimesModel.fromJson(String playerId, Map<String, dynamic> json) {
    try {
      if (json == null || json.isEmpty || json["crimes"] == null) {
        throw ("OC are empty");
      }

      var fc = FactionCrimesModel(
        crimes: Map.from(json["crimes"]).map((k, v) => MapEntry<String, Crime>(k, Crime.fromJson(v))),
      );

      return fc;
    } catch (e) {
      /* No Crashlytics in isolates
      var response = json == null
          ? "Null JSON"
          : json['crimes'] == null
              ? "Null JSON Crimes"
              : "Other";
      FirebaseCrashlytics.instance.log("PDA Crash at Faction Crimes Model");
      FirebaseCrashlytics.instance.recordError("Player ID: $playerId, Response: $response, Error: $e", null);
      */
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        "crimes": crimes == null ? null : Map.from(crimes).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
      };
}

class Crime {
  Crime({
    this.crimeId,
    this.crimeName,
    this.participants,
    this.timeStarted,
    this.timeReady,
    this.timeLeft,
    this.timeCompleted,
    this.initiated,
    this.initiatedBy,
    this.plannedBy,
    this.success,
    this.moneyGain,
    this.respectGain,
  });

  int crimeId;
  String crimeName;
  List<Map<String, Participant>> participants;
  int timeStarted;
  int timeReady;
  int timeLeft;
  int timeCompleted;
  int initiated;
  int initiatedBy;
  int plannedBy;
  int success;
  int moneyGain;
  int respectGain;

  factory Crime.fromJson(Map<String, dynamic> json) {
    try {
      var crimes = Crime(
        crimeId: json["crime_id"] == null ? null : json["crime_id"],
        crimeName: json["crime_name"] == null ? null : json["crime_name"],
        participants: json["participants"] == null
            ? null
            : List<Map<String, Participant>>.from(json["participants"].map((x) => Map.from(x)
                .map((k, v) => MapEntry<String, Participant>(k, v == null ? null : Participant.fromJson(v))))),
        timeStarted: json["time_started"] == null ? null : json["time_started"],
        timeReady: json["time_ready"] == null ? null : json["time_ready"],
        timeLeft: json["time_left"] == null ? null : json["time_left"],
        timeCompleted: json["time_completed"] == null ? null : json["time_completed"],
        initiated: json["initiated"] == null ? null : json["initiated"],
        initiatedBy: json["initiated_by"] == null ? null : json["initiated_by"],
        plannedBy: json["planned_by"] == null ? null : json["planned_by"],
        success: json["success"] == null ? null : json["success"],
        moneyGain: json["money_gain"] == null ? null : json["money_gain"],
        respectGain: json["respect_gain"] == null ? null : json["respect_gain"],
      );

      return crimes;
    } catch (e) {
      FirebaseCrashlytics.instance.log("PDA Crash at Faction Crimes Model [Crime]");
      FirebaseCrashlytics.instance.recordError("Error: $e", null);
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        "crime_id": crimeId == null ? null : crimeId,
        "crime_name": crimeName == null ? null : crimeName,
        "participants": participants == null
            ? null
            : List<dynamic>.from(participants
                .map((x) => Map.from(x).map((k, v) => MapEntry<String, dynamic>(k, v == null ? null : v.toJson())))),
        "time_started": timeStarted == null ? null : timeStarted,
        "time_ready": timeReady == null ? null : timeReady,
        "time_left": timeLeft == null ? null : timeLeft,
        "time_completed": timeCompleted == null ? null : timeCompleted,
        "initiated": initiated == null ? null : initiated,
        "initiated_by": initiatedBy == null ? null : initiatedBy,
        "planned_by": plannedBy == null ? null : plannedBy,
        "success": success == null ? null : success,
        "money_gain": moneyGain == null ? null : moneyGain,
        "respect_gain": respectGain == null ? null : respectGain,
      };
}

class Participant {
  Participant({
    this.description,
    this.details,
    this.state,
    this.color,
    this.until,
  });

  String description;
  String details;
  String state;
  String color;
  int until;

  factory Participant.fromJson(Map<String, dynamic> json) {
    try {
      var participant = Participant(
        description: json["description"] == null ? null : json["description"],
        details: json["details"] == null ? null : json["details"],
        state: json["state"] == null ? null : json["state"],
        color: json["color"] == null ? null : json["color"],
        until: json["until"] == null ? null : json["until"],
      );

      return participant;
    } catch (e) {
      FirebaseCrashlytics.instance.log("PDA Crash at Faction Crimes Model [Participant]");
      FirebaseCrashlytics.instance.recordError("Error: $e", null);
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        "description": description == null ? null : description,
        "details": details == null ? null : details,
        "state": state == null ? null : state,
        "color": color == null ? null : color,
        "until": until == null ? null : until,
      };
}
