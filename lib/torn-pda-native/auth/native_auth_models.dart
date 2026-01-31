enum NativeLoginType {
  none,
  google,
  apple,
}

class GetInitDataModel {
  final int playerId;
  final String sToken;

  GetInitDataModel({required this.playerId, required this.sToken});
}

class TornLoginResponseContainer {
  final bool success;
  final String authUrl;
  final String message;
  final int httpStatus;
  final bool transientError;

  TornLoginResponseContainer({
    this.success = false,
    this.authUrl = "",
    this.message = "",
    this.httpStatus = 0,
    this.transientError = false,
  });
}
