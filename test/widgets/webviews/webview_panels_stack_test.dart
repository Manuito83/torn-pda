import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/widgets/webviews/webview_panels_stack.dart';

int _created = 0;
int _disposed = 0;

class _FakeTab extends StatefulWidget {
  const _FakeTab({super.key});

  @override
  State<_FakeTab> createState() => _FakeTabState();
}

class _FakeTabState extends State<_FakeTab> {
  @override
  void initState() {
    super.initState();
    _created++;
  }

  @override
  void dispose() {
    _disposed++;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const ColoredBox(color: Colors.white, child: SizedBox.expand());
}

void main() {
  final keys = List.generate(3, (i) => ValueKey("tab$i"));

  Element tabElement(int index) => find.byKey(keys[index], skipOffstage: false).evaluate().single;

  Element parentOf(int index) {
    late Element parent;
    tabElement(index).visitAncestorElements((element) {
      parent = element;
      return false;
    });
    return parent;
  }

  List<Object> identities() => [
    for (var i = 0; i < keys.length; i++) ...[tabElement(i), (tabElement(i) as StatefulElement).state, parentOf(i)],
  ];

  Future<void> pumpPanels(WidgetTester tester, List<int?> panelTabs, List<int> childPanels) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 800,
          height: 600,
          child: WebViewPanelsStack(
            panelTabs: panelTabs,
            childPanels: childPanels,
            focusedPanel: 0,
            emptyPanel: const ColoredBox(key: ValueKey("blank"), color: Colors.grey),
            duration: 100,
            errorCallback: () => fail("errorCallback called"),
            children: [for (final key in keys) _FakeTab(key: key)],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  bool isShown(int index) => find.byKey(keys[index]).hitTestable().evaluate().isNotEmpty;

  testWidgets("tabs keep their State through every panel layout", (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    _created = 0;
    _disposed = 0;

    await pumpPanels(tester, [0], [0, 0, 0]);
    final before = identities();
    expect(_created, 3);
    expect([isShown(0), isShown(1), isShown(2)], [true, false, false]);
    expect(tester.getSize(find.byKey(keys[0])).width, 800);

    await pumpPanels(tester, [0, 2], [0, 0, 1]);
    expect([isShown(0), isShown(1), isShown(2)], [true, false, true]);
    expect(tester.getTopLeft(find.byKey(keys[2])).dx, 400);
    expect(tester.getSize(find.byKey(keys[2])).width, 400);
    expect(MediaQuery.sizeOf(tabElement(2)).width, 400);

    await pumpPanels(tester, [2, 0], [1, 1, 0]);
    expect(tester.getTopLeft(find.byKey(keys[0])).dx, 400);
    expect(tester.getTopLeft(find.byKey(keys[2])).dx, 0);

    await pumpPanels(tester, [1, null], [0, 0, 0]);
    expect([isShown(0), isShown(1), isShown(2)], [false, true, false]);
    expect(tester.getTopLeft(find.byKey(const ValueKey("blank"))).dx, 400);

    await pumpPanels(tester, [2], [0, 0, 0]);
    expect([isShown(0), isShown(1), isShown(2)], [false, false, true]);
    expect(tester.getSize(find.byKey(keys[2])).width, 800);
    expect(find.byKey(const ValueKey("blank")), findsNothing);

    final after = identities();
    for (var i = 0; i < before.length; i++) {
      expect(identical(after[i], before[i]), isTrue, reason: "identity $i changed");
    }
    expect(_created, 3);
    expect(_disposed, 0);
  });

  testWidgets("a pointer down reports the tab of the touched panel", (tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final touched = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: WebViewPanelsStack(
          panelTabs: const [0, 2],
          childPanels: const [0, 0, 1],
          duration: 100,
          errorCallback: () => fail("errorCallback called"),
          onTabPointerDown: touched.add,
          children: [for (final key in keys) _FakeTab(key: key)],
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tapAt(const Offset(600, 300));
    await tester.tapAt(const Offset(200, 300));
    expect(touched, [2, 0]);
  });
}
