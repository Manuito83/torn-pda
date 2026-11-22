import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/territory_map/map_sheet.dart';

void main() {
  late int closed;

  Future<void> pumpSheet(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    closed = 0;
    await tester.binding.setSurfaceSize(const Size(400, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ChangeNotifierProvider<ThemeProvider>(
        create: (_) => ThemeProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: Stack(
              fit: StackFit.expand,
              children: [
                MapSheet(
                  title: const Text('Title'),
                  onClose: () => closed++,
                  children: [for (var i = 0; i < 30; i++) Text('row $i')],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('closes when dragged to the bottom', (tester) async {
    await pumpSheet(tester);
    await tester.drag(find.text('Title'), const Offset(0, 800));
    await tester.pumpAndSettle();
    expect(closed, 1);
  });

  testWidgets('resizes on a small drag', (tester) async {
    await pumpSheet(tester);
    final before = tester.getTopLeft(find.text('Title')).dy;
    await tester.drag(find.text('Title'), const Offset(0, 120));
    await tester.pumpAndSettle();
    expect(closed, 0);
    expect(tester.getTopLeft(find.text('Title')).dy, greaterThan(before));
  });
}
