import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/utils/discreet_schedule.dart';

void main() {
  DateTime at(int hour, [int minute = 0]) => DateTime(2026, 1, 1, hour, minute);

  group('same day window', () {
    const schedule = DiscreetSchedule(enabled: true, from: 9 * 60, to: 17 * 60);

    test('inside and outside', () {
      expect(schedule.contains(at(12)), isTrue);
      expect(schedule.contains(at(8, 59)), isFalse);
      expect(schedule.contains(at(17, 1)), isFalse);
    });

    test('start is included and end is not', () {
      expect(schedule.contains(at(9)), isTrue);
      expect(schedule.contains(at(16, 59)), isTrue);
      expect(schedule.contains(at(17)), isFalse);
    });
  });

  group('window across midnight', () {
    const schedule = DiscreetSchedule(enabled: true, from: 23 * 60, to: 7 * 60);

    test('both sides of midnight are inside', () {
      expect(schedule.contains(at(23, 30)), isTrue);
      expect(schedule.contains(at(0)), isTrue);
      expect(schedule.contains(at(3, 15)), isTrue);
    });

    test('daytime is outside', () {
      expect(schedule.contains(at(7)), isFalse);
      expect(schedule.contains(at(12)), isFalse);
      expect(schedule.contains(at(22, 59)), isFalse);
    });

    test('edges', () {
      expect(schedule.contains(at(23)), isTrue);
      expect(schedule.contains(at(6, 59)), isTrue);
    });
  });

  test('a disabled schedule never applies', () {
    const schedule = DiscreetSchedule(from: 0, to: 23 * 60 + 59);
    expect(schedule.contains(at(12)), isFalse);
  });

  test('equal ends make an empty window', () {
    const schedule = DiscreetSchedule(enabled: true, from: 8 * 60, to: 8 * 60);
    expect(schedule.contains(at(8)), isFalse);
    expect(schedule.contains(at(20)), isFalse);
  });

  group('combined with the general option', () {
    const schedule = DiscreetSchedule(enabled: true, from: 23 * 60, to: 7 * 60);

    test('option wins', () {
      expect(isDiscreetAt(always: true, schedule: schedule, time: at(12)), isTrue);
    });

    test('window applies', () {
      expect(isDiscreetAt(always: false, schedule: schedule, time: at(1)), isTrue);
      expect(isDiscreetAt(always: false, schedule: schedule, time: at(12)), isFalse);
    });
  });

  group('server upload', () {
    const schedule = DiscreetSchedule(enabled: true, from: 23 * 60, to: 7 * 60);
    const off = DiscreetSchedule(from: 23 * 60, to: 7 * 60);

    test('map', () {
      expect(schedule.toFirestore(-300), {'enabled': true, 'from': 1380, 'to': 420, 'offset': -300});
    });

    test('offset moved', () {
      expect(discreetScheduleNeedsSync(schedule, offset: 60, uploadedOffset: 60, pending: false), isFalse);
      expect(discreetScheduleNeedsSync(schedule, offset: 120, uploadedOffset: 60, pending: false), isTrue);
    });

    test('no offset uploaded', () {
      expect(discreetScheduleNeedsSync(schedule, offset: 0, uploadedOffset: null, pending: false), isTrue);
    });

    test('off and nothing pending', () {
      expect(discreetScheduleNeedsSync(off, offset: 120, uploadedOffset: 60, pending: false), isFalse);
      expect(discreetScheduleNeedsSync(off, offset: 0, uploadedOffset: null, pending: false), isFalse);
    });

    test('failed turning off retries', () {
      expect(discreetScheduleNeedsSync(off, offset: 60, uploadedOffset: 60, pending: true), isTrue);
    });
  });
}
