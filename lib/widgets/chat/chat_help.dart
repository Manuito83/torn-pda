import 'package:flutter/material.dart';
import 'package:torn_pda/models/chat/chat_template.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/diagrams/feature_diagrams.dart';

enum ChatHelpSpot { intro, quick }

enum ChatHelpGroup {
  start('Start here'),
  writing('Writing'),
  alerts('Alerts'),
  look('Look'),
  rooms('Rooms'),
  accessibility('Accessibility');

  const ChatHelpGroup(this.title);

  final String title;
}

enum ChatNeed {
  screenReader('a screen reader'),
  largeText('larger text'),
  boldText('bold text'),
  highContrast('higher contrast'),
  fewerAnimations('fewer animations');

  const ChatNeed(this.label);

  final String label;
}

bool chatLargeText(TextScaler scaler) => scaler.scale(14) > 14 * 1.3;

Set<ChatNeed> chatNeedsOf(MediaQueryData media) => {
  if (media.accessibleNavigation) ChatNeed.screenReader,
  if (chatLargeText(media.textScaler)) ChatNeed.largeText,
  if (media.boldText) ChatNeed.boldText,
  if (media.highContrast) ChatNeed.highContrast,
  if (media.disableAnimations) ChatNeed.fewerAnimations,
};

String chatNeedsText(Set<ChatNeed> needs) {
  final names = [
    for (final n in ChatNeed.values)
      if (needs.contains(n)) n.label,
  ];
  final list = names.length < 2 ? names.join() : '${names.sublist(0, names.length - 1).join(', ')} and ${names.last}';
  return 'Your phone uses $list';
}

List<ChatHelpEntry> chatHelpOf(ChatHelpGroup group, Set<ChatNeed> needs) {
  final all = chatHelp.where((e) => e.group == group);
  bool fits(ChatHelpEntry e) => e.needs.any(needs.contains);
  return [...all.where(fits), ...all.where((e) => !fits(e))];
}

class ChatHelpEntry {
  const ChatHelpEntry(
    this.group,
    this.icon,
    this.title,
    String text, {
    this.spots = const {},
    this.scenes = const [],
    this.actions = const {},
    this.withSlots = false,
    this.needs = const {},
  }) : _text = text;

  final ChatHelpGroup group;
  final IconData icon;
  final String title;
  final String _text;
  final Set<ChatHelpSpot> spots;
  final List<FeatureDiagramScene> scenes;

  final Set<String> actions;

  /// Adds what each reply slot fills
  final bool withSlots;

  /// Shown first with these phone settings
  final Set<ChatNeed> needs;

  String get text => withSlots ? '$_text:\n${ChatTemplate.slots.map((s) => '${s.tag} - ${s.help}').join('\n')}' : _text;
}

({List<List<ChatHelpEntry>> rows, List<ChatHelpEntry> off, List<ChatHelpEntry> other}) quickGuide({
  required List<String> order,
  required List<ChatQuickRow> rows,
  required bool Function(String id) isOff,
}) {
  final quick = chatHelp.where((e) => e.spots.contains(ChatHelpSpot.quick));
  final actionRows = rows.where((t) => t == ChatQuickRow.actions).length;
  final split = ChatPrefs.splitQuickRows(order, rows: actionRows);
  final shown = <ChatHelpEntry>{};
  List<ChatHelpEntry> pick(Iterable<String> ids) => [
    for (final id in ids)
      for (final e in quick)
        if (e.actions.contains(id) && shown.add(e)) e,
  ];
  var action = 0;
  final shownRows = [
    for (final type in rows)
      switch (type) {
        ChatQuickRow.actions => pick(split[action++].where((id) => !isOff(id))),
        ChatQuickRow.emoji => pick(['emoji']),
        ChatQuickRow.replies => pick(['replies']),
      },
  ];
  return (
    rows: shownRows,
    off: actionRows == 0 ? const [] : pick(split.expand((ids) => ids).where(isOff)),
    other: [for (final e in quick) if (e.actions.isEmpty) e],
  );
}

