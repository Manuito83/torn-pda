import 'dart:async';
import 'dart:convert';
import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:chopper/chopper.dart' as chopper;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:torn_pda/models/api_v2/torn_v2.swagger.dart';
import 'package:torn_pda/models/chat/chat_models.dart';
import 'package:torn_pda/models/chat/chat_source.dart';
import 'package:torn_pda/providers/api/api_caller.dart';
import 'package:torn_pda/providers/api/api_utils.dart';

final chatNow = DateTime(2026, 10, 14, 12);

class FakeChatSource implements ChatSource {
  FakeChatSource({bool sync = true}) : _events = StreamController<ChatEvent>.broadcast(sync: sync);

  final StreamController<ChatEvent> _events;
  final List<String> calls = [];
  final List<({String roomId, String content, String reqId})> sent = [];
  Object? olderError;

  void emit(ChatEvent event) => _events.add(event);

  int count(String call) => calls.where((c) => c == call || c.startsWith('$call ')).length;

  @override
  bool get available => true;

  @override
  Stream<ChatEvent> get events => _events.stream;

  @override
  Future<void> loadOlder(String roomId, DateTime before) async {
    calls.add('loadOlder $roomId');
    if (olderError != null) throw olderError!;
  }

  @override
  Future<void> send(String roomId, String content, String reqId) async {
    calls.add('send $roomId');
    sent.add((roomId: roomId, content: content, reqId: reqId));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = invocation.memberName.toString().split('"')[1];
    calls.add([name, ...invocation.positionalArguments].join(' '));
    return Future<void>.value();
  }
}

ChatMessage chatMessage(
  String id,
  String roomId, {
  int sender = 2,
  String name = 'Bravo',
  String? text,
  DateTime? at,
  String? reqId,
}) => ChatMessage(
  id: id,
  reqId: reqId,
  roomId: roomId,
  sender: ChatUser(id: sender, name: name),
  content: text ?? 'text $id',
  createdAt: at ?? chatNow,
);

void useTempPathProvider() {
  const channel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory dir;
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    dir = Directory.systemTemp.createTempSync('chat_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (call) async => dir.path,
    );
  });
  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null);
    dir.deleteSync(recursive: true);
  });
}

class FakeApiCaller extends ApiCallerController {
  FakeApiCaller(this.answer);

  final Object? Function(Uri url) answer;
  final List<Uri> urls = [];

  @override
  // ignore: must_call_super
  Future<void> onInit() async {}

  @override
  Future<dynamic> enqueueApiCall<T>({
    ApiSelection_v1? apiSelection,
    String? prefix = '',
    int limit = 100,
    int? from,
    // ignore: non_constant_identifier_names
    ApiSelection_v2? apiSelection_v2,
    Future<chopper.Response<T>> Function(TornV2 client, String apiKey)? apiCall,
    String? forcedApiKey = '',
  }) async {
    if (apiCall == null) {
      final url = Uri.parse('https://api.torn.com/${apiSelection?.name}');
      urls.add(url);
      return answer(url);
    }
    final client = TornV2.create(
      baseUrl: Uri.parse('https://api.torn.com/v2'),
      httpClient: MockClient((request) async {
        urls.add(request.url);
        return http.Response(jsonEncode(answer(request.url) ?? {}), 200);
      }),
    );
    return (await apiCall(client, 'key')).body;
  }
}
