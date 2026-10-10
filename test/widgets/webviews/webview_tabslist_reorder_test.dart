import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/widgets/webviews/webview_tabslist.dart';

void main() {
  // Global list: 0 M, 1 M, 2 A, 3 A, 4 M, 5 A, 6 M
  const List<int> mainTabs = [0, 1, 4, 6];
  const List<int> apartTabs = [2, 3, 5];

  group('splitGroupReorderIndexes', () {
    test('moves forward past hidden tabs of the other group', () {
      expect(splitGroupReorderIndexes(mainTabs, 1, 7, firstIsFixed: true), (1, 3));
      expect(splitGroupReorderIndexes(mainTabs, 1, 5, firstIsFixed: true), (1, 2));
    });

    test('moves backward past hidden tabs of the other group', () {
      expect(splitGroupReorderIndexes(mainTabs, 6, 2, firstIsFixed: true), (3, 2));
      expect(splitGroupReorderIndexes(apartTabs, 5, 2), (2, 0));
    });

    test('dropping on either side of a hidden tab gives the same result', () {
      expect(splitGroupReorderIndexes(mainTabs, 6, 2, firstIsFixed: true), (3, 2));
      expect(splitGroupReorderIndexes(mainTabs, 6, 3, firstIsFixed: true), (3, 2));
      expect(splitGroupReorderIndexes(mainTabs, 6, 4, firstIsFixed: true), (3, 2));
    });

    test('a drop that leaves the tab in its place does not move it', () {
      expect(splitGroupReorderIndexes(mainTabs, 4, 3, firstIsFixed: true), isNull);
      expect(splitGroupReorderIndexes(apartTabs, 3, 3), isNull);
      expect(splitGroupReorderIndexes(apartTabs, 3, 5), isNull);
    });

    test('the apart group can move a tab to its first place, even before global index 0', () {
      expect(splitGroupReorderIndexes(apartTabs, 3, 0), (1, 0));
      expect(splitGroupReorderIndexes(apartTabs, 5, 1), (2, 0));
    });

    test('the main tab stays first in the main group', () {
      expect(splitGroupReorderIndexes(mainTabs, 4, 0, firstIsFixed: true), isNull);
      expect(splitGroupReorderIndexes(mainTabs, 4, 1, firstIsFixed: true), (2, 1));
      expect(splitGroupReorderIndexes(mainTabs, 0, 5, firstIsFixed: true), isNull);
    });

    test('a tab of the other group is ignored', () {
      expect(splitGroupReorderIndexes(mainTabs, 3, 7, firstIsFixed: true), isNull);
      expect(splitGroupReorderIndexes(apartTabs, 4, 0), isNull);
    });
  });
}
