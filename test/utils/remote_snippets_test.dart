import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/utils/js_snippets/js_quick_items.dart';
import 'package:torn_pda/utils/js_snippets/remote_snippets.dart';

void main() {
  test('every base snippet can be pasted into RC', () {
    for (final id in RemoteSnippets.ids) {
      final js = RemoteSnippets.resolve(id);
      expect(js, isNotEmpty, reason: id);
      expect(js.contains('\\'), isFalse, reason: id);
      expect(js.contains('`'), isFalse, reason: id);
    }
  });

  test('newer RC override replaces the quick item base', () {
    const id = RemoteSnippets.quickItemsRun;
    addTearDown(() => RemoteSnippets.setOverride(id, '', ''));

    RemoteSnippets.setOverride(id, '1.0.1', 'console.log("rc");');
    final js = runQuickItemJS(item: '206', itemName: 'Xanax', faction: true);
    expect(js, startsWith('window.__pdaQuickItemsRunArgs = {"item":"206","itemName":"Xanax","faction":true,'));
    expect(js, endsWith('console.log("rc");'));
  });
}
