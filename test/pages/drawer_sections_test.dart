import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/drawer_section.dart';
import 'package:torn_pda/pages/settings/drawer_sections_page.dart';

void main() {
  test('chat lands above Profile in an older saved order', () {
    final saved = ['travel', 'chaining', 'profile', 'loot', 'gone'];
    final order = DrawerSectionsPage.fullOrder(saved);
    expect(order.take(5), ['travel', 'chaining', 'chat', 'profile', 'loot']);
    expect(order.toSet(), {'chat', ...DrawerSection.values.map((s) => s.name)});
    expect(order, hasLength(DrawerSection.values.length + 1));

    expect(DrawerSectionsPage.fullOrder(const []).take(2), ['chat', 'profile']);
    final moved = ['profile', 'travel', 'chat'];
    expect(DrawerSectionsPage.fullOrder(moved).take(3), moved);
  });
}
