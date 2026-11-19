const chatBrakeSteps = [
  Duration(minutes: 1),
  Duration(minutes: 5),
  Duration(minutes: 30),
  Duration(hours: 1),
  Duration(hours: 6),
  Duration(hours: 24),
];

const chatBrakeCap = Duration(days: 7);

/// Backoff for one source, immutable: keep the latest value
class ChatBrake {
  const ChatBrake({this.failures = 0, this.retryAt});

  /// Failures in a row, zero after a success
  final int failures;
  final DateTime? retryAt;

  /// Third failure in a row
  bool get persistent => failures == 3;

  bool blocks(DateTime now) => retryAt != null && now.isBefore(retryAt!);

  ChatBrake failed(DateTime now, {Duration? retryAfter}) {
    final count = failures + 1;
    var wait = count <= chatBrakeSteps.length ? chatBrakeSteps[count - 1] : chatBrakeCap;
    if (retryAfter != null && retryAfter > wait) wait = retryAfter;
    if (wait > chatBrakeCap) wait = chatBrakeCap;
    return ChatBrake(failures: count, retryAt: now.add(wait));
  }
}