const chatHelp = <ChatHelpEntry>[
  ChatHelpEntry(
    ChatHelpGroup.start,
    Icons.forum_rounded,
    'The bubble',
    'Tap it to open the full chat, or a chat window if you pick Window in Chat settings > Chat button. Long press '
        'it for Window, Full chat and Chat settings. Drag it anywhere, or push it against an edge to tuck it away and '
        'tap it to bring it back. A double tap marks your chats as read, with Undo. Rooms like Global and Trade, '
        'hidden rooms and archived chats stay as they are. A red cloud means the chat is not connected. To have the '
        'chat button in the browser or the side menu instead, pick Browser, Menu header or Menu bar in Chat '
        'settings > Chat button',
    spots: {ChatHelpSpot.intro},
    scenes: [FeatureDiagramScene.chatBubble, FeatureDiagramScene.chatWindow],
  ),
  ChatHelpEntry(
    ChatHelpGroup.start,
    Icons.bubble_chart_outlined,
    'Minimized chats',
    'Small bubbles next to the bubble hold your minimized chats. Tap one to reopen it, or hold it to dismiss it. '
        'Long press the bubble to see them all in a list. The chat window minimizes into the '
        'bubble, or into a small bubble of its own if you open the chat from somewhere else. To get your open windows '
        'and full chat back after a restart, turn on Reopen chats as I left them in Chat settings > Chat button',
  ),
  ChatHelpEntry(
    ChatHelpGroup.start,
    Icons.menu_rounded,
    'The chat in the side menu',
    'Menu header puts the bubble on the side menu logo, with the same unread counts. Menu bar adds a Chat row '
        'above Profile instead, and Settings > Drawer sections moves it. Tap either one to open the chat, long press '
        'it for Window, Full chat and Chat settings. Both need the in-app chat on and a working API key',
    scenes: [FeatureDiagramScene.chatDrawer, FeatureDiagramScene.chatMenuBar],
  ),
  ChatHelpEntry(
    ChatHelpGroup.start,
    Icons.chat_bubble_outline_rounded,
    'The chat icon in the browser',
    'Tap it to open the chat, or a small menu when the in-app chat is off. Double tap it to hide or show '
        'Torn\'s own chat in that tab. Long press it for Window, Full chat, Chat settings and hiding Torn\'s chat '
        'in every tab. With Browser picked in Chat settings > Chat button, it shows in every tab with your '
        'unread counts',
    spots: {ChatHelpSpot.intro},
    scenes: [FeatureDiagramScene.chatBrowser],
  ),
  ChatHelpEntry(
    ChatHelpGroup.start,
    Icons.web_stories_outlined,
    'The chat window',
    'The chat window floats over the app. Drag its top bar to move it and the corner to resize it. The buttons on '
        'top minimize it and open the full chat. More has Chat settings and Maximize window, which only makes the '
        'window fill the screen. In a conversation, the small window button pops it out on its own',
  ),
  ChatHelpEntry(
    ChatHelpGroup.start,
    Icons.tune_rounded,
    'Settings',
    'The settings button at the top of the full chat opens Chat settings. So do a long press on the chat button, '
        'More in a chat window and Chat in the app Settings. This guide is there too, under How the chat works',
    spots: {ChatHelpSpot.intro},
  ),
  ChatHelpEntry(
    ChatHelpGroup.start,
    Icons.visibility_off_outlined,
    'Hide Torn\'s web chat',
    'Chat settings > Hide Torn\'s web chat in browser tabs takes Torn\'s own chat out of every open and new tab. '
        'It stays hidden only while the in-app chat is on or the browser chat icon is shown. Otherwise Torn\'s chat '
        'comes back, and your choice is kept for later',
  ),
  ChatHelpEntry(
    ChatHelpGroup.start,
    Icons.settings_backup_restore_rounded,
    'Back up chat settings',
    'At the bottom of Chat settings, export your nicknames, notes, words, tones, colors, rooms and preferences as '
        'text. Import it on another device',
  ),
  ChatHelpEntry(
    ChatHelpGroup.start,
    Icons.login_rounded,
    'Logging in',
    'The chat uses your Torn login, like the website. Sign in at Settings > Torn Authentication with Google, '
        'Apple (iOS) or your Torn email and password, and the chat connects by itself. If Torn asks for a '
        'two-factor code, enter it in the browser',
    spots: {ChatHelpSpot.intro},
  ),
  ChatHelpEntry(
    ChatHelpGroup.alerts,
    Icons.alarm_add_rounded,
    'Remind me',
    'Long press a message and tap Remind me. Pick a time, or a moment like landing, leaving hospital or full '
        'energy when it applies',
    spots: {ChatHelpSpot.intro, ChatHelpSpot.quick},
  ),
  ChatHelpEntry(
    ChatHelpGroup.rooms,
    Icons.web_asset_rounded,
    'Link preview',
    'Links open in a small window over the app. Main tab or New tab sends the page to the browser. Turn it off in '
        'Chat settings > Messages & links > Preview links in a window',
    scenes: [FeatureDiagramScene.chatLinkPreview],
  ),
  ChatHelpEntry(
    ChatHelpGroup.writing,
    Icons.menu_book_outlined,
    'Torn wiki',
    'The Wiki chip searches the wiki and adds the link. In the New players room, tap an underlined term like OC '
        'or xanax to see what it means. Chat settings > Messages & links > Explain Torn slang everywhere does it in '
        'every chat',
    spots: {ChatHelpSpot.intro, ChatHelpSpot.quick},
    actions: {'wiki'},
  ),
  ChatHelpEntry(
    ChatHelpGroup.start,
    Icons.person_search_outlined,
    'Player card',
    'Tap or hold a name or avatar to see their level and status, attack, trade, add a note or ignore them. '
        'It also opens from the top of a private chat, a long press in the chat list or on a mention, '
        'and the dots next to friends and search results',
    spots: {ChatHelpSpot.intro},
    scenes: [FeatureDiagramScene.chatPlayerCard],
  ),
  ChatHelpEntry(
    ChatHelpGroup.writing,
    Icons.swipe_left_rounded,
    'Swipe a message',
    'Swipe right to reply. Outside private chats, swipe left to act on who wrote it: chat, profile, attack, '
        'trade, bazaar or mail. Pick which one in Chat settings > Writing & actions > Message actions',
  ),
  ChatHelpEntry(
    ChatHelpGroup.writing,
    Icons.bolt_rounded,
    'Replies',
    'Tap one to put it in the message box. Slots fill themselves, or a sheet asks for them. '
        'Save replies in Chat settings > Writing & actions > Quick replies, or with Save a reply when the row is '
        'empty. '
        'Hold a slot there to see what it fills',
    withSlots: true,
    spots: {ChatHelpSpot.quick},
    actions: {'replies'},
  ),
  ChatHelpEntry(
    ChatHelpGroup.writing,
    Icons.edit_outlined,
    'Edit',
    'The pencil next to the help button picks what each row shows: actions, emojis or saved replies. Turn '
        'actions on or off and drag them into order. With more than one action row, drag the Row markers to '
        'split them',
    spots: {ChatHelpSpot.quick},
  ),
  ChatHelpEntry(
    ChatHelpGroup.writing,
    Icons.sell_outlined,
    'Item price',
    'Find an item and add its market value, with its link if you want',
    spots: {ChatHelpSpot.quick},
    actions: {'price'},
  ),
  ChatHelpEntry(
    ChatHelpGroup.rooms,
    Icons.price_check_rounded,
    'Price check',
    'In Trade and Global, an offer to sell (WTS) or buy (WTB) a known item at a price shows its market value next '
        'to it. Green is below market, grey is close, red is far off. Nicknames like xans work too: edit them in '
        'Chat settings > Messages & links > Item nicknames',
    spots: {ChatHelpSpot.intro},
  ),
  ChatHelpEntry(
    ChatHelpGroup.writing,
    Icons.monitor_heart_outlined,
    'Status',
    'Pick which bars, timers and cooldowns to put in the message',
    spots: {ChatHelpSpot.quick},
    actions: {'status'},
  ),
  ChatHelpEntry(
    ChatHelpGroup.writing,
    Icons.schedule_rounded,
    'Time',
    'Pick a time on your clock to add it as TCT. Tap any TCT time in a message to see it in your time',
    spots: {ChatHelpSpot.quick},
    actions: {'time'},
  ),
  ChatHelpEntry(
    ChatHelpGroup.writing,
    Icons.add_reaction_outlined,
    'Emojis',
    'Tap one to put it in the message box at the cursor. The row shows your favorites, or your most used until '
        'you pick some. Tap Emojis to pick favorites and drag them into order',
    spots: {ChatHelpSpot.quick},
    actions: {'emoji'},
  ),
  ChatHelpEntry(
    ChatHelpGroup.rooms,
    Icons.payments_outlined,
    'Amounts',
    'Tap an underlined amount like 1.2m, 850k or \$1,500 to see the exact figure. Turn on Compare amounts with '
        'your cash in Chat settings > Messages & links to see if your cash on hand covers it',
  ),
  ChatHelpEntry(
    ChatHelpGroup.writing,
    Icons.search_rounded,
    'Find a player',
    'Find someone by name or ID to see their level and status, add them to the message or open their actions',
    spots: {ChatHelpSpot.quick},
    actions: {'player'},
  ),
  ChatHelpEntry(
    ChatHelpGroup.writing,
    Icons.tab_rounded,
    'Share tab or script',
    'Share tab adds the link of an open tab, and Share script one of your scripts. Others see a script link as a '
        'card they can install in Torn PDA',
    spots: {ChatHelpSpot.quick},
    actions: {'tab', 'script'},
  ),
  ChatHelpEntry(
    ChatHelpGroup.writing,
    Icons.share_rounded,
    'Share in and out',
    'Long press messages and tap Share to send them to another app, with names and TCT times. On Android, share '
        'a link or an image to Torn PDA from another app and pick a chat: it waits in the message box, and images '
        'upload only after you confirm',
  ),
  ChatHelpEntry(
    ChatHelpGroup.writing,
    Icons.forum_outlined,
    'Share from Torn PDA',
    'The chat icon in the top bar of a target or member, Share to chat on a foreign stock or ranked war card, '
        'and a swipe left on a stakeout put a clean text in the message box of the chat you pick. Nothing goes '
        'out until you tap Send',
  ),
  ChatHelpEntry(
    ChatHelpGroup.alerts,
    Icons.highlight_rounded,
    'Highlight words',
    'Words you add in Settings > Browser > Highlight words also show in the chat. In Chat settings > Alerts > '
        'Highlight words, the bell next to a word alerts for it, only in chats with Alert on set to Everything',
  ),
  ChatHelpEntry(
    ChatHelpGroup.alerts,
    Icons.subtitles_rounded,
    'Ticker',
    'A line over the app for each new message. In Chat settings > Alerts > Ticker, When tapped picks what a tap '
        'does: Open quick window, or Expand in place to read the whole message with Open and Reply. Press and hold '
        'does the other one. Preview plays a sample ticker',
  ),
  ChatHelpEntry(
    ChatHelpGroup.alerts,
    Icons.flash_on_rounded,
    'Bubble glow',
    'The bubble flashes in the color of the room the message came from. With Bubble picked in Chat settings > '
        'Chat button, choose Same as ticker, Custom or Off there. Frozen and hidden rooms never make it glow',
  ),
  ChatHelpEntry(
    ChatHelpGroup.alerts,
    Icons.alternate_email_rounded,
    'Only when mentioned',
    'In a room\'s Alerts and mute, set Alert on to Mentions to get alerts only when your name appears, as @name '
        'or as the whole word. Highlight words do not count here. Notifications, the ticker and the Mentions and '
        'highlight words list follow it too',
  ),
  ChatHelpEntry(
    ChatHelpGroup.rooms,
    Icons.filter_alt_outlined,
    'Room filters',
    'Use Filter in a room\'s menu to show only, or hide, messages with some words. Your own messages, mentions and '
        'highlighted words always show',
  ),
  ChatHelpEntry(
    ChatHelpGroup.rooms,
    Icons.ac_unit_rounded,
    'Live, Frozen and Hidden',
    'Pick how a room behaves in its Alerts and mute, or in Chat settings > Rooms. Live updates in real time, like '
        'Torn\'s chat. Frozen saves battery: no messages, alerts or bubble count until you unfreeze it or its time '
        'ends. Opening it still shows the latest messages. Hidden takes it out of the list and the counts, and '
        'Hidden rooms, at the end of the list, brings it back',
  ),
  ChatHelpEntry(
    ChatHelpGroup.look,
    Icons.palette_outlined,
    'Color per player',
    'In Chat settings > People, give each sender their own name color, always readable on the bubble. A color '
        'picked in Customize comes first',
  ),
  ChatHelpEntry(
    ChatHelpGroup.look,
    Icons.view_headline_rounded,
    'Compact mode',
    'In Chat settings > Appearance, drop the bubbles and show each message as a row, Name: message, with a small '
        'time on the right. Colors, highlights, quotes, links and images work the same. Show avatars hides the '
        'pictures',
  ),
  ChatHelpEntry(
    ChatHelpGroup.look,
    Icons.format_color_fill_rounded,
    'Chat colors',
    'Pick the chat background, your bubbles and theirs, and their text, for each app theme in Chat settings > '
        'Appearance > Colors. The preview changes as you pick. Reset puts the theme back to default',
  ),
  ChatHelpEntry(
    ChatHelpGroup.start,
    Icons.circle,
    'Status at the top',
    'In a private chat, the line under the name says if they are online, or when they were last seen, and their '
        'Torn status, with a colored dot. Tap the name for their card. The menu on the right has Alerts and mute, '
        'Mark as unread and more',
  ),
  ChatHelpEntry(
    ChatHelpGroup.look,
    Icons.palette_outlined,
    'Customize a player',
    'Customize, in a player\'s menu, sets their name color, a highlight on all their messages and a nickname only '
        'you see. Their sound, vibration and mute are in Alerts and mute; muting someone also silences their '
        'mentions in rooms. Players you customize are listed in Chat settings > People > Player nicknames',
  ),
  ChatHelpEntry(
    ChatHelpGroup.start,
    Icons.sticky_note_2_outlined,
    'Chat notes',
    'A player\'s menu has two notes. Chat note shows only in the chat, Player note everywhere in Torn PDA',
  ),
  ChatHelpEntry(
    ChatHelpGroup.alerts,
    Icons.visibility_outlined,
    'Watch, targets and friends',
    'In a player\'s menu, one tap adds them to your stakeouts, targets or friends, and another removes them. '
        'Watching alerts you when they come online, leave hospital or land, depending on their status. Add to chat '
        'friends keeps them in the Chat tab of Friends. Tap the name at the top of a private chat to get there',
  ),
  ChatHelpEntry(
    ChatHelpGroup.writing,
    Icons.shield_outlined,
    'Safe sending',
    'Torn PDA asks before sending something that looks like an API key. Turn on Confirm messages to public rooms '
        'in Chat settings > Writing & actions to be asked before writing in rooms like Global or Trade too',
  ),
  ChatHelpEntry(
    ChatHelpGroup.alerts,
    Icons.notifications_active_outlined,
    'Sound and vibration',
    'Each chat has its own sound, vibration and mute in Alerts and mute. Open it from a room\'s menu, a player\'s '
        'menu or a long press on the chat in the list. While you travel, Until I land mutes a chat until you arrive',
  ),
  ChatHelpEntry(
    ChatHelpGroup.rooms,
    Icons.link_rounded,
    'Chain and war',
    'The faction chat shows your chain and ranked war on top, with a note when the chain gets low and one for '
        'each retal. Choose what shows in Chat settings > Faction room',
  ),
  ChatHelpEntry(
    ChatHelpGroup.rooms,
    Icons.newspaper_rounded,
    'Faction news',
    'Joins, leaves, chain and war news can show in the faction chat, grouped in one line. Turn on Faction events '
        'in chat in Chat settings > Faction room. It needs an API key with faction access',
  ),
  ChatHelpEntry(
    ChatHelpGroup.alerts,
    Icons.skip_next_rounded,
    'Next unread',
    'Inside a chat, the button at the top shows how many other chats have unread messages. Tap it, or swipe in '
        'from the right edge, to jump to the next one in list order. Back returns to the chat list. In a small '
        'window, it is in the More menu',
  ),
  ChatHelpEntry(
    ChatHelpGroup.rooms,
    Icons.mark_chat_unread_outlined,
    'Mark as unread',
    'Swipe a chat in the list, long press it, or use the menu at the top of a chat to mark it as unread. '
        'It counts as unread, on this device only, until you open it',
  ),
  ChatHelpEntry(
    ChatHelpGroup.rooms,
    Icons.archive_outlined,
    'Archive a private chat',
    'Swipe a private chat the other way, or long press it and pick Archive. It leaves the list and the unread '
        'count but stays open in Torn, and comes back when they write again. Archived, at the end of the list, has '
        'Unarchive. This is on this device only',
  ),
  ChatHelpEntry(
    ChatHelpGroup.alerts,
    Icons.hourglass_top_rounded,
    'Waiting for you',
    'The strip above the chat list shows private chats where they wrote last and you have not answered for a few '
        'hours. Tap a name to open it, or swipe it away or tap its X until they write again. It does not add to the '
        'unread count. Set the hours, or turn it off, in Chat settings > Rooms > Waiting for you',
  ),
  ChatHelpEntry(
    ChatHelpGroup.alerts,
    Icons.history_rounded,
    'While you were away',
    'Back in a room after half an hour or more, a summary shows what you missed when there is something worth '
        'jumping to. Tap one to go there',
  ),
  ChatHelpEntry(
    ChatHelpGroup.alerts,
    Icons.phone_android_rounded,
    'With the app closed',
    'Only private chats notify with the app closed. Faction, company and other rooms alert while it is open '
        'or just left',
  ),
  ChatHelpEntry(
    ChatHelpGroup.alerts,
    Icons.reply_rounded,
    'Reply from notifications',
    'On Android, private chat notifications have a Reply button to answer without opening the app',
  ),
  ChatHelpEntry(
    ChatHelpGroup.start,
    Icons.ads_click_rounded,
    'App icon shortcuts',
    'Long press the Torn PDA icon to jump to a chat. Pick which ones in Chat settings > Chat button > '
        'App icon menu',
  ),
  ChatHelpEntry(
    ChatHelpGroup.accessibility,
    Icons.accessibility_new_rounded,
    'Screen readers',
    'TalkBack and VoiceOver read each message as one line, with its links, times and gestures in the actions '
        'menu. The bubble, windows, ticker, chat list and browser chat icon have their gestures there too, moving '
        'included, and notices with Undo wait for you',
    needs: {ChatNeed.screenReader},
  ),
  ChatHelpEntry(
    ChatHelpGroup.accessibility,
    Icons.record_voice_over_outlined,
    'New messages read aloud',
    'The chat you have open reads out new messages: all of them in private, faction and company chats, only '
        'mentions and highlight words elsewhere. Ticker lines stay until you dismiss them',
    needs: {ChatNeed.screenReader},
  ),
  ChatHelpEntry(
    ChatHelpGroup.accessibility,
    Icons.format_size_rounded,
    'Text size',
    'The chat follows your system text size. On top of it, Chat settings > Appearance > Chat text size goes '
        'from 80% to 160% for messages and the ticker',
    needs: {ChatNeed.largeText, ChatNeed.boldText},
  ),
  ChatHelpEntry(
    ChatHelpGroup.accessibility,
    Icons.contrast_rounded,
    'Contrast',
    'Name colors always stay readable on the bubble. In Chat settings > Appearance > Colors, Torn PDA '
        'warns you when some text gets hard to read and offers white or black text',
    needs: {ChatNeed.highContrast},
  ),
  ChatHelpEntry(
    ChatHelpGroup.accessibility,
    Icons.motion_photos_off_outlined,
    'Fewer animations',
    'When the system asks for fewer animations, the chat jumps instead of animating and the bubble does not '
        'flash with new messages',
    needs: {ChatNeed.fewerAnimations},
  ),
];
