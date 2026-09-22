import 'package:diacritic/diacritic.dart';
import 'package:flutter/services.dart';

const int kFFScouterNoteMaxLength = 400;

// Keyboard punctuation has no accent to strip, and diacritic turns ß into a single s
const Map<String, String> _punctuation = {"‘’‚‛′‹›": "'", "“”„‟″«»": '"', "‐‑‒–—―−•·": "-", "…": "...", "ß": "ss"};

final RegExp _punctuationPattern = RegExp('[${_punctuation.keys.join()}]');

String _mapToAscii(String input) {
  final replaced = input.replaceAllMapped(
    _punctuationPattern,
    (m) => _punctuation.entries.firstWhere((e) => e.key.contains(m[0]!)).value,
  );
  return removeDiacritics(replaced).replaceAll(RegExp(r'\s'), ' ').replaceAll(RegExp(r'[^\x20-\x7E]'), '');
}

/// Single line of printable ASCII as FFScouter requires, lines joined with " / "
String toFFScouterNoteText(String input) {
  return input
      .split(RegExp(r'[\r\n]+'))
      .map((line) => _mapToAscii(line).replaceAll(RegExp(r' {2,}'), ' ').trim())
      .where((line) => line.isNotEmpty)
      .join(' / ');
}

bool isValidFFScouterNoteText(String text) =>
    text.isNotEmpty && text.length <= kFFScouterNoteMaxLength && RegExp(r'^[\x20-\x7E]+$').hasMatch(text);

class FFScouterNoteInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.composing.isValid && !newValue.composing.isCollapsed) return newValue;
    final cursor = newValue.selection.end.clamp(0, newValue.text.length);
    final before = _mapToAscii(newValue.text.substring(0, cursor));
    final after = _mapToAscii(newValue.text.substring(cursor));
    final text = before + after;
    if (text == newValue.text) return newValue;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: before.length),
    );
  }
}
