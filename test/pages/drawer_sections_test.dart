import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/drawer_section.dart';

void main() {
  test('chat lands above Profile in an older saved order', () {
    final saved = ['travel', 'chaining', 'profile', 'loot', 'gone'];
    final order = drawerFullOrder(saved);
    expect(order.take(5), ['travel', 'chaining', 'chat', 'profile', 'loot']);
    expect(order.toSet(), {'chat', ...DrawerSection.values.map((s) => s.name)});
    expect(order, hasLength(DrawerSection.values.length + 1));

    expect(drawerFullOrder(const []).take(2), ['chat', 'profile']);
    final moved = ['profile', 'travel', 'chat'];
    expect(drawerFullOrder(moved).take(3), moved);
  });

  test('feedback lands above About and nothing else moves', () {
    final saved = ['chat', 'travel', 'profile', 'settings', 'about', 'tips', 'divider2'];
    final order = drawerFullOrder(saved);
    expect(order.indexOf('feedback'), order.indexOf('about') - 1);
    expect(order.where((id) => id != 'feedback').take(saved.length), saved);

    final custom = ['about', 'settings', 'profile'];
    expect(drawerFullOrder(custom).take(5), ['feedback', 'about', 'settings', 'chat', 'profile']);

    final placed = ['feedback', 'chat', 'profile', 'about'];
    expect(drawerFullOrder(placed).take(4), placed);
  });
}
