import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/widgets/webviews/webview_url_dialog.dart';

void main() {
  test('clears the HTTP cache first and then reloads the tab', () async {
    final calls = <String>[];

    final done = await softCacheReset(
      clearHttpCache: () async => calls.add('clear'),
      reload: () async => calls.add('reload'),
      notify: (text, success) => calls.add('notify:$success'),
    );

    expect(done, isTrue);
    expect(calls, ['clear', 'notify:true', 'reload']);
  });

  test('a failed clear does not reload and reports the error', () async {
    final calls = <String>[];

    final done = await softCacheReset(
      clearHttpCache: () async => throw StateError('no webview'),
      reload: () async => calls.add('reload'),
      notify: (text, success) => calls.add('notify:$success'),
    );

    expect(done, isFalse);
    expect(calls, ['notify:false']);
  });
}
