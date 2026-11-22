import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/territory_map/city_map_hole.dart';
import 'package:torn_pda/models/territory_map/city_page_data.dart';
import 'package:torn_pda/pages/territory_map/territory_map_page.dart';
import 'package:torn_pda/providers/city_item_prices.dart';
import 'package:torn_pda/providers/city_pda_map_controller.dart';
import 'package:torn_pda/providers/territory_map_controller.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/territory_map/city_map_picture.dart';

const _radius = 20.0;
const _arrivalStart = 0.82;

final _fadeIn = CurveTween(curve: const Interval(0, 0.25));
final _arrivalFade = CurveTween(curve: const Interval(0, 0.6, curve: Curves.easeOut));
final _grow = CurveTween(curve: Curves.fastOutSlowIn);

CityFrame pushCityMapFrame(
  BuildContext context, {
  required CityPageData page,
  required String? hole,
  required Future<Object?> Function(CityItem item) pick,
  required GlobalKey webArea,
  required GlobalKey button,
  required bool arrival,
  required CityItemPrices prices,
}) {
  final navigator = Navigator.of(context);
  final map = context.read<TerritoryMapController>();
  final browser = context.read<WebViewProvider>();
  final mapKey = GlobalKey();
  final lifeHidden = ValueNotifier(false);
  final route = _frameRoute<Object?>(
    origin: _frameOrigin(hole, webArea, button, navigator),
    screenAtOpen: MediaQuery.sizeOf(navigator.context),
    arrival: arrival,
    builder: (_) =>
        TerritoryMapPage(city: page, cityPrices: prices, mapKey: mapKey, lifeHidden: lifeHidden, pickItem: pick),
  );
  map.showPage(page);
  final closed = navigator.push(route);
  // Recoloring repaints a page going away
  unawaited(route.completed.then((_) => map.hidePage(page)));
  unawaited(closed.then((_) => browser.notifyDialogClosed()));
  return (closed: closed, picture: _pictureOnClose(route, mapKey, lifeHidden, map), shown: _entranceOver(route));
}

// Entered, or already going away
Future<void> _entranceOver(ModalRoute<Object?> route) {
  final animation = route.animation!;
  if (animation.isCompleted) return Future.value();
  final over = Completer<void>();
  void listen(AnimationStatus status) {
    if (status == AnimationStatus.forward) return;
    animation.removeStatusListener(listen);
    over.complete();
  }

  animation.addStatusListener(listen);
  return over.future;
}

// Still painted while it shrinks
Future<String?> _pictureOnClose(
  ModalRoute<Object?> route,
  GlobalKey mapKey,
  ValueNotifier<bool> lifeHidden,
  TerritoryMapController map,
) {
  final animation = route.animation!;
  final picture = Completer<String?>();
  Future<String?> take() async {
    lifeHidden.value = true;
    await WidgetsBinding.instance.endOfFrame;
    return cityMapPictureUrl(mapKey);
  }

  void listen(AnimationStatus status) {
    if (status != AnimationStatus.reverse) return;
    animation.removeStatusListener(listen);
    // No picture of a past day
    picture.complete(map.pastDay != null ? null : take().catchError((_) => null));
  }

  animation.addStatusListener(listen);
  return picture.future;
}

Rect _frameOrigin(String? hole, GlobalKey webArea, GlobalKey button, NavigatorState navigator) {
  final space = navigator.context.findRenderObject();
  final web = webArea.currentContext?.findRenderObject();
  if (space is RenderBox && web is RenderBox && web.attached) {
    final rect = cityHoleOnScreen(hole, web.localToGlobal(Offset.zero, ancestor: space) & web.size);
    if (rect != null) return rect;
  }
  // Fullscreen has no button
  final box = button.currentContext?.findRenderObject();
  if (space is RenderBox && box is RenderBox && box.hasSize && box.attached) {
    return box.localToGlobal(Offset.zero, ancestor: space) & box.size;
  }
  final size = MediaQuery.sizeOf(navigator.context);
  return Rect.fromCenter(center: size.center(Offset.zero), width: 40, height: 40);
}

// Non opaque, Torn stays visible around it
PageRouteBuilder<T> _frameRoute<T>({
  required Rect origin,
  required Size screenAtOpen,
  required bool arrival,
  required WidgetBuilder builder,
}) {
  return PageRouteBuilder<T>(
    opaque: false,
    barrierColor: Colors.black38,
    transitionDuration: const Duration(milliseconds: 380),
    reverseTransitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, _, _) => _CityMapFrame(child: builder(context)),
    transitionsBuilder: (context, animation, _, child) {
      final screen = MediaQuery.sizeOf(context);
      final frame = cityFrameRect(screen, MediaQuery.paddingOf(context));
      final entering = arrival && animation.status != AnimationStatus.reverse;
      // Rotated, the old rect is wrong
      final start = entering
          ? Rect.fromCenter(
              center: frame.center,
              width: frame.width * _arrivalStart,
              height: frame.height * _arrivalStart,
            )
          : screen == screenAtOpen
          ? origin
          : Rect.fromCenter(center: frame.center, width: frame.width / 4, height: frame.height / 4);
      final rect = Rect.lerp(start, frame, _grow.evaluate(animation))!;
      final cover = cityFrameCover(rect, frame.size);
      return Stack(
        children: [
          Positioned.fromRect(
            rect: rect,
            child: FadeTransition(
              opacity: animation.drive(entering ? _arrivalFade : _fadeIn),
              child: Material(
                elevation: 10,
                shadowColor: Colors.black54,
                clipBehavior: Clip.antiAlias,
                borderRadius: BorderRadius.circular(_radius),
                child: OverflowBox(
                  alignment: Alignment.topLeft,
                  minWidth: frame.width,
                  maxWidth: frame.width,
                  minHeight: frame.height,
                  maxHeight: frame.height,
                  child: Transform(
                    transform: Matrix4.identity()
                      ..translateByDouble(cover.offset.dx, cover.offset.dy, 0, 1)
                      ..scaleByDouble(cover.scale, cover.scale, 1, 1),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

// Back needs two presses
class _CityMapFrame extends StatefulWidget {
  const _CityMapFrame({required this.child});

  final Widget child;

  @override
  State<_CityMapFrame> createState() => _CityMapFrameState();
}

class _CityMapFrameState extends State<_CityMapFrame> {
  DateTime? _lastBack;

  void _onBack(bool didPop, Object? _) {
    if (didPop) return;
    final now = DateTime.now();
    if (cityBackCloses(_lastBack, now)) {
      Navigator.pop(context);
      return;
    }
    _lastBack = now;
    BotToast.showText(
      text: 'Back again to close',
      contentColor: Colors.grey[700]!,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: _onBack,
      child: MediaQuery(
        data: media.copyWith(
          size: cityFrameRect(media.size, media.padding).size,
          padding: EdgeInsets.zero,
          viewPadding: EdgeInsets.zero,
        ),
        child: widget.child,
      ),
    );
  }
}
