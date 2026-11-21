import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/userscripts/script_source_preview.dart';

void main() {
  group('previewScriptSource', () {
    test('keeps a small source untouched', () {
      final source = '// ==UserScript==\n// @name Small\n// ==/UserScript==\nrun();\n';
      final preview = previewScriptSource(source);
      expect(preview.text, source);
      expect(preview.notice, isNull);
    });

    test('keeps a source right at the threshold', () {
      final source = 'a' * scriptPreviewThreshold;
      expect(previewScriptSource(source).notice, isNull);
    });

    test('cuts a big source to the first lines with its size', () {
      final source = List.generate(30000, (i) => 'const v$i = $i;').join('\n');
      final preview = previewScriptSource(source);
      expect(preview.text.split('\n').length, lessThanOrEqualTo(41));
      expect(preview.text, startsWith('const v0 = 0;\nconst v1 = 1;'));
      expect(source.startsWith(preview.text), isTrue);
      expect(preview.notice, '${(source.length / 1024).round()} KB, rest not shown');
    });

    test('does not split a surrogate pair at the cut', () {
      final source = '${'x' * 3999}😀${'x' * scriptPreviewThreshold}';
      final preview = previewScriptSource(source);
      expect(preview.text.length, 3999);
    });

    test('cuts a minified single line by characters', () {
      final source = 'x' * (scriptPreviewThreshold + 1);
      final preview = previewScriptSource(source);
      expect(preview.text.length, lessThan(5000));
      expect(preview.text, isNotEmpty);
      expect(preview.notice, isNotNull);
    });
  });
}
