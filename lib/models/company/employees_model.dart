// To parse this JSON data, do
//
//     final companyEmployees = companyEmployeesFromJson(jsonString);

import 'dart:convert';

CompanyEmployees companyEmployeesFromJson(String str) => CompanyEmployees.fromJson(json.decode(str));

String companyEmployeesToJson(CompanyEmployees data) => json.encode(data.toJson());

class CompanyEmployees {
  Map<String, CompanyEmployee>? companyEmployees;

  CompanyEmployees({
    this.companyEmployees,
  });

  factory CompanyEmployees.fromJson(Map<String, dynamic> json) {
    if (json["company_employees"] == null) throw ArgumentError("PDA Error at company employees!");
    return CompanyEmployees(
      companyEmployees: Map.from(json["company_employees"])
          .map((k, v) => MapEntry<String, CompanyEmployee>(k, CompanyEmployee.fromJson(v))),
    );
  }

  Map<String, dynamic> toJson() => {
        "company_employees": Map.from(companyEmployees!).map((k, v) => MapEntry<String, dynamic>(k, v.toJson())),
      };
}

class CompanyEmployee {
  String? name;
  String? position;
  int? daysInCompany;
  int? manualLabor;
  int? intelligence;
  int? endurance;
  Effectiveness? effectiveness;
  LastAction? lastAction;
  Status? status;
  int? wage;

  CompanyEmployee({
    this.name,
    this.position,
    this.daysInCompany,
    this.manualLabor,
    this.intelligence,
    this.endurance,
    this.effectiveness,
    this.lastAction,
    this.status,
    this.wage,
  });

  factory CompanyEmployee.fromJson(Map<String, dynamic> json) => CompanyEmployee(
        name: json["name"],
        position: json["position"],
        daysInCompany: json["days_in_company"],
        manualLabor: json["manual_labor"],
        intelligence: json["intelligence"],
        endurance: json["endurance"],
        effectiveness: Effectiveness.fromJson(json["effectiveness"]),
        lastAction: LastAction.fromJson(json["last_action"]),
        status: Status.fromJson(json["status"]),
        wage: json["wage"],
      );

  Map<String, dynamic> toJson() => {
        "name": name,
        "position": position,
        "days_in_company": daysInCompany,
        "manual_labor": manualLabor,
        "intelligence": intelligence,
        "endurance": endurance,
        "effectiveness": effectiveness!.toJson(),
        "last_action": lastAction!.toJson(),
        "status": status!.toJson(),
        "wage": wage,
      };
}

class Effectiveness {
  int? workingStats;
  int? settledIn;
  int? directorEducation;
  int? total;
  int? addiction;
  int? merits;
  int? inactivity;

  Effectiveness({
    this.workingStats,
    this.settledIn,
    this.directorEducation,
    this.total,
    this.addiction,
    this.merits,
    this.inactivity,
  });

  factory Effectiveness.fromJson(Map<String, dynamic> json) => Effectiveness(
        workingStats: json["working_stats"],
        settledIn: json["settled_in"],
        directorEducation: json["director_education"],
        total: json["total"],
        addiction: json["addiction"],
        merits: json["merits"],
        inactivity: json["inactivity"],
      );

  Map<String, dynamic> toJson() => {
        "working_stats": workingStats,
        "settled_in": settledIn,
        "director_education": directorEducation,
        "total": total,
        "addiction": addiction,
        "merits": merits,
        "inactivity": inactivity,
      };
}

class LastAction {
  String? status;
  int? timestamp;
  String? relative;

  LastAction({
    this.status,
    this.timestamp,
    this.relative,
  });

  factory LastAction.fromJson(Map<String, dynamic> json) => LastAction(
        status: json["status"],
        timestamp: json["timestamp"],
        relative: json["relative"],
      );

  Map<String, dynamic> toJson() => {
        "status": status,
        "timestamp": timestamp,
        "relative": relative,
      };
}

class Status {
  String? description;
  String? details;
  String? state;
  String? color;
  int? until;

  Status({
    this.description,
    this.details,
    this.state,
    this.color,
    this.until,
  });

  factory Status.fromJson(Map<String, dynamic> json) => Status(
        description: json["description"],
        details: json["details"],
        state: json["state"],
        color: json["color"],
        until: json["until"],
      );

  Map<String, dynamic> toJson() => {
        "description": description,
        "details": details,
        "state": state,
        "color": color,
        "until": until,
      };
}
