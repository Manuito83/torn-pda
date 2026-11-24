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

  test('feedback goes last unless the player placed it', () {
    expect(drawerFullOrder(const []).last, 'feedback');

    final saved = ['chat', 'travel', 'profile', 'settings', 'about', 'tips', 'divider2'];
    final order = drawerFullOrder(saved);
    expect(order.last, 'feedback');
    expect(order.take(saved.length), saved);

    final placed = ['feedback', 'chat', 'profile', 'about'];
    expect(drawerFullOrder(placed).take(4), placed);
  });

  test('a saved map start falls back to Profile only while the map is off', () {
    expect(startSection('territoryMap', territoryMapOff: false), DrawerSection.territoryMap);
    expect(startSection('territoryMap', territoryMapOff: true), DrawerSection.profile);
    expect(startSection('loot', territoryMapOff: true), DrawerSection.loot);
  });

  test('older and odd saved starts still resolve', () {
    expect(startSection('browser_full', territoryMapOff: false), DrawerSection.profile);
    expect(startSection('8', territoryMapOff: false), DrawerSection.rankedWars);
    expect(startSection('gone', territoryMapOff: false), DrawerSection.profile);
  });
}
