import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/widgets/chat/chat_edge_back.dart';

void main() {
  var backs = 0;
  var taps = 0;

  Future<void> show(WidgetTester tester, {EdgeInsets system = EdgeInsets.zero}) async {
    backs = 0;
    taps = 0;
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(context).copyWith(systemGestureInsets: system),
              child: ChatEdgeBack(
                onBack: () => backs++,
                child: ListView(
                  children: [
                    for (final name in const ['Alpha', 'Bravo', 'Charlie'])
                      Slidable(
                        key: ValueKey(name),
                        startActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [SlidableAction(onPressed: (_) {}, icon: Icons.push_pin, label: 'Pin $name')],
                        ),
                        endActionPane: ActionPane(
                          motion: const DrawerMotion(),
                          children: [
                            SlidableAction(onPressed: (_) {}, icon: Icons.notifications_off, label: 'Mute $name'),
                          ],
                        ),
                        child: ListTile(title: Text(name), onTap: () => taps++),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  double rowY(WidgetTester tester) => tester.getCenter(find.text('Bravo')).dy;

  Future<void> swipe(WidgetTester tester, double fromX, double dx) async {
    await tester.dragFrom(Offset(fromX, rowY(tester)), Offset(dx, 0));
    await tester.pumpAndSettle();
  }

  testWidgets('from the edge the page goes back and the row stays shut', (tester) async {
    await show(tester);
    await swipe(tester, 30, 150);
    expect(backs, 1);
    expect(find.text('Pin Bravo'), findsNothing);
  });

  testWidgets('from inside the row opens its actions', (tester) async {
    await show(tester);
    await swipe(tester, 200, 300);
    expect(backs, 0);
    expect(find.text('Pin Bravo'), findsOneWidget);
  });

  testWidgets('a short edge drag does nothing and an edge tap still opens the row', (tester) async {
    await show(tester);
    await swipe(tester, 30, 30);
    expect(backs, 0);
    expect(find.text('Pin Bravo'), findsNothing);

    await tester.tapAt(Offset(30, rowY(tester)));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('the band starts past the zone the system already takes', (tester) async {
    await show(tester, system: const EdgeInsets.only(left: 30));
    await swipe(tester, 10, 300);
    expect(backs, 0);
    expect(find.text('Pin Bravo'), findsOneWidget);

    await show(tester, system: const EdgeInsets.only(left: 30));
    await swipe(tester, 50, 300);
    expect(backs, 1);
    expect(find.text('Pin Bravo'), findsNothing);
  });

  testWidgets('the far edge is left to the row', (tester) async {
    await show(tester);
    await swipe(tester, tester.getSize(find.byType(ChatEdgeBack)).width - 30, -300);
    expect(backs, 0);
    expect(find.text('Mute Bravo'), findsOneWidget);
  });

  testWidgets('a cancelled drag closes nothing', (tester) async {
    await show(tester);
    final gesture = await tester.startGesture(Offset(30, rowY(tester)));
    await gesture.moveBy(const Offset(300, 0));
    await tester.pump();
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(backs, 0);
    expect(find.text('Pin Bravo'), findsNothing);
  });
}
