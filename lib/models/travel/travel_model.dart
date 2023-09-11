class TravelModel {
  bool abroad;
  String? destination;
  int? timeLeft;
  int? timeStamp;
  DateTime? timeArrival;
  int? departed;
  int? moneyOnhand;

  TravelModel({
    this.abroad = false,
    this.destination,
    this.timeLeft,
    this.timeStamp,
    this.timeArrival,
    this.departed,
    this.moneyOnhand,
  }) {
    timeArrival ??= DateTime.now();
  }

  factory TravelModel.fromJson(Map<String, dynamic> json) {
    final destination = json['travel']['destination'];
    final timeLeft = json['travel']['time_left'];
    final timestamp = json['travel']['timestamp'];
    final departed = json['travel']['departed'];
    final moneyOnHand = json["money_onhand"];

    bool active = false;
    if (destination != 'Torn' || timeLeft > 0) {
      active = true;
    }

    final timeArrival =
        DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

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
