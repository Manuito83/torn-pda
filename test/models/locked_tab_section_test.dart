import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/webview/locked_tab_section.dart';

void main() {
  test("paging inside the same section is allowed", () {
    expect(
      isSameLockedSection(
        "https://www.torn.com/forums.php#/p=threads&f=63&t=16146310&b=0&a=0",
        "https://www.torn.com/forums.php#/p=threads&f=63&t=16146310&b=0&a=0&start=20&to=24014610",
      ),
      isTrue,
    );
    expect(
      isSameLockedSection(
        "https://www.torn.com/bounties.php#!p=main",
        "https://www.torn.com/bounties.php#/!p=main&start=20",
      ),
      isTrue,
    );
    expect(
      isSameLockedSection(
        "https://www.torn.com/page.php?sid=attackLog&ID=4c7a8019368cc44ab6e1008adc7e9a19",
        "https://www.torn.com/page.php?sid=attackLog&ID=10dae7389b171c99f33be62475194101",
      ),
      isTrue,
    );
    expect(isSameLockedSection("https://www.torn.com/bounties.php", "https://torn.com/bounties.php#!p=main"), isTrue);
  });

  test("home is another section", () {
    expect(isSameLockedSection("https://www.torn.com/item.php", "https://www.torn.com/"), isFalse);
    expect(isSameLockedSection("https://www.torn.com/gym.php", "https://www.torn.com"), isFalse);
    expect(isSameLockedSection("https://www.torn.com/index.php", "https://www.torn.com/"), isTrue);
  });

  test("another page or page.php sid is another section", () {
    expect(isSameLockedSection("https://www.torn.com/gym.php", "https://www.torn.com/item.php"), isFalse);
    expect(
      isSameLockedSection("https://www.torn.com/page.php?sid=crimes", "https://www.torn.com/page.php?sid=stocks"),
      isFalse,
    );
    expect(
      isSameLockedSection("https://www.torn.com/page.php?sid=log", "https://www.torn.com/page.php?sid=attackLog&ID=1"),
      isFalse,
    );
  });
}
