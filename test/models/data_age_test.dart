import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/data_age.dart';

void main() {
  test('data age reads like the chat times', () {
    final now = DateTime.utc(2026, 11, 10, 12);
    int ago(Duration d) => now.subtract(d).millisecondsSinceEpoch ~/ 1000;
    expect(dataAgeText(ago(const Duration(seconds: 59)), now: now), isNull);
    expect(dataAgeText(ago(const Duration(minutes: 73)), now: now), '1h 13m ago');
    expect(dataAgeText(ago(const Duration(hours: 5)), now: now), '5h ago');
    expect(dataAgeText(ago(const Duration(days: 3)), now: now), '3d ago');
    expect(dataAgeText(null, now: now), isNull);
    expect(dataAgeText(0, now: now), isNull);
  });
}
