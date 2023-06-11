import 'dart:async';

class MultiTapDetector {
  int lastTap = DateTime.now().millisecondsSinceEpoch;
  int consecutiveTaps = 0;
  Timer tapTimer;
  int maxTaps;

  MultiTapDetector({this.maxTaps = 3});

  void onTap(Function(int) onTapCallback) {
    int now = DateTime.now().millisecondsSinceEpoch;
    if (now - lastTap < 450) {
      consecutiveTaps++;
      tapTimer?.cancel(); // Cancel the previous timer if it exists
      if (consecutiveTaps >= maxTaps) {
        onTapCallback(maxTaps);
        consecutiveTaps = 0;
      } else {
        tapTimer = Timer(Duration(milliseconds: 450), () {
          onTapCallback(consecutiveTaps);
          consecutiveTaps = 0; // Reset the counter
        });
      }
    } else {
      consecutiveTaps = 1;
      tapTimer = Timer(Duration(milliseconds: 300), () {
        if (consecutiveTaps == 1) {
          onTapCallback(1);
        }
        consecutiveTaps = 0; // Reset the counter
      });
    }
    lastTap = now;
  }
}
