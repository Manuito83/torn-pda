class ProfileModel {
  String name;
  int level;
  String gender;
  String rank;
  int playerId;
  int life;
  String status;
  String lastAction;

  ProfileModel(
      {this.name,
      this.gender,
      this.lastAction,
      this.level,
      this.life,
      this.playerId,
      this.rank,
      this.status});

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    var name = json['name'];
    var level = json['level'];
    var gender = json['gender'];
    var rank = json['rank'];
    var playerId = json['player_id'];
    var life = json['life']['current'];
    var status = json['status']['description'];
    var lastAction = json['last_action']['relative'];

    return ProfileModel(
      name: name,
      level: level,
      gender: gender,
      rank: rank,
      playerId: playerId,
      life: life,
      status: status,
      lastAction: lastAction,
    );
  }
}
