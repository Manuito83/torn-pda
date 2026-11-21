const int scriptPreviewThreshold = 100 * 1024;
const int _previewMaxLines = 40;
const int _previewMaxChars = 4000;

({String text, String? notice}) previewScriptSource(String source) {
  if (source.length <= scriptPreviewThreshold) return (text: source, notice: null);

  var end = 0;
  for (var i = 0; i < _previewMaxLines; i++) {
    final next = source.indexOf('\n', end);
    if (next == -1 || next >= _previewMaxChars) break;
    end = next + 1;
  }
  if (end == 0) {
    end = _previewMaxChars;
    final last = source.codeUnitAt(end - 1);
    if (last >= 0xD800 && last <= 0xDBFF) end--;
  }

  final kb = (source.length / 1024).round();
  return (text: source.substring(0, end), notice: "$kb KB, rest not shown");
}

String previewScriptSourceWithNotice(String source) {
  final preview = previewScriptSource(source);
  return preview.notice == null ? preview.text : "${preview.notice}\n\n${preview.text}";
}
