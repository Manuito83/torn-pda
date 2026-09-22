import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/utils/ffscouter_note_text.dart';

/// FFScouter only takes one line of printable ASCII, up to 400 characters

void main() {
  group('toFFScouterNoteText', () {
    test('keeps plain ASCII', () {
      expect(toFFScouterNoteText('Hits hard, 2.3b total'), 'Hits hard, 2.3b total');
    });

    test('turns keyboard punctuation into ASCII', () {
      expect(toFFScouterNoteText('Don’t “hit” – ever…'), 'Don\'t "hit" - ever...');
    });

    test('removes accents', () {
      expect(toFFScouterNoteText('Añadir según ßtraße Łódź'), 'Anadir segun sstrasse Lodz');
    });

    test('joins lines and drops empty ones', () {
      expect(toFFScouterNoteText('first line\n\n  second line  \r\nthird'), 'first line / second line / third');
    });

    test('drops what has no ASCII version', () {
      expect(toFFScouterNoteText('ok 👍 Привет'), 'ok');
    });

    test('result is accepted by FFScouter', () {
      final text = toFFScouterNoteText('Watch — he’s “online” at 20:00 😀');
      expect(isValidFFScouterNoteText(text), isTrue);
    });
  });

  test('isValidFFScouterNoteText', () {
    expect(isValidFFScouterNoteText(''), isFalse);
    expect(isValidFFScouterNoteText('a' * 400), isTrue);
    expect(isValidFFScouterNoteText('a' * 401), isFalse);
    expect(isValidFFScouterNoteText('two\nlines'), isFalse);
    expect(isValidFFScouterNoteText('café'), isFalse);
  });

  group('FFScouterNoteInputFormatter', () {
    final formatter = FFScouterNoteInputFormatter();

    test('converts while typing and keeps the cursor after the change', () {
      const old = TextEditingValue(text: 'don', selection: TextSelection.collapsed(offset: 3));
      const typed = TextEditingValue(text: 'don’t', selection: TextSelection.collapsed(offset: 4));
      final result = formatter.formatEditUpdate(old, typed);
      expect(result.text, "don't");
      expect(result.selection.baseOffset, 4);
    });

    test('keeps trailing spaces while typing', () {
      const typed = TextEditingValue(text: 'hello ', selection: TextSelection.collapsed(offset: 6));
      expect(formatter.formatEditUpdate(TextEditingValue.empty, typed).text, 'hello ');
    });

    test('leaves text being composed alone', () {
      const typed = TextEditingValue(
        text: 'e´',
        selection: TextSelection.collapsed(offset: 2),
        composing: TextRange(start: 1, end: 2),
      );
      expect(formatter.formatEditUpdate(TextEditingValue.empty, typed).text, 'e´');
    });
  });
}
