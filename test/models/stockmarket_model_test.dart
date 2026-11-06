import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/stockmarket/stockmarket_model.dart';

StockMarketStock _stock({int? requirement, int? sharesOwned}) {
  return StockMarketStock(
    acronym: "TST",
    benefit: requirement == null ? null : Benefit(requirement: requirement),
  )..sharesOwned = sharesOwned;
}

void main() {
  test("stocks that are not owned have no benefit block", () {
    expect(_stock(requirement: 1000000).hasBenefitBlock, isFalse);
  });

  test("owning fewer shares than the requirement is not a benefit block", () {
    expect(_stock(requirement: 1000000, sharesOwned: 999999).hasBenefitBlock, isFalse);
  });

  test("owning at least the required shares is a benefit block", () {
    expect(_stock(requirement: 1000000, sharesOwned: 1000000).hasBenefitBlock, isTrue);
    expect(_stock(requirement: 1000000, sharesOwned: 2500000).hasBenefitBlock, isTrue);
  });

  test("stocks without benefit information never have a benefit block", () {
    expect(_stock(sharesOwned: 5000000).hasBenefitBlock, isFalse);
    expect(_stock(requirement: 0, sharesOwned: 5000000).hasBenefitBlock, isFalse);
  });
}
