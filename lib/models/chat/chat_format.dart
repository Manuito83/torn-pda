import 'dart:math';

import 'package:flutter/services.dart';
import 'package:torn_pda/models/chat/chat_links.dart';

/// Torn's chat markdown: no code, no headings
class ChatFormat {
  ChatFormat._();

  static const int bold = 1;
  static const int italic = 2;
  static const int strike = 4;
  static const int underline = 8;

  static final RegExp _marker = RegExp(r'\*|~~|__');

  // Matches Torn's web chat, same order
  static final List<(RegExp, int, int)> _rules = [
    (RegExp(r'\*\*([^*\n][\s\S]*?[^*\n]|[^*\n])\*\*'), bold, 2),
    (RegExp(r'~~([^~\n][\s\S]*?[^~\n]|[^~\n])~~'), strike, 2),
    (RegExp(r'(^|[^*])\*([^*\n][\s\S]*?[^*\n]|[^*\n])\*(?!\*)'), italic, 1),
    (RegExp(r'__([^_\s]|[^_\s](?:[^_]|_(?!_))*?[^_\s])__'), underline, 2),
  ];

  static bool hasMarkers(String text) => _marker.hasMatch(text);

  /// Style per code unit, plus marker flags
  static (List<int>, List<bool>) scan(String text) {
    final styles = List<int>.filled(text.length, 0);
    final markers = List<bool>.filled(text.length, false);
    if (!hasMarkers(text)) return (styles, markers);
    final links = ChatLink.ranges(text);
    bool inLink(int i) => links.any((r) => i >= r.$1 && i < r.$2);
    var work = text;
    for (final (pattern, style, size) in _rules) {
      for (final m in pattern.allMatches(work)) {
        final open = m.start + (m.groupCount > 1 ? m.group(1)!.length : 0);
        final close = m.end - size;
        final at = [
          for (var i = 0; i < size; i++) ...[open + i, close + i],
        ];
        if (at.any(inLink)) continue;
        for (final i in at) {
          markers[i] = true;
        }
        for (var i = open + size; i < close; i++) {
          styles[i] |= style;
        }
      }
      // Used markers stop matching later rules
      work = String.fromCharCodes([for (var i = 0; i < text.length; i++) markers[i] ? 1 : text.codeUnitAt(i)]);
    }
    return (styles, markers);
  }

  /// Text without markers, split by style
  static List<(String, int)> runs(String text) {
    final (styles, markers) = scan(text);
    final runs = <(String, int)>[];
    final buffer = StringBuffer();
    var current = 0;
    for (var i = 0; i < text.length; i++) {
      if (markers[i]) continue;
      if (styles[i] != current && buffer.isNotEmpty) {
        runs.add((buffer.toString(), current));
        buffer.clear();
      }
      current = styles[i];
      buffer.writeCharCode(text.codeUnitAt(i));
    }
    if (buffer.isNotEmpty || runs.isEmpty) runs.add((buffer.toString(), current));
    return runs;
  }

  static String plain(String text) => hasMarkers(text) ? runs(text).map((r) => r.$1).join() : text;

  static (int, int) _trimmed(TextEditingValue value) {
    final text = value.text;
    final selection = value.selection;
    var start = selection.isValid ? selection.start : text.length;
    var end = selection.isValid ? selection.end : text.length;
    while (start < end && text[start].trim().isEmpty) {
      start++;
    }
    while (end > start && text[end - 1].trim().isEmpty) {
      end--;
    }
    return (start, end);
  }

  /// Unwraps when already marked
  static TextEditingValue wrap(TextEditingValue value, String marker, String placeholder) {
    final text = value.text;
    final size = marker.length;
    final (start, end) = _trimmed(value);
    if (start == end) {
      return TextEditingValue(
        text: text.replaceRange(start, start, '$marker$placeholder$marker'),
        selection: TextSelection(baseOffset: start + size, extentOffset: start + size + placeholder.length),
      );
    }

    final char = marker[0];
    int count(int from, int step, int limit) {
      var n = 0;
      for (var i = from; i >= 0 && i < text.length && i != limit && text[i] == char; i += step) {
        n++;
      }
      return n;
    }

    bool marked(int n) => size == 1 ? n.isOdd : n >= 2;
    final outside = min(count(start - 1, -1, -1), count(end, 1, -1));
    if (marked(outside)) {
      return TextEditingValue(
        text: text.replaceRange(end, end + size, '').replaceRange(start - size, start, ''),
        selection: TextSelection(baseOffset: start - size, extentOffset: end - size),
      );
    }
    final inside = min(count(start, 1, end), count(end - 1, -1, start - 1));
    if (end - start > 2 * size && marked(inside)) {
      return TextEditingValue(
        text: text.replaceRange(end - size, end, '').replaceRange(start, start + size, ''),
        selection: TextSelection(baseOffset: start, extentOffset: end - 2 * size),
      );
    }
    return TextEditingValue(
      text: text.replaceRange(end, end, marker).replaceRange(start, start, marker),
      selection: TextSelection(baseOffset: start + size, extentOffset: end + size),
    );
  }

  static TextEditingValue link(TextEditingValue value) {
    final text = value.text;
    var (start, end) = _trimmed(value);
    var selected = text.substring(start, end);
    if (selected.contains('\n')) {
      start = end;
      selected = '';
    }
    final isUrl = RegExp(r'^(https?://|www\.)\S+$', caseSensitive: false).hasMatch(selected);
    final insert = isUrl ? '[text]($selected)' : '[${selected.isEmpty ? 'text' : selected}](https://)';
    return TextEditingValue(
      text: text.replaceRange(start, end, insert),
      selection: selected.isEmpty || isUrl
          ? TextSelection(baseOffset: start + 1, extentOffset: start + 5)
          : TextSelection.collapsed(offset: start + insert.length - 1),
    );
  }
}
