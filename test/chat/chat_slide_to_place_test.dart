import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/chat_slide_to_place.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

Widget _list(List<String> ids, {bool still = false, double header = 0}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: still),
    child: ListView(
      children: [
        SizedBox(height: header),
        for (var i = 0; i < ids.length; i++)
          ChatSlideToPlace(
            key: ValueKey(ids[i]),
            index: i,
            child: SizedBox(key: Key('row-${ids[i]}'), height: 100, child: Text(ids[i])),
          ),
      ],
    ),
  ),
);

double _top(WidgetTester tester, String id) => tester.getTopLeft(find.byKey(Key('row-$id'))).dy;

void main() {
  testWidgets('a moved row slides to its slot', (tester) async {
    await tester.pumpWidget(_list(['a', 'b', 'c']));
    final start = _top(tester, 'c');
    await tester.pumpWidget(_list(['c', 'a', 'b']));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final mid = _top(tester, 'c');
    expect(mid, greaterThan(_top(tester, 'a') - 200));
    expect(mid, lessThan(start));
    await tester.pump(const Duration(seconds: 1));
    expect(_top(tester, 'c'), lessThan(mid));
    expect(_top(tester, 'c'), _top(tester, 'a') - 100);
  });

  testWidgets('rows that stay put do not move', (tester) async {
    await tester.pumpWidget(_list(['a', 'b']));
    final before = _top(tester, 'b');
    await tester.pumpWidget(_list(['a', 'b']));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_top(tester, 'b'), before);
  });

  testWidgets('a taller header does not slide the rows', (tester) async {
    await tester.pumpWidget(_list(['a', 'b']));
    await tester.pumpWidget(_list(['a', 'b'], header: 80));
    await tester.pump();
    await tester.pumpWidget(_list(['a', 'b'], header: 80));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_top(tester, 'b'), _top(tester, 'a') + 100);
  });

  testWidgets('reduced motion jumps straight to the slot', (tester) async {
    await tester.pumpWidget(_list(['a', 'b', 'c'], still: true));
    await tester.pumpWidget(_list(['c', 'a', 'b'], still: true));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(_top(tester, 'c'), _top(tester, 'a') - 100);
  });

  testWidgets('the chosen option sets how long the slide lasts', (tester) async {
    addTearDown(() => NativeChat.prefs.animations = ChatAnimations.verySmooth);
    final settled = <ChatAnimations, bool>{};
    for (final option in [ChatAnimations.quick, ChatAnimations.verySmooth]) {
      NativeChat.prefs.animations = option;
      await tester.pumpWidget(_list(['a', 'b', 'c']));
      await tester.pumpWidget(_list(['c', 'a', 'b']));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      settled[option] = _top(tester, 'c') == _top(tester, 'a') - 100;
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpWidget(const SizedBox());
    }
    expect(settled, {ChatAnimations.quick: true, ChatAnimations.verySmooth: false});
  });
}
