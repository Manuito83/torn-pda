import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/webview/blank_page.dart';

void main() {
  test("a page with little text is never blank", () {
    expect(blankPageDetected(text: 500, valid: 10, failed: 10), isFalse);
    expect(blankPageDetected(text: 501, valid: 10, failed: 10), isTrue);
  });

  test("fewer than four checked points is not enough", () {
    expect(blankPageDetected(text: 2000, valid: 3, failed: 3), isFalse);
    expect(blankPageDetected(text: 2000, valid: 4, failed: 2), isTrue);
  });

  test("under ten checked points, half of them must fail", () {
    expect(blankPageDetected(text: 2000, valid: 7, failed: 3), isFalse);
    expect(blankPageDetected(text: 2000, valid: 7, failed: 4), isTrue);
  });

  test("from ten checked points, five failures are enough", () {
    expect(blankPageDetected(text: 2000, valid: 10, failed: 4), isFalse);
    expect(blankPageDetected(text: 2000, valid: 10, failed: 5), isTrue);
    expect(blankPageDetected(text: 2000, valid: 14, failed: 5), isTrue);
  });
}
