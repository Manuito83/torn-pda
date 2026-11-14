import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/tabsave_model.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/sembast_db.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/webviews/webview_full.dart';

import 'chat_fakes.dart';

void main() {
  useTempPathProvider();

  test('chat hiding reaches every tab', () async {
    final web = WebViewProvider();
    await web.addTab(url: 'https://www.torn.com/index.php', tabUid: 'a');
    await web.addTab(url: 'https://www.torn.com/gym.php', tabUid: 'b', chatRemovalActive: true);
    await web.addTab(url: 'https://www.torn.com/city.php', tabUid: 'c', sleepTab: true);

    web.setChatHiddenEverywhere(true);
    expect(web.tabList.map((t) => t.chatRemovalActiveTab), everyElement(isTrue));
    expect(await Prefs().getChatRemovalActive(), isTrue);
    web.activateTab(2);
    expect((web.tabList[2].webView! as WebViewFull).chatRemovalActive, isTrue);
    await web.addTab(url: 'https://www.torn.com/item.php', tabUid: 'd');
    expect(web.tabList.last.chatRemovalActiveTab, isTrue);

    web.setChatHiddenEverywhere(false);
    expect(web.tabList.map((t) => t.chatRemovalActiveTab), everyElement(isFalse));
    expect(await Prefs().getChatRemovalActive(), isFalse);
    await web.addTab(url: 'https://www.torn.com/travel.php', tabUid: 'e');
    expect(web.tabList.last.chatRemovalActiveTab, isFalse);
  });

  test('chat removal migration runs once', () async {
    const saved =
        '{"tabsSave":[{"url":"https://www.torn.com/","chat":true},{"url":"https://www.torn.com/gym.php","chat":false}]}';
    Future<List<bool?>> tabs() async => [
      for (final tabs in [await Prefs().getWebViewMainTab(), await Prefs().getWebViewSecondaryTabs()])
        ...tabSaveModelFromJson(tabs).tabsSave!.map((t) => t.chatRemovalActive),
    ];
    Future<void> prepare({required bool icon}) async {
      await Prefs().setChatRemovalMigrated(false);
      await PrefsDatabase.setBool('pda_chatRemovalEnabled', icon);
      await Prefs().setChatRemovalActive(true);
      await Prefs().setWebViewMainTab(saved);
      await Prefs().setWebViewSecondaryTabs(saved);
    }

    final web = WebViewProvider();
    await prepare(icon: false);
    await web.migrateChatRemoval();
    expect(await Prefs().getChatRemovalActive(), isFalse);
    expect(await tabs(), everyElement(isFalse));
    expect(await Prefs().getChatRemovalEnabled(), isTrue);

    await Prefs().setChatRemovalActive(true);
    await web.migrateChatRemoval();
    expect(await Prefs().getChatRemovalActive(), isTrue);

    await prepare(icon: true);
    await web.migrateChatRemoval();
    expect(await Prefs().getChatRemovalActive(), isTrue);
    expect(await tabs(), [true, false, true, false]);
  });
}
