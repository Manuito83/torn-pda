import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/providers/flights_sharing.dart';
import 'package:torn_pda/utils/shared_prefs.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('flights_sharing_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => tempDir.path,
    );
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    tempDir.deleteSync(recursive: true);
  });

  setUp(() => Prefs().setTerritoryMapShareStopPending(false));

  Future<Object?> offline(bool share) async => throw const SocketException('no network');

  test('a failed stop is retried until it goes through', () async {
    await stopSharingFlights(call: offline);
    expect(await Prefs().getTerritoryMapShareStopPending(), isTrue);

    await retryStopSharingFlights(call: offline);
    expect(await Prefs().getTerritoryMapShareStopPending(), isTrue);

    final asked = <bool>[];
    await retryStopSharingFlights(
      call: (share) async {
        asked.add(share);
        return {'status': 'ok', 'share': share};
      },
    );
    expect(asked, [false]);
    expect(await Prefs().getTerritoryMapShareStopPending(), isFalse);
  });

  test('reading fails on anything but true, false or no login', () async {
    expect(await readFlightSharing(call: () async => {'share': true}), isTrue);
    expect(await readFlightSharing(call: () async => {'share': false}), isFalse);
    expect(await readFlightSharing(call: () async => {'status': 'no_login'}), isNull);
    await expectLater(readFlightSharing(call: () async => {'status': 'no_player'}), throwsFormatException);
    await expectLater(readFlightSharing(call: () async => 'nope'), throwsFormatException);
    await expectLater(readFlightSharing(call: () async => throw const SocketException('x')), throwsException);
  });

  test('a stop the server leaves pending is retried until it finishes', () async {
    Future<Object?> needsLogin(bool share) async => {'status': 'pending'};

    expect(await writeFlightSharing(false, call: needsLogin), isTrue);
    expect(await Prefs().getTerritoryMapShareStopPending(), isTrue);

    await stopSharingFlights(call: needsLogin);
    await retryStopSharingFlights(call: needsLogin);
    expect(await Prefs().getTerritoryMapShareStopPending(), isTrue);

    await retryStopSharingFlights(call: (share) async => {'status': 'ok', 'share': share});
    expect(await Prefs().getTerritoryMapShareStopPending(), isFalse);
  });

  test('no retry call when nothing is pending', () async {
    var calls = 0;
    await retryStopSharingFlights(
      call: (share) async {
        calls++;
        return {'status': 'ok'};
      },
    );
    expect(calls, 0);
  });

  test('a player with no document has nothing left to stop', () async {
    await stopSharingFlights(call: (share) async => {'status': 'no_player'});
    expect(await Prefs().getTerritoryMapShareStopPending(), isFalse);
  });

  test('only a saved turn on clears a pending stop', () async {
    await stopSharingFlights(call: offline);

    expect(await writeFlightSharing(true, call: (share) async => {'status': 'not_owner'}), isFalse);
    expect(await Prefs().getTerritoryMapShareStopPending(), isTrue);

    expect(await writeFlightSharing(true, call: (share) async => {'status': 'ok', 'share': true}), isTrue);
    expect(await Prefs().getTerritoryMapShareStopPending(), isFalse);
  });
}
