String apiPingMessage(List<int> times, int sent, Object? lastError) {
  String message = "Received ${times.length}/$sent";
  if (times.isNotEmpty) {
    final sorted = [...times]..sort();
    final average = sorted.reduce((a, b) => a + b) ~/ sorted.length;
    message += "\nTime: min ${sorted.first} ms, avg $average ms, max ${sorted.last} ms";
  }
  if (times.length == sent) return "SUCCESS\n\n$message";
  return "CONNECTION PROBLEM\n\n$message\n\n$lastError";
}
