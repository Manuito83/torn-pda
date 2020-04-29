class TravelModel {
  bool travelling;
  String destination;
  int timeLeft;
  DateTime timeArrival;

  TravelModel({this.destination, this.timeLeft,
    this.timeArrival, this.travelling = false}) {
    if (timeArrival == null) {
      this.timeArrival = DateTime.now();
    }

  }

  factory TravelModel.fromJson(Map<String, dynamic> json) {
    var destination = json['travel']['destination'];
    var timeLeft = json['travel']['time_left'];
    bool active = false;
    if (destination != 'Torn' || timeLeft > 0) {
      active = true;
    }
    var timeStampRaw = json['travel']['timestamp'];
    var timeStamp = new DateTime.fromMillisecondsSinceEpoch(timeStampRaw * 1000);
    return TravelModel(
      destination: destination,
      timeLeft: timeLeft,
      timeArrival: timeStamp,
      travelling: active,
    );
  }
}