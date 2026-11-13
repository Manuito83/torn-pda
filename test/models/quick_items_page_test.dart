import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/quick_items_page.dart';

void main() {
  test('personal quick items only in item.php', () {
    expect(isPersonalQuickItemsPage('https://www.torn.com/item.php'), isTrue);
    expect(isPersonalQuickItemsPage('https://www.torn.com/factions.php?step=your#/tab=armoury'), isFalse);
  });

  test('faction quick items only in the armoury', () {
    expect(isFactionQuickItemsPage('https://www.torn.com/factions.php?step=your#/tab=armoury'), isTrue);
    expect(isFactionQuickItemsPage('https://www.torn.com/factions.php?step=your#/tab=crimes'), isFalse);
    expect(isFactionQuickItemsPage('https://www.torn.com/item.php'), isFalse);
  });
}
