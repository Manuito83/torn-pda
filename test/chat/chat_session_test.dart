import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/providers/chat/chat_controller.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

import 'chat_fakes.dart';

void main() {
  late FakeChatSource source;
  late ChatController chat;

  setUp(() {
    source = FakeChatSource();
    chat = ChatController(source, ChatPrefs());
  });

  void emit(ChatConnection state, {bool tentative = false}) =>
      source.emit(ChatConnectionEvent(state, tentative: tentative));

  void session(String name, Future<void> Function(WidgetTester tester) body) => testWidgets(name, (tester) async {
    chat.resetStall();
    await body(tester);
    chat.dispose();
  });

  session('tentative noSession waits for grace', (tester) async {
    emit(ChatConnection.noSession, tentative: true);
    await tester.pump(const Duration(seconds: 20));
    expect(chat.sessionIssue, isFalse);
    expect(chat.starting, isTrue);

    await tester.pump(const Duration(seconds: 6));
    expect(chat.connection, ChatConnection.noSession);
    expect(chat.starting, isFalse);
  });

  session('logout stalls, login reconnects', (tester) async {
    source.emit(const ChatReadyEvent(1));
    emit(ChatConnection.connected);
    chat.onLogout();
    emit(ChatConnection.disconnected);
    expect(chat.connection, ChatConnection.noSession);
    expect(chat.stalled, isTrue);

    chat.retrySession();
    expect(source.count('reconnect'), 1);
    chat.onLogin();
    expect(source.count('reconnect'), 2);
    expect(chat.stalled, isFalse);
    expect(chat.sessionIssue, isFalse);
  });

  session('login as someone else switches a live chat', (tester) async {
    source.emit(const ChatReadyEvent(1));
    emit(ChatConnection.connected);
    chat.onLogin();
    expect(source.count('reconnect'), 0);
    expect(source.count('switchAccount'), 0);

    chat.onLogin(accountChanged: true);
    expect(source.count('switchAccount'), 1);
    expect(source.count('reconnect'), 0);
    expect(chat.connection, ChatConnection.connected);
  });

  session('failed login stops a live chat', (tester) async {
    expect(NativeChat.logoutStops(chat, hadLogin: false), isFalse);
    emit(ChatConnection.noSession);
    expect(NativeChat.logoutStops(chat, hadLogin: true), isFalse);
    source.emit(const ChatReadyEvent(1));
    emit(ChatConnection.connected);
    expect(NativeChat.logoutStops(chat, hadLogin: false), isTrue);
  });

  session('no login at all shows right away', (tester) async {
    emit(ChatConnection.noSession);
    expect(chat.connection, ChatConnection.noSession);
    expect(chat.needsLogin, isTrue);
  });

  session('session back within grace', (tester) async {
    emit(ChatConnection.needsBrowser);
    await tester.pump(const Duration(seconds: 10));
    source.emit(const ChatReadyEvent(1));
    emit(ChatConnection.connected);
    await tester.pump(const Duration(seconds: 30));

    expect(chat.connection, ChatConnection.connected);
    expect(chat.sessionIssue, isFalse);
  });

  session('offline after grace, then recovers', (tester) async {
    emit(ChatConnection.offline);
    expect(chat.starting, isTrue);
    await tester.pump(const Duration(seconds: 26));
    expect(chat.connection, ChatConnection.offline);
    expect(chat.sessionIssue, isTrue);

    source.emit(const ChatReadyEvent(1));
    emit(ChatConnection.connected);
    expect(chat.sessionIssue, isFalse);
    expect(chat.starting, isFalse);
  });

  session('offline after the grace shows at once', (tester) async {
    await tester.pump(const Duration(seconds: 26));
    emit(ChatConnection.tornDown);
    expect(chat.connection, ChatConnection.tornDown);
    expect(chat.sessionIssue, isTrue);
  });

  session('resume restarts the grace', (tester) async {
    await tester.pump(const Duration(seconds: 26));
    emit(ChatConnection.needsBrowser);
    expect(chat.needsLogin, isTrue);

    chat.resumed();
    expect(chat.needsLogin, isFalse);
    expect(chat.starting, isTrue);

    await tester.pump(const Duration(seconds: 26));
    expect(chat.connection, ChatConnection.needsBrowser);
  });

  session('lost connection keeps data', (tester) async {
    source.emit(const ChatReadyEvent(1));
    await tester.pump(const Duration(seconds: 26));
    emit(ChatConnection.offline);

    expect(chat.ready, isTrue);
    expect(chat.sessionIssue, isFalse);
  });

  // Timers start in the zone that listens
  void bubble(String name, Future<void> Function(WidgetTester tester) body) => session(name, (tester) async {
    chat.dispose();
    source = FakeChatSource();
    chat = ChatController(source, ChatPrefs());
    await body(tester);
  });

  bubble('loadingCounts until ready', (tester) async {
    expect(chat.loadingCounts, isTrue);
    emit(ChatConnection.connected);
    expect(chat.starting, isFalse);
    expect(chat.loadingCounts, isTrue);
    source.emit(const ChatUnreadEvent({'faction': 1}));
    expect(chat.loadingCounts, isTrue);
    source.emit(const ChatReadyEvent(1));
    expect(chat.loadingCounts, isFalse);
  });

  bubble('connected without ready stalls after 30 seconds and recovers', (tester) async {
    emit(ChatConnection.connected);
    await tester.pump(const Duration(seconds: 29));
    expect(chat.stalled, isFalse);
    await tester.pump(const Duration(seconds: 1));
    expect(chat.stalled, isTrue);
    source.emit(const ChatReadyEvent(1));
    expect(chat.stalled, isFalse);
  });

  bubble('unread retry backoff', (tester) async {
    emit(ChatConnection.connected);
    source.emit(const ChatReadyEvent(1));
    source.calls.clear();

    source.emit(const ChatUnreadFailedEvent());
    await tester.pump(const Duration(seconds: 4));
    expect(source.count('refreshUnread'), 0);
    await tester.pump(const Duration(seconds: 1));
    expect(source.count('refreshUnread'), 1);

    source.emit(const ChatUnreadFailedEvent());
    await tester.pump(const Duration(seconds: 14));
    expect(source.count('refreshUnread'), 1);
    expect(chat.loadingCounts, isTrue);
    await tester.pump(const Duration(seconds: 1));
    expect(source.count('refreshUnread'), 2);
    expect(chat.loadingCounts, isFalse);
    expect(chat.stalled, isFalse);

    source.emit(const ChatUnreadFailedEvent());
    await tester.pump(const Duration(seconds: 39));
    expect(source.count('refreshUnread'), 2);
    await tester.pump(const Duration(seconds: 1));
    expect(source.count('refreshUnread'), 3);

    source
      ..emit(const ChatUnreadEvent({}))
      ..emit(const ChatUnreadFailedEvent());
    await tester.pump(const Duration(seconds: 5));
    expect(source.count('refreshUnread'), 4);
  });

  test('listens and usable', () {
    final prefs = NativeChat.prefs;
    final (chatOn, dmOn, keyOn) = (prefs.inAppEnabled, prefs.dmPush, NativeChat.keyValid.value);
    addTearDown(() {
      prefs
        ..inAppEnabled = chatOn
        ..dmPush = dmOn;
      NativeChat.keyValid.value = keyOn;
    });
    NativeChat.keyValid.value = true;

    prefs
      ..inAppEnabled = false
      ..dmPush = true;
    expect((NativeChat.listens, NativeChat.usable), (true, false));

    prefs.dmPush = false;
    expect(NativeChat.listens, isFalse);

    prefs.inAppEnabled = true;
    expect((NativeChat.listens, NativeChat.usable), (true, true));

    NativeChat.keyValid.value = false;
    expect(NativeChat.listens, isFalse);
  });

  test('the faction emblem gives up after five tries', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    var tries = 0;
    final fetch = NativeChat.fetchEmblem;
    addTearDown(() {
      NativeChat.fetchEmblem = fetch;
      chat.dispose();
    });
    NativeChat.fetchEmblem = () async {
      tries++;
      return null;
    };
    source
      ..emit(const ChatReadyEvent(5))
      ..emit(const ChatRoomsEvent([ChatRoom(id: 'faction', name: 'Faction')]));
    var now = chatNow;
    for (var i = 0; i < 60; i++) {
      NativeChat.askEmblem(chat, now);
      await Future<void>.delayed(Duration.zero);
      now = now.add(const Duration(minutes: 1));
    }
    expect(tries, 5);
  });
}
