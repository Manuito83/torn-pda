import 'dart:async';

// ignore: depend_on_referenced_packages
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:torn_pda/main.dart' show logAndShowToUser;
import 'package:torn_pda/models/territory_map/city_page_data.dart';
import 'package:torn_pda/providers/city_pda_map_controller.dart';
import 'package:torn_pda/utils/js_snippets/city_map_snippets.dart';
import 'package:torn_pda/utils/js_snippets/js_snippets.dart';
import 'package:torn_pda/utils/js_snippets/remote_snippets.dart';

const _page = '{"time": 1794060914}';

class _FakeWeb extends Fake implements InAppWebViewController {
  _FakeWeb({this.url = 'https://www.torn.com/city.php'});

  final String url;
  Object? data = _page;
  bool holeFits = true;
  Object? rect;
  bool arrived = false;
  final calls = <String>[];
  final pictures = <Object?>[];
  final loads = <String>[];
  final earlyScripts = <UserScript>[];

  late final _names = {
    cityMapPauseJS(paused: true): 'pause',
    cityMapPauseJS(paused: false): 'resume',
    cityMapDataJS(): 'data',
    cityMapRectJS(): 'rect',
    highlightCityItemsJS(): 'rings',
    cityMapCleanJS(hidden: false): 'clean off',
    cityMapCleanJS(hidden: true): 'clean on',
    toggleCityItemsHighlightJS(hidden: true): 'eye off',
    cityMapHoleJS(): 'hole',
    cityMapFocusJS(): 'focus',
  };

  @override
  Future<WebUri?> getUrl() async => WebUri(url);

  @override
  Future<dynamic> evaluateJavascript({required String source, ContentWorld? contentWorld}) async {
    if (source == cityMapArrivedJS) return arrived;
    if (source == cityMapFirstArrivalJS) {
      final first = !arrived;
      arrived = true;
      return first;
    }
    final name = _names[source]!;
    calls.add(name);
    if (name == 'rect') return rect;
    if (name != 'data') return null;
    if (data == null) throw StateError('renderer gone');
    return data;
  }

  @override
  Future<CallAsyncJavaScriptResult?> callAsyncJavaScript({
    required String functionBody,
    Map<String, dynamic> arguments = const {},
    ContentWorld? contentWorld,
  }) async {
    final name = _names[functionBody]!;
    calls.add(name);
    if (name != 'hole') return null;
    pictures.add(arguments['picture']);
    return CallAsyncJavaScriptResult(value: holeFits);
  }

  @override
  Future<void> loadUrl({
    required URLRequest urlRequest,
    Uri? iosAllowingReadAccessTo,
    WebUri? allowingReadAccessTo,
  }) async {
    loads.add('${urlRequest.url}');
  }

  @override
  Future<void> addUserScript({required UserScript userScript}) async => earlyScripts.add(userScript);

  @override
  Future<void> removeUserScriptsByGroupName({required String groupName}) async =>
      earlyScripts.removeWhere((s) => s.groupName == groupName);
}

