import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/cityshops/city_shop_daily_limit.dart';

void main() {
  test('the TCT day turns at midnight UTC', () {
    expect(tctDay(DateTime.utc(2026, 3, 5, 23, 59)), '2026-03-05');
    expect(nextTctMidnightMs(DateTime.utc(2026, 12, 31, 18)), DateTime.utc(2027).millisecondsSinceEpoch);
  });

  test('purchases add up to the limit', () {
    expect(cityShopPurchaseResult({'success': true, 'amount': '4'}, 10), (count: 14, reached: false));
    expect(cityShopPurchaseResult({'success': true, 'amount': 6}, 94), (count: 100, reached: true));
    expect(cityShopPurchaseResult({'success': false, 'amount': 6}, 99), (count: 99, reached: false));
  });

  test('Torn saying no more today reaches the limit', () {
    final response = {'success': false, 'text': 'You can only buy a maximum of 100 items today'};
    expect(cityShopPurchaseResult(response, 3), (count: 3, reached: true));
  });
}
