import 'dart:convert';

/// player-flights response (premium)
class FFScouterFlightsResponse {
  final int? playerId;

  /// In-progress flight, if traveling
  final FFScouterFlight? current;

  /// Recently completed flights (most recent first)
  final List<FFScouterFlight> recentFlights;

  FFScouterFlightsResponse({this.playerId, this.current, this.recentFlights = const []});

  bool get hasCurrentFlight => current != null;

  factory FFScouterFlightsResponse.fromJson(Map<String, dynamic> json) => FFScouterFlightsResponse(
    playerId: json["player_id"],
    current: json["current"] != null ? FFScouterFlight.fromJson(json["current"]) : null,
    recentFlights: json["recent_flights"] is List
        ? (json["recent_flights"] as List).map((e) => FFScouterFlight.fromJson(e)).toList()
        : const [],
  );
}

FFScouterFlightsResponse ffScouterFlightsFromJson(String str) => FFScouterFlightsResponse.fromJson(json.decode(str));

/// A single flight
class FFScouterFlight {
  final int? takeoffTime;
  final String? statusDescription;
  final int? earliestArrivalTime;
  final int? latestArrivalTime;
  final String? travelMethod;
  final bool? bookLikelyBeingUsed;

  /// Only present for completed trips
  final int? approxLandingTime;

  FFScouterFlight({
    this.takeoffTime,
    this.statusDescription,
    this.earliestArrivalTime,
    this.latestArrivalTime,
    this.travelMethod,
    this.bookLikelyBeingUsed,
    this.approxLandingTime,
  });

  factory FFScouterFlight.fromJson(Map<String, dynamic> json) => FFScouterFlight(
    takeoffTime: json["takeoff_time"],
    statusDescription: json["status_description"],
    earliestArrivalTime: json["earliest_arrival_time"],
    latestArrivalTime: json["latest_arrival_time"],
    travelMethod: json["travel_method"],
    bookLikelyBeingUsed: json["book_likely_being_used"],
    approxLandingTime: json["approx_landing_time"],
  );

  /// Best landing estimate (epoch s): confirmed landing, else window midpoint
  int? get estimatedArrival {
    if (approxLandingTime != null) return approxLandingTime;
    if (earliestArrivalTime != null && latestArrivalTime != null) {
      return ((earliestArrivalTime! + latestArrivalTime!) / 2).round();
    }
    return earliestArrivalTime ?? latestArrivalTime;
  }

  /// Arrival window has a spread worth showing
  bool get hasArrivalWindow =>
      earliestArrivalTime != null && latestArrivalTime != null && latestArrivalTime! > earliestArrivalTime!;
}
