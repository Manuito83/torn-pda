import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/utils/http_overrides.dart';

class _FakeCertificate implements X509Certificate {
  _FakeCertificate({required this.startValidity, required this.endValidity});

  @override
  final DateTime startValidity;
  @override
  final DateTime endValidity;
  @override
  String get issuer => "CN=Proxy CA";
  @override
  String get subject => "CN=api.torn.com";
  @override
  Uint8List get der => Uint8List(0);
  @override
  String get pem => "";
  @override
  Uint8List get sha1 => Uint8List(0);
}

void main() {
  final now = DateTime.now();
  final valid = _FakeCertificate(
    startValidity: now.subtract(const Duration(days: 30)),
    endValidity: now.add(const Duration(days: 30)),
  );

  test('rejects and reports each host once per session', () {
    final reports = <String>[];
    final overrides = MyHttpOverrides(onRejected: (host, issuer, problem) => reports.add("$host|$issuer|$problem"));

    expect(overrides.onBadCertificate(valid, "api.torn.com", 443), isFalse);
    expect(overrides.onBadCertificate(valid, "api.torn.com", 443), isFalse);
    expect(overrides.onBadCertificate(valid, "yata.yt", 443), isFalse);

    expect(reports, ["api.torn.com|CN=Proxy CA|untrusted", "yata.yt|CN=Proxy CA|untrusted"]);
  });

  test('accepts but still reports when strict mode is off', () {
    final reports = <String>[];
    final overrides = MyHttpOverrides(onRejected: (host, _, _) => reports.add(host))..strictMode = false;

    expect(overrides.onBadCertificate(valid, "api.torn.com", 443), isTrue);
    overrides.strictMode = true;
    expect(overrides.onBadCertificate(valid, "yata.yt", 443), isFalse);

    expect(reports, ["api.torn.com", "yata.yt"]);
  });

  test('reports expired and not_yet_valid', () {
    final problems = <String>[];
    final overrides = MyHttpOverrides(onRejected: (_, _, problem) => problems.add(problem));

    overrides.onBadCertificate(
      _FakeCertificate(
        startValidity: now.subtract(const Duration(days: 90)),
        endValidity: now.subtract(const Duration(days: 1)),
      ),
      "a.com",
      443,
    );
    overrides.onBadCertificate(
      _FakeCertificate(startValidity: now.add(const Duration(days: 1)), endValidity: now.add(const Duration(days: 90))),
      "b.com",
      443,
    );

    expect(problems, ["expired", "not_yet_valid"]);
  });
}
