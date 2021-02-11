class TravelModel {
  bool abroad;
  String destination;
  int timeLeft;
  int timeStamp;
  DateTime timeArrival;
  int departed;
  int moneyOnhand;

  TravelModel({
    this.abroad = false,
    this.destination,
    this.timeLeft,
    this.timeStamp,
    this.timeArrival,
    this.departed,
    this.moneyOnhand,
  }) {
    if (timeArrival == null) {
      this.timeArrival = DateTime.now();
    }
  }

  factory TravelModel.fromJson(Map<String, dynamic> json) {
    var destination = json['travel']['destination'];
    var timeLeft = json['travel']['time_left'];
    var timestamp = json['travel']['timestamp'];
    var departed = json['travel']['departed'];
    var moneyOnHand = json["money_onhand"];

    bool active = false;
    if (destination != 'Torn' || timeLeft > 0) {
      active = true;
    }

    var timeArrival =
        new DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

    return TravelModel(
      abroad: active,
      destination: destination,
      timeLeft: timeLeft,
      timeStamp: timestamp,
      timeArrival: timeArrival,
      departed: departed,
      moneyOnhand: moneyOnHand,
    );
  }
}
