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
  rooms('Rooms');

  const ChatHelpGroup(this.title);

  final String title;
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
    'Drag it anywhere. Push it against an edge to tuck it away and tap it to bring it back. '
        'A double tap on the bubble marks every chat as read, with Undo. Global, Trade and Poker are skipped. '
        'Minimized chats wait as small bubbles next to it: long press '
        'the bubble to list them, and hold a small one to dismiss it. A red cloud means the chat lost its '
        'connection; it reconnects by itself. To open the chat from the browser or the side menu instead, pick '
        'Browser, Menu header or Menu bar in Chat settings > Open the chat from',
    spots: {ChatHelpSpot.intro},
    scenes: [FeatureDiagramScene.chatBubble, FeatureDiagramScene.chatWindow],
  ),
  ChatHelpEntry(
    ChatHelpGroup.start,
    Icons.menu_rounded,
    'The chat in the side menu',
    'Menu header puts the bubble on the side menu logo, with the same unread counts. Menu bar adds a Chat row '
        'above Profile instead: move it in Settings > Drawer sections. Tap either one to open the chat. They show '
        'only while the in-app chat is on and your API key works',
    scenes: [FeatureDiagramScene.chatDrawer, FeatureDiagramScene.chatMenuBar],
  ),
  ChatHelpEntry(
    ChatHelpGroup.start,
    Icons.chat_bubble_outline_rounded,
    'The chat icon in the browser',
    'Tap it to open this chat, or a small menu when the in-app chat is off. Double tap it to hide or show '
        'Torn\'s own chat in that tab, and long press it for more options, like hiding Torn\'s chat in every tab. '
        'Pick Browser in Chat settings > Open the chat from to show it in every tab with your unread counts',
    spots: {ChatHelpSpot.intro},
    scenes: [FeatureDiagramScene.chatBrowser],
  ),
  ChatHelpEntry(
    ChatHelpGroup.start,
    Icons.tune_rounded,
    'Settings',
    'All chat settings, from the button at the top of the chat or a long press on the chat icon. This guide is '
        'there too',
    spots: {ChatHelpSpot.intro},
  ),
  ChatHelpEntry(
    ChatHelpGroup.start,
    Icons.visibility_off_outlined,
    'Hide Torn\'s web chat',
    'Chat settings > Hide Torn\'s web chat in browser tabs takes Torn\'s own chat out of every open and '
        'new tab. It stays hidden only while the in-app chat is on or the browser chat icon is shown. Otherwise '
        'Torn\'s chat comes back, so you are never left without a chat, and your choice is kept for later',
  ),
  ChatHelpEntry(
    ChatHelpGroup.start,
    Icons.settings_backup_restore_rounded,
    'Back up chat settings',
    'At the bottom of Chat settings, export your nicknames, notes, words, tones, colors, rooms and preferences as '
        'text and import them on another device',
  ),
  ChatHelpEntry(
    ChatHelpGroup.start,
    Icons.login_rounded,
    'Logging in',
    'The chat uses your Torn login, like the website. Go to Settings > Torn Authentication and sign in with '
        'Google, Apple (iOS) or your Torn email and password, and the chat connects by itself. If Torn asks for a '
        'two-factor code, open the browser and enter it there',
    spots: {ChatHelpSpot.intro},
  ),
  ChatHelpEntry(
    ChatHelpGroup.alerts,
    Icons.alarm_add_rounded,
    'Remind me',
    'Long press a message and tap the alarm below it. Get a notification in a while, when you land, '
        'leave hospital or your energy is full',
    spots: {ChatHelpSpot.intro, ChatHelpSpot.quick},
  ),
  ChatHelpEntry(
    ChatHelpGroup.rooms,
    Icons.web_asset_rounded,
    'Link preview',
    'Links open in a small window over the app. Main tab or New tab moves the page to the browser. '
        'Turn it off in Chat settings > Messages & links',
    scenes: [FeatureDiagramScene.chatLinkPreview],
  ),
  ChatHelpEntry(
    ChatHelpGroup.rooms,
    Icons.menu_book_outlined,
    'Torn wiki',
    'Search the wiki with the Wiki chip to add a link. In the New players room, underlined terms like OC or xanax '
        'explain themselves when tapped',
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
    'Swipe right to reply. Swipe left outside private chats to act on who wrote it: chat, profile, attack, trade, '
        'bazaar or mail. Pick it in Chat settings > Writing & actions > Message actions',
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
    'Tap the pencil next to the help button to choose what each row shows: actions, emojis or saved replies. '
        'Turn actions on or off and drag them into the order you like. With more than one action row, drag the Row markers to split them',
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
    'In Trade and Global, a message offering to sell (WTS, want to sell) or to buy (WTB, want to buy) with a known '
        'item and price shows the market value next to it. Green is below market, grey is close, red is far off, so '
        'be careful. Nicknames like xans work too: edit them in Chat settings > Messages & links',
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
    'Pick a time in your clock to add it as TCT. Tap any TCT time in a message to see it in yours',
    spots: {ChatHelpSpot.quick},
    actions: {'time'},
  ),
  ChatHelpEntry(
    ChatHelpGroup.writing,
    Icons.add_reaction_outlined,
    'Emojis',
    'Tap one to put it in the message box at the cursor. The row shows your favorites, or the ones you use most '
        'until you pick some. Tap Emojis to pick favorites and drag them into order',
    spots: {ChatHelpSpot.quick},
    actions: {'emoji'},
  ),
  ChatHelpEntry(
    ChatHelpGroup.rooms,
    Icons.payments_outlined,
    'Amounts',
    'Tap an underlined amount like 1.2m, 850k or \$1,500 to see the exact figure. In Chat settings > '
        'Messages & links you can also see if your cash on hand covers it',
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
    'Share tab or Share script adds the link of an open tab or one of your scripts. Script links show as a '
        'card others can install in PDA',
    spots: {ChatHelpSpot.quick},
    actions: {'tab', 'script'},
  ),
  ChatHelpEntry(
    ChatHelpGroup.writing,
    Icons.share_rounded,
    'Share in and out',
    'Long press messages and tap Share to send them to another app, with names and TCT times. On '
        'Android, share a link or an image from another app to Torn PDA and pick a chat: it waits in the message '
        'box, and images upload only after you confirm. Nothing goes out until you tap Send',
  ),
  ChatHelpEntry(
    ChatHelpGroup.writing,
    Icons.forum_outlined,
    'Share from Torn PDA',
    'The chat icon in the top bar of a target or member, Share to chat on a foreign stock or ranked war card, '
        'and a swipe left on a stakeout leave a clean text in the box of the chat you pick. Nothing goes out '
        'until you tap Send',
  ),
  ChatHelpEntry(
    ChatHelpGroup.alerts,
    Icons.highlight_rounded,
    'Highlight words',
    'Words you add in Settings > Browser > Highlight words also show in this chat. In Chat settings > '
        'Alerts > Highlight words, the bell next to a word alerts for it, but only in chats set to Alert on: '
        'Everything',
  ),
  ChatHelpEntry(
    ChatHelpGroup.alerts,
    Icons.subtitles_rounded,
    'Ticker',
    'A line for each new message, over the app. In Chat settings > Alerts > Ticker, When tapped sets what a tap '
        'does: Open quick window, or Expand in place to read the whole message with Open and Reply. Press and '
        'hold for the other option. Preview plays a sample to check the position, time and lines of text',
  ),
  ChatHelpEntry(
    ChatHelpGroup.alerts,
    Icons.flash_on_rounded,
    'Bubble glow',
    'The floating bubble flashes in the color of the room the message came from. Choose Same as ticker, Custom '
        'or Off in Chat settings > Open the chat from. Frozen and hidden chats never glow, and it stays still if the '
        'system asks for fewer animations',
  ),
  ChatHelpEntry(
    ChatHelpGroup.alerts,
    Icons.alternate_email_rounded,
    'Only when mentioned',
    'Set a room to Mentions in its menu to get alerts only when your name appears, as @name or as the whole word. '
        'Highlight words do not count here. It works the same in notifications, the ticker and the tray',
  ),
  ChatHelpEntry(
    ChatHelpGroup.rooms,
    Icons.filter_alt_outlined,
    'Room filters',
    'Use Filter in a room\'s menu to show only, or hide, messages with some words. Your own messages, '
        'mentions and highlighted words always show',
  ),
  ChatHelpEntry(
    ChatHelpGroup.rooms,
    Icons.ac_unit_rounded,
    'Live, Frozen and Hidden',
    'In a room\'s Alerts and mute, or in Chat settings > Rooms, pick how it behaves. Live updates in '
        'real time, like Torn\'s chat. Frozen saves battery: no messages, alerts or bubble count until you '
        'unfreeze it or its time ends, and opening it still shows the latest messages. Hidden takes it out of the '
        'list and the counts, and "Hidden rooms", at the end of the list, brings it back',
  ),
  ChatHelpEntry(
    ChatHelpGroup.look,
    Icons.palette_outlined,
    'Color per player',
    'Turn on Color per player in Chat settings > People to give each sender their own name color. It always stays '
        'readable on the bubble. A color picked in Customize a player comes first',
  ),
  ChatHelpEntry(
    ChatHelpGroup.look,
    Icons.view_headline_rounded,
    'Compact mode and text size',
    'In Chat settings > Appearance, Compact mode drops the bubbles and shows each message as a row, Name: message, '
        'with a small time on the right. Colors, highlights, quotes, links and images work the same. Show avatars '
        'hides the pictures, and the slider sets only the chat text size, from 80% to 160%, on top of your system '
        'text size. It applies to the full screen chat and the small windows',
  ),
  ChatHelpEntry(
    ChatHelpGroup.look,
    Icons.format_color_fill_rounded,
    'Chat colors',
    'Pick the chat background, your bubbles and theirs, and their text, for each app theme in Chat settings > '
        'Appearance > Colors. The preview changes as you pick. If some text gets hard to read, Torn PDA warns you '
        'and offers white or black text. Reset puts the theme back to default',
  ),
  ChatHelpEntry(
    ChatHelpGroup.start,
    Icons.circle,
    'Status at the top',
    'In a private chat, the line under the name says if they are online and their Torn status, with a colored '
        'dot. Tap the name for their card. Alerts, minimize and more are in the menu on the right',
  ),
  ChatHelpEntry(
    ChatHelpGroup.look,
    Icons.palette_outlined,
    'Customize a player',
    'In a player card, Customize picks their name color, highlights all their messages and sets a nickname only '
        'you see. Their sound, vibration and mute are in Alerts and mute; muting someone also silences their '
        'mentions in rooms. Highlighted players are listed in Chat settings > People > Player nicknames',
  ),
  ChatHelpEntry(
    ChatHelpGroup.writing,
    Icons.sticky_note_2_outlined,
    'Chat notes',
    'Chat notes stay in the chat, player notes show everywhere in Torn PDA',
  ),
  ChatHelpEntry(
    ChatHelpGroup.alerts,
    Icons.visibility_outlined,
    'Watch, targets and friends',
    'In a player\'s menu, one tap adds them to your Torn PDA stakeouts, targets or friends, and another tap '
        'removes them. Add to chat friends keeps them in the Chat tab of Friends. Watching alerts you when they come '
        'online, leave hospital or land, depending on their status. Tap the name at the top of a private chat to get '
        'there',
  ),
  ChatHelpEntry(
    ChatHelpGroup.writing,
    Icons.shield_outlined,
    'Safe sending',
    'Torn PDA asks before sending something that looks like an API key, or a message to Global, Trade, Poker or '
        'New players',
  ),
  ChatHelpEntry(
    ChatHelpGroup.alerts,
    Icons.notifications_active_outlined,
    'Sound and vibration',
    'Each chat has its own sound, vibration and mute. Use Alerts and mute in a room\'s menu or in a player\'s '
        'details, or long press the chat in the list. While you travel, you can mute a chat until you land',
  ),
  ChatHelpEntry(
    ChatHelpGroup.rooms,
    Icons.link_rounded,
    'Chain and war',
    'The faction chat shows your chain and ranked war on top, with a note when the chain gets low and for '
        'each retal',
  ),
  ChatHelpEntry(
    ChatHelpGroup.rooms,
    Icons.newspaper_rounded,
    'Faction news',
    'Joins, leaves, chain and war news can show in the faction chat, grouped in one line. '
        'It needs a key with faction access',
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
    ChatHelpGroup.alerts,
    Icons.mark_chat_unread_outlined,
    'Mark as unread',
    'Swipe a chat in the list, long press it, or use the menu at the top of a chat to mark it as unread. '
        'It counts as unread, on this device only, until you open it',
  ),
  ChatHelpEntry(
    ChatHelpGroup.rooms,
    Icons.archive_outlined,
    'Archive a private chat',
    'Swipe a private chat the other way or long press it and pick Archive. It leaves the list and the unread count, '
        'but stays open in Torn. It returns by itself when they write again. Archived (n) at the end of the list '
        'brings it back with Unarchive. This is on this device only',
  ),
  ChatHelpEntry(
    ChatHelpGroup.alerts,
    Icons.hourglass_top_rounded,
    'Waiting for you',
    'The strip above the chat list shows private chats where the last message is theirs and you have not answered '
        'for a few hours. Tap a name to open it, or swipe it away or tap its X to dismiss it until they write again. '
        'It does not add to the unread count. Choose the hours, or turn it off, in Chat settings > Rooms',
  ),
  ChatHelpEntry(
    ChatHelpGroup.alerts,
    Icons.history_rounded,
    'While you were away',
    'After half an hour away, a room opens with a summary, only when there is something worth jumping to. '
        'Tap one to jump there',
  ),
  ChatHelpEntry(
    ChatHelpGroup.alerts,
    Icons.reply_rounded,
    'Reply from notifications',
    'On Android, private chat notifications have a Reply button to answer without opening the app',
  ),
  ChatHelpEntry(
    ChatHelpGroup.rooms,
    Icons.ads_click_rounded,
    'App icon shortcuts',
    'Long press the Torn PDA icon to jump straight to your most opened chats',
  ),
  ChatHelpEntry(
    ChatHelpGroup.rooms,
    Icons.accessibility_new_rounded,
    'Accessibility',
    'The chat works with TalkBack, VoiceOver and large text. Gestures like double tap are also in the screen '
        'reader\'s actions menu',
  ),
];
