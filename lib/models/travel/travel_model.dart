class TravelModel {
  bool travelling;
  String destination;
  int timeLeft;
  int timeStamp;
  DateTime timeArrival;
  int departed;

  TravelModel({
    this.travelling = false,
    this.destination,
    this.timeLeft,
    this.timeStamp,
    this.timeArrival,
    this.departed,
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

    bool active = false;
    if (destination != 'Torn' || timeLeft > 0) {
      active = true;
    }

    var timeArrival =
        new DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

    return TravelModel(
      travelling: active,
      destination: destination,
      timeLeft: timeLeft,
      timeStamp: timestamp,
      timeArrival: timeArrival,
      departed: departed,
    );
  }
}