void main() {
  late _FakeWeb web;
  late bool opens;
  late bool disabled;
  late bool autoOpen;
  late int frames;
  late Completer<Object?> closed;
  late Completer<String?> picture;
  late Completer<void> shown;
  late List<bool> arrivals;
  late List<String> toasts;
  late List<bool> savedClean;
  late List<String> reports;

  CityPdaMapController controller() => CityPdaMapController(
    web: () => web,
    pushFrame: (_, _, _, {required arrival}) {
      frames++;
      arrivals.add(arrival);
      return (closed: closed.future, picture: picture.future, shown: shown.future);
    },
    mayAutoOpen: () => autoOpen,
    toast: toasts.add,
    debugToast: reports.add,
    fetchItems: () async => const [],
    opensAlways: () async => opens,
    mapDisabled: () async => disabled,
    saveMapClean: (value) async => savedClean.add(value),
  );

  setUp(() {
    web = _FakeWeb();
    opens = false;
    disabled = false;
    autoOpen = true;
    frames = 0;
    closed = Completer();
    picture = Completer();
    shown = Completer();
    arrivals = [];
    toasts = [];
    savedClean = [];
    reports = [];
    logAndShowToUser = true;
  });

  tearDown(() => logAndShowToUser = false);

  group('opening fails', () {
    test('unreadable page brings Torn back', () async {
      web.data = 'NOT_READY';
      final map = controller();
      await map.open();
      expect(frames, 0);
      expect(toasts, hasLength(1));
      expect(map.active, isFalse);
      expect(web.calls, containsAllInOrder(['resume', 'rings', 'clean off']));
    });

    test('a read that throws brings Torn back', () async {
      web.data = null;
      await controller().open();
      expect(web.calls, contains('resume'));
    });

    test('already active stays hidden', () async {
      opens = true;
      autoOpen = false;
      final map = controller();
      await map.arrive();
      web.calls.clear();
      web.data = 'NOT_READY';
      await map.open();
      expect(map.active, isTrue);
      expect(web.calls, isNot(contains('resume')));
    });
  });

  group('closing', () {
    test('plain close keeps the picture in the hole', () async {
      final map = controller();
      final opening = map.open();
      await pumpEventQueue();
      expect(frames, 1);
      expect(map.active, isTrue);

      closed.complete(null);
      picture.complete('data:image/png;base64,AA');
      await opening;
      await pumpEventQueue();
      expect(map.active, isTrue);
      expect(web.pictures, contains('data:image/png;base64,AA'));
      expect(web.calls, isNot(contains('resume')));
    });

    test('no picture brings Torn back instead of an empty hole', () async {
      final map = controller();
      final opening = map.open();
      await pumpEventQueue();
      picture.complete(null);
      closed.complete(null);
      await opening;
      expect(map.active, isFalse);
      expect(web.calls.last, 'clean off');
      expect(web.calls, contains('resume'));
    });

    test('a hole that does not fit brings Torn back', () async {
      web.holeFits = false;
      final map = controller();
      final opening = map.open();
      await pumpEventQueue();
      picture.complete('data:image/png;base64,AA');
      closed.complete(null);
      await opening;
      expect(map.active, isFalse);
      expect(web.calls, contains('resume'));
    });

    test('the close says which exit it took and the box it saw', () async {
      web.rect = '{"x":0,"y":56,"w":360,"h":700,"vw":360,"vh":760}';
      web.holeFits = false;
      final map = controller();
      var opening = map.open();
      await pumpEventQueue();
      picture.complete('data:image/png;base64,AA');
      closed.complete(null);
      await opening;
      expect(reports, hasLength(1));
      expect(reports.single, contains("Torn's map back"));
      expect(reports.single, contains('hole refused'));
      expect(reports.single, contains('360x700 at 0,56, page 360x760'));

      web.holeFits = true;
      closed = Completer();
      picture = Completer();
      opening = map.open();
      await pumpEventQueue();
      picture.complete(null);
      closed.complete(null);
      await opening;
      expect(reports.last, contains('no picture'));
    });

    test('a late picture does not bring the hole back', () async {
      final map = controller();
      final opening = map.open();
      await pumpEventQueue();
      closed.complete(CityTornLink('https://www.torn.com/city.php#terrName=QFA'));
      await opening;
      expect(map.active, isFalse);
      expect(web.calls, containsAllInOrder(['resume', 'focus']));

      web.calls.clear();
      picture.complete('data:image/png;base64,AA');
      await pumpEventQueue();
      expect(web.calls, isEmpty);
    });

    test('a link elsewhere loads in the tab', () async {
      final map = controller();
      final opening = map.open();
      await pumpEventQueue();
      closed.complete(CityTornLink('https://www.torn.com/factions.php?step=profile&ID=7'));
      await opening;
      expect(web.loads, ['https://www.torn.com/factions.php?step=profile&ID=7']);
    });
  });

  test('no second frame while one is open', () async {
    final map = controller();
    unawaited(map.open());
    await pumpEventQueue();
    await map.open();
    expect(frames, 1);
  });

  group('arriving', () {
    test('arrival opens the frame first', () async {
      opens = true;
      final map = controller();
      expect(await map.hideForArrival(), isTrue);
      expect(map.arriving, isTrue);
      unawaited(map.arrive());
      await pumpEventQueue();
      expect(map.active, isTrue);
      expect(frames, 1);
      expect(arrivals, [true]);
      expect(web.calls, isNot(contains('hole')));

      shown.complete();
      await pumpEventQueue();
      expect(map.arriving, isFalse);

      picture.complete('data:image/png;base64,AA');
      closed.complete(null);
      await pumpEventQueue();
      expect(web.calls, contains('hole'));
    });

    test('a tap keeps the hole under the frame', () async {
      final map = controller();
      unawaited(map.open());
      await pumpEventQueue();
      expect(arrivals, [false]);
      expect(web.calls, contains('hole'));
    });

    test('an unreadable page on arrival brings Torn back', () async {
      opens = true;
      web.data = 'NOT_READY';
      final map = controller();
      await map.hideForArrival();
      await map.arrive();
      expect(frames, 0);
      expect(map.active, isFalse);
      expect(map.arriving, isFalse);
      expect(web.calls, contains('resume'));
    });

    test('the option off releases an early hide', () async {
      final map = controller();
      expect(await map.hideForArrival(), isFalse);
      expect(map.active, isFalse);
      expect(web.calls, ['resume']);
    });

    test('a frame already open ends the arrival', () async {
      opens = true;
      final map = controller();
      unawaited(map.open());
      await pumpEventQueue();
      await map.hideForArrival();
      await map.arrive();
      expect(map.arriving, isFalse);
      expect(frames, 1);
    });

    test('map off beats open and early hide', () async {
      opens = true;
      disabled = true;
      final map = controller();
      await map.syncEarlyHide();
      expect(map.hidesEarly, isFalse);
      expect(web.earlyScripts, isEmpty);
      expect(await map.hideForArrival(), isFalse);
      await map.arrive();
      expect(frames, 0);
      expect(map.active, isFalse);
    });

    test('the early hide follows the option', () async {
      opens = true;
      final map = controller();
      await map.syncEarlyHide();
      await map.syncEarlyHide();
      expect(map.hidesEarly, isTrue);
      expect(web.earlyScripts.single.groupName, cityMapEarlyHideGroup);

      opens = false;
      await map.syncEarlyHide();
      expect(map.hidesEarly, isFalse);
      expect(web.earlyScripts, isEmpty);
    });

    test('opens once per document', () async {
      opens = true;
      final map = controller();
      unawaited(map.arrive());
      await pumpEventQueue();
      picture.complete(null);
      closed.complete(null);
      await pumpEventQueue();

      await map.arrive();
      expect(frames, 1);

      web.arrived = false;
      closed = Completer();
      picture = Completer();
      unawaited(map.arrive());
      await pumpEventQueue();
      expect(frames, 2);
    });

    test('a late second pass leaves Torn visible', () async {
      opens = true;
      autoOpen = false;
      final map = controller();
      expect(await map.hideForArrival(), isTrue);
      await map.arrive();
      await map.showTornMap();
      web.calls.clear();

      expect(await map.hideForArrival(), isFalse);
      await map.arrive();
      expect(map.active, isFalse);
      expect(web.calls, isEmpty);
    });

    test('no place for the hole brings Torn back', () async {
      opens = true;
      autoOpen = false;
      web.holeFits = false;
      final map = controller();
      await map.arrive();
      expect(map.active, isFalse);
      expect(frames, 0);
      expect(web.calls, contains('resume'));
    });

    test('a tab off screen waits for a tap', () async {
      opens = true;
      autoOpen = false;
      final map = controller();
      await map.arrive();
      expect(map.active, isTrue);
      expect(frames, 0);
    });

    test('without the option Torn comes back', () async {
      opens = true;
      autoOpen = false;
      final map = controller();
      await map.arrive();
      opens = false;
      web.arrived = false;
      await map.arrive();
      expect(map.active, isFalse);
      expect(web.calls, contains('resume'));
    });

    test('a new document resets the eye', () async {
      final map = controller();
      map.toggleItemsOnMap();
      expect(web.calls, ['eye off']);
      await map.arrive();
      expect(map.itemsHidden, isFalse);
    });

    test('not on Torn, nothing is hidden', () async {
      opens = true;
      web = _FakeWeb(url: 'https://city.example.com/city.php');
      final map = controller();
      await map.arrive();
      expect(map.active, isFalse);
      expect(web.calls, isEmpty);
    });
  });

  test('clean view is saved and applied', () async {
    final map = controller();
    map.toggleMapClean();
    expect(map.mapClean, isTrue);
    expect(savedClean, [true]);
    expect(web.calls, ['clean on']);
    await map.showTornMap();
    expect(web.calls.last, 'clean on');
  });

  group('page bridge', () {
    test('Torn opens and goes back', () async {
      final map = controller();
      unawaited(map.onPageAction('open', isMainFrame: true));
      await pumpEventQueue();
      expect(frames, 1);
      picture.complete(null);
      closed.complete(null);
      await pumpEventQueue();
      await map.onPageAction('torn', isMainFrame: true);
      expect(map.active, isFalse);
    });

    test('open while the map is off shows Torn', () async {
      disabled = true;
      await controller().onPageAction('open', isMainFrame: true);
      expect(frames, 0);
      expect(web.calls, contains('resume'));
    });

    test('other sites and frames are ignored', () async {
      await controller().onPageAction('open', isMainFrame: false);
      web = _FakeWeb(url: 'https://city.example.com/city.php');
      await controller().onPageAction('open', isMainFrame: true);
      expect(frames, 0);
      expect(web.calls, isEmpty);
    });
  });
}
