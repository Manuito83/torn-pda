import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/chat/chat_logo_bubble.dart';

enum FeatureDiagramScene {
  dragToApp,
  dragToOtherPanel,
  copyMainTab,
  linkCurrentTab,
  linkNewTab,
  linkTabBehindApp,
  linkNewTabAppSide,
  pipChain,
  pipPlayer,
  chatBubble,
  chatBrowser,
  chatWindow,
  chatLinkPreview,
  chatPlayerCard,
  chatDrawer,
  chatMenuBar,
  chatListReply,
}

const Map<FeatureDiagramScene, String> featureDiagramCaptions = {
  FeatureDiagramScene.dragToApp: "Drag a tab onto the app",
  FeatureDiagramScene.dragToOtherPanel: "Drag a tab to the other panel",
  FeatureDiagramScene.copyMainTab: "Drag the main tab to copy it",
  FeatureDiagramScene.linkCurrentTab: "Open a link from the app in the current tab",
  FeatureDiagramScene.linkNewTab: "Open a link from the app in a new tab",
  FeatureDiagramScene.linkTabBehindApp: "Open a link from the app in the tab behind it",
  FeatureDiagramScene.linkNewTabAppSide: "Open a link from the app in a new tab on its side",
  FeatureDiagramScene.pipChain: "Tap the window icon to watch the chain over other apps",
  FeatureDiagramScene.pipPlayer: "Choose Watch players in the options and tap up to 4 cards",
  FeatureDiagramScene.chatBubble: "Tap the bubble for your chats, then tap one to open it",
  FeatureDiagramScene.chatBrowser: "Tap the chat button in the browser for your chats",
  FeatureDiagramScene.chatWindow: "Open a chat in a small window, then minimize it to a bubble",
  FeatureDiagramScene.chatLinkPreview: "Tap a link to preview it, then open it in a tab",
  FeatureDiagramScene.chatPlayerCard: "Tap a name to see their card and actions",
  FeatureDiagramScene.chatDrawer: "Tap the bubble in the side menu header",
  FeatureDiagramScene.chatMenuBar: "Tap Chat in the side menu for your chats",
  FeatureDiagramScene.chatListReply: "Tap the arrow on a chat to read it and answer from the list",
};

typedef _Palette = ({Color frame, Color panel, Color appBar, Color ink});

class FeatureDiagram extends StatefulWidget {
  const FeatureDiagram({super.key, required this.scenes, this.showCaption});

  final List<FeatureDiagramScene> scenes;
  final bool? showCaption;

  @override
  State<FeatureDiagram> createState() => _FeatureDiagramState();
}

class _FeatureDiagramState extends State<FeatureDiagram> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int _scene = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 5200))
      ..addStatusListener((status) {
        if (status != AnimationStatus.completed || !mounted) return;
        if (widget.scenes.length > 1) setState(() => _scene = (_scene + 1) % widget.scenes.length);
        _controller.forward(from: 0);
      })
      ..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final scene = widget.scenes[_scene % widget.scenes.length];
    final ink = theme.mainText;
    final _Palette palette = (
      frame: theme.canvas,
      panel: theme.cardColor,
      appBar: theme.currentTheme == AppTheme.light
          ? theme.statusBar
          : Color.alphaBlend(ink.withValues(alpha: 0.12), theme.statusBar),
      ink: ink,
    );

    final diagram = AspectRatio(
      aspectRatio: 100 / 62,
      child: RepaintBoundary(
        child: CustomPaint(
          painter: _FeatureDiagramPainter(
            scene: scene,
            animation: MediaQuery.disableAnimationsOf(context) ? const AlwaysStoppedAnimation(0.8) : _controller,
            palette: palette,
          ),
        ),
      ),
    );

    if (!(widget.showCaption ?? widget.scenes.length > 1)) return diagram;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        diagram,
        const SizedBox(height: 6),
        Text(
          featureDiagramCaptions[scene]!,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ink.withValues(alpha: 0.75)),
        ),
      ],
    );
  }
}

double _seg(double t, double from, double to) => Curves.easeInOut.transform(((t - from) / (to - from)).clamp(0, 1));

class _FeatureDiagramPainter extends CustomPainter {
  _FeatureDiagramPainter({required this.scene, required this.animation, required this.palette})
    : super(repaint: animation);

  final FeatureDiagramScene scene;
  final Animation<double> animation;
  final _Palette palette;

  static final Color _blue = Colors.blue[400]!;
  static final Color _link = Colors.green[500]!;
  static final Map<String, Color> _pages = {
    '1': Colors.blueGrey[300]!,
    '2': Colors.teal[300]!,
    '3': Colors.amber[600]!,
    '4': Colors.purple[300]!,
  };

  late double u;

  @override
  void paint(Canvas canvas, Size size) {
    u = size.width / 100;
    final double raw = animation.value;
    final double t = raw >= 0.95 ? 0 : raw;
    final double fade = raw < 0.9 ? 1 : (raw - 0.95).abs() / 0.05;

    canvas.saveLayer(Offset.zero & size, Paint()..color = Color.fromRGBO(0, 0, 0, fade));
    final frame = RRect.fromRectAndRadius((Offset.zero & size).deflate(u * 0.3), Radius.circular(u * 3));
    canvas.drawRRect(frame, Paint()..color = palette.frame);
    canvas.drawRRect(
      frame,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.5
        ..color = palette.ink.withValues(alpha: 0.35),
    );
    final left = Rect.fromLTWH(u * 3, u * 3, u * 45.5, u * 56);
    final right = Rect.fromLTWH(u * 51.5, u * 3, u * 45.5, u * 56);
    if (!const {
      FeatureDiagramScene.pipChain,
      FeatureDiagramScene.pipPlayer,
      FeatureDiagramScene.chatBubble,
      FeatureDiagramScene.chatBrowser,
      FeatureDiagramScene.chatWindow,
      FeatureDiagramScene.chatLinkPreview,
      FeatureDiagramScene.chatPlayerCard,
      FeatureDiagramScene.chatDrawer,
      FeatureDiagramScene.chatMenuBar,
      FeatureDiagramScene.chatListReply,
    }.contains(scene)) {
      canvas.drawLine(
        Offset(u * 50, u * 22),
        Offset(u * 50, u * 40),
        Paint()
          ..strokeWidth = u * 0.6
          ..strokeCap = StrokeCap.round
          ..color = palette.ink.withValues(alpha: 0.3),
      );
    }

    switch (scene) {
      case FeatureDiagramScene.linkCurrentTab ||
          FeatureDiagramScene.linkNewTab ||
          FeatureDiagramScene.linkTabBehindApp ||
          FeatureDiagramScene.linkNewTabAppSide:
        final bool behind =
            scene == FeatureDiagramScene.linkTabBehindApp || scene == FeatureDiagramScene.linkNewTabAppSide;
        final bool newTab = scene == FeatureDiagramScene.linkNewTab || scene == FeatureDiagramScene.linkNewTabAppSide;
        final double tap = _seg(t, 0.28, 0.33);
        final double reveal = behind ? _seg(t, 0.38, 0.52) : 0;
        final double effect = behind ? 0.52 : 0.38;
        final double grow = newTab ? _seg(t, effect, effect + 0.08) : 1;
        final double loadFrom = effect + (newTab ? 0.08 : 0);
        final double load = ((t - loadFrom) / 0.12).clamp(0, 1);
        final double mix = _seg(t, loadFrom + 0.1, loadFrom + 0.16);

        final bool besideGrows = scene == FeatureDiagramScene.linkNewTab;
        _drawBrowser(
          canvas,
          right,
          tabs: besideGrows ? ['1', '2', '3'] : ['1', '2'],
          active: besideGrows && grow > 0.5 ? 2 : 1,
          mainLeading: true,
          growLast: besideGrows ? grow : 1,
          page: behind ? _pages['2']! : Color.lerp(_pages['2'], _link, mix)!,
          pageReplaced: !behind && besideGrows && grow > 0.5 && mix < 1,
          loading: behind ? 0 : load,
        );
        if (behind) {
          final bool grows = scene == FeatureDiagramScene.linkNewTabAppSide;
          _drawBrowser(
            canvas,
            left,
            tabs: grows ? ['3', '4'] : ['3'],
            active: grows && grow > 0.5 ? 1 : 0,
            growLast: grows ? grow : 1,
            page: Color.lerp(_pages['3'], _link, mix)!,
            pageReplaced: grows && grow > 0.5 && mix < 1,
            loading: load,
          );
        }

        final Rect app = behind ? left.shift(Offset(u * 2.4, u * 2.4)) : left;
        if (reveal < 1) {
          _drawApp(canvas, app.shift(Offset(0, reveal * u * 16)), alpha: 1 - reveal, tapped: tap, shadow: behind);
        }

        final Offset target = Offset(app.left + app.width * 0.62, app.top + u * 24);
        final Offset start = Offset(left.right - u * 2, size.height + u * 4);
        _drawFinger(
          canvas,
          Offset.lerp(start, target, _seg(t, 0.1, 0.28))!,
          alpha: _seg(t, 0.1, 0.16) * (1 - _seg(t, 0.36, 0.44)),
          ring: tap > 0 && tap < 1 ? tap : 0,
        );

      case FeatureDiagramScene.dragToApp || FeatureDiagramScene.dragToOtherPanel || FeatureDiagramScene.copyMainTab:
        final double reach = _seg(t, 0.08, 0.22);
        final double hold = _seg(t, 0.22, 0.30);
        final double drag = _seg(t, 0.30, 0.52);
        final double zone = _seg(t, 0.40, 0.46) * (1 - _seg(t, 0.54, 0.60));
        final bool dragging = t >= 0.26 && t < 0.55;
        final bool done = t >= 0.55;
        final double grow = _seg(t, 0.55, 0.61);

        Rect from, to;
        int index;
        String label;
        switch (scene) {
          case FeatureDiagramScene.dragToApp:
            (from, to, index, label) = (right, left, 2, "Open here");
            if (done) {
              _drawBrowser(canvas, left, tabs: ['3'], active: 0, growLast: grow, page: _pages['3']!);
              _drawBrowser(canvas, right, tabs: ['1', '2'], active: 1, mainLeading: true, page: _pages['2']!);
            } else {
              _drawApp(canvas, left);
              _drawBrowser(
                canvas,
                right,
                tabs: ['1', '2', '3'],
                active: 2,
                mainLeading: true,
                page: _pages['3']!,
                lifted: dragging ? 2 : null,
              );
            }
          case FeatureDiagramScene.dragToOtherPanel:
            (from, to, index, label) = (right, left, 1, "Move here");
            _drawBrowser(
              canvas,
              left,
              tabs: done ? ['1', '2', '4'] : ['1', '2'],
              active: done ? 2 : 1,
              mainLeading: true,
              growLast: done ? grow : 1,
              page: done ? _pages['4']! : _pages['2']!,
            );
            _drawBrowser(
              canvas,
              right,
              tabs: done ? ['3'] : ['3', '4'],
              active: done ? 0 : 1,
              page: done ? _pages['3']! : _pages['4']!,
              lifted: dragging ? 1 : null,
            );
          default:
            (from, to, index, label) = (left, right, 0, "Copy here");
            _drawBrowser(canvas, left, tabs: ['1', '2'], active: 0, mainLeading: true, page: _pages['1']!);
            _drawBrowser(
              canvas,
              right,
              tabs: done ? ['3', '1'] : ['3'],
              active: done ? 1 : 0,
              growLast: done ? grow : 1,
              page: done ? _pages['1']! : _pages['3']!,
            );
        }

        if (zone > 0) _drawZone(canvas, to, alpha: zone, label: label);

        final Rect chip = _chipRect(from, index, mainLeading: true);
        final Offset target = to.center.translate(0, -u * 2);
        final Offset finger = drag > 0
            ? Offset.lerp(chip.center, target, drag)!
            : Offset.lerp(Offset(chip.center.dx + u * 6, size.height + u * 6), chip.center, reach)!;
        if (dragging) {
          final Rect ghost = Rect.fromCenter(
            center: finger.translate(0, -u * 7 * hold),
            width: chip.width * (1 + 0.15 * hold),
            height: chip.height * (1 + 0.15 * hold),
          );
          canvas.drawShadow(
            Path()..addRRect(RRect.fromRectAndRadius(ghost, Radius.circular(u))),
            Colors.black,
            u,
            false,
          );
          _drawChip(
            canvas,
            ghost,
            scene == FeatureDiagramScene.dragToApp ? '3' : (scene == FeatureDiagramScene.copyMainTab ? '1' : '4'),
            active: true,
            solid: true,
          );
        }
        _drawFinger(
          canvas,
          finger,
          alpha: _seg(t, 0.08, 0.12) * (1 - _seg(t, 0.56, 0.62)),
          ring: hold > 0 && hold < 1 ? hold : 0,
        );
      case FeatureDiagramScene.pipChain:
        final Rect full = Rect.fromLTWH(u * 3, u * 3, u * 94, u * 56);
        final Rect small = Rect.fromLTWH(u * 56, u * 34, u * 38, u * 22.6);
        final double tap = _seg(t, 0.2, 0.26);
        final double shrink = _seg(t, 0.36, 0.52);
        final double swap = _seg(t, 0.44, 0.54);
        final Rect now = Rect.lerp(full, small, shrink)!;
        final Offset icon = Offset(u * 90, u * 27);

        if (shrink > 0) {
          _drawOtherApp(canvas, full, alpha: shrink);
          canvas.drawShadow(
            Path()..addRRect(RRect.fromRectAndRadius(now, Radius.circular(u * 1.5))),
            Colors.black,
            u * 1.5 * shrink,
            false,
          );
        }
        if (swap < 1) {
          canvas.save();
          canvas.translate(now.left, now.top);
          canvas.scale(now.width / full.width);
          _drawApp(canvas, full.shift(-full.topLeft), alpha: 1 - swap, tapped: tap);
          _drawIcon(
            canvas,
            Icons.picture_in_picture_alt,
            icon - full.topLeft,
            u * 7,
            _blue.withValues(alpha: 1 - swap),
          );
          canvas.restore();
        }
        if (swap > 0) {
          canvas.save();
          canvas.translate(now.left, now.top);
          canvas.scale(now.width / (u * 38));
          _drawPipWindow(canvas, player: false, t: t, alpha: swap);
          canvas.restore();
        }

        _drawFinger(
          canvas,
          Offset.lerp(Offset(full.right - u * 2, size.height + u * 4), icon, _seg(t, 0.08, 0.2))!,
          alpha: _seg(t, 0.08, 0.13) * (1 - _seg(t, 0.28, 0.34)),
          ring: tap > 0 && tap < 1 ? tap : 0,
        );
      case FeatureDiagramScene.pipPlayer:
        final Rect full = Rect.fromLTWH(u * 3, u * 3, u * 94, u * 56);
        final Rect small = Rect.fromLTWH(u * 56, u * 34, u * 38, u * 22.6);
        final Offset gear = Offset(u * 90, u * 7);
        final Rect menu = Rect.fromLTWH(full.right - u * 38, full.top + u * 6, u * 36, u * 21);
        final Offset item = Offset(menu.left + u * 18, menu.top + u * 16.5);
        final Offset watch = Offset(full.right - u * 10, full.top + u * 4);
        Rect card(int i) =>
            Rect.fromLTWH(full.left + u * 3, full.top + u * 11 + i * u * 9.5, full.width - u * 6, u * 7);
        Offset box(int i) => Offset(card(i).left + u * 3.5, card(i).center.dy);
        final double tapGear = _seg(t, 0.12, 0.17);
        final double menuIn = _seg(t, 0.18, 0.22) * (1 - _seg(t, 0.3, 0.33));
        final double tapItem = _seg(t, 0.26, 0.3);
        final double selecting = _seg(t, 0.31, 0.35);
        final List<double> checks = [_seg(t, 0.4, 0.43), 0, _seg(t, 0.48, 0.51), 0];
        final double tapWatch = _seg(t, 0.56, 0.6);
        final double shrink = _seg(t, 0.64, 0.76);
        final double swap = _seg(t, 0.7, 0.78);
        final Rect now = Rect.lerp(full, small, shrink)!;

        if (shrink > 0) {
          _drawOtherApp(canvas, full, alpha: shrink);
          canvas.drawShadow(
            Path()..addRRect(RRect.fromRectAndRadius(now, Radius.circular(u * 1.5))),
            Colors.black,
            u * 1.5 * shrink,
            false,
          );
        }
        if (swap < 1) {
          canvas.save();
          canvas.translate(now.left, now.top);
          canvas.scale(now.width / full.width);
          canvas.translate(-full.left, -full.top);
          canvas.saveLayer(full.inflate(u * 3), Paint()..color = Color.fromRGBO(0, 0, 0, 1 - swap));
          _drawApp(canvas, full);
          _drawIcon(canvas, Icons.settings, gear, u * 5, Colors.white.withValues(alpha: 1 - selecting));
          canvas.save();
          canvas.clipRRect(RRect.fromRectAndRadius(full, Radius.circular(u * 1.5)));
          if (selecting > 0) {
            canvas.drawRect(
              Rect.fromLTWH(full.left, full.top, full.width, u * 8),
              Paint()..color = palette.appBar.withValues(alpha: selecting),
            );
            _drawIcon(canvas, Icons.close, Offset(full.left + u * 5, full.top + u * 4), u * 5, Colors.white);
            final int picked = checks.where((c) => c >= 1).length;
            _drawLabel(
              canvas,
              picked == 0 ? "Watch" : "Watch $picked",
              watch,
              u * 3.4,
              Colors.white.withValues(alpha: (picked == 0 ? 0.5 : 1) * selecting),
            );
            for (var i = 0; i < 4; i++) {
              if (checks[i] > 0) {
                canvas.drawRRect(
                  RRect.fromRectAndRadius(card(i), Radius.circular(u)),
                  Paint()..color = _blue.withValues(alpha: 0.25 * checks[i]),
                );
              }
              final square = Rect.fromCenter(center: box(i), width: u * 3.4, height: u * 3.4);
              canvas.drawRRect(
                RRect.fromRectAndRadius(square, Radius.circular(u * 0.6)),
                Paint()..color = palette.panel.withValues(alpha: selecting),
              );
              canvas.drawRRect(
                RRect.fromRectAndRadius(square, Radius.circular(u * 0.6)),
                Paint()
                  ..style = PaintingStyle.stroke
                  ..strokeWidth = u * 0.5
                  ..color = palette.ink.withValues(alpha: 0.5 * selecting),
              );
              if (checks[i] > 0) {
                canvas.drawRRect(
                  RRect.fromRectAndRadius(square, Radius.circular(u * 0.6)),
                  Paint()..color = _blue.withValues(alpha: checks[i]),
                );
              }
            }
          }
          if (menuIn > 0) {
            final shape = RRect.fromRectAndRadius(menu, Radius.circular(u));
            canvas.drawShadow(Path()..addRRect(shape), Colors.black, u * menuIn, false);
            canvas.drawRRect(shape, Paint()..color = palette.panel.withValues(alpha: menuIn));
            for (var i = 0; i < 3; i++) {
              final double y = menu.top + u * (4 + i * 6.25);
              final bool pip = i == 2;
              if (pip && tapItem > 0) {
                canvas.drawRect(
                  Rect.fromLTWH(menu.left, y - u * 3, menu.width, u * 6),
                  Paint()..color = _blue.withValues(alpha: 0.3 * menuIn),
                );
              }
              _drawIcon(
                canvas,
                pip ? Icons.picture_in_picture_alt : Icons.circle,
                Offset(menu.left + u * 4, y),
                u * (pip ? 3.6 : 2),
                palette.ink.withValues(alpha: (pip ? 0.9 : 0.3) * menuIn),
              );
              if (pip) {
                _drawLabel(
                  canvas,
                  "Watch players",
                  Offset(menu.left + u * 20, y),
                  u * 3,
                  palette.ink.withValues(alpha: menuIn),
                );
              } else {
                canvas.drawRRect(
                  RRect.fromRectAndRadius(
                    Rect.fromLTWH(menu.left + u * 8, y - u, u * (i == 0 ? 20 : 16), u * 2),
                    Radius.circular(u),
                  ),
                  Paint()..color = palette.ink.withValues(alpha: 0.25 * menuIn),
                );
              }
            }
          }
          canvas.restore();
          canvas.restore();
          canvas.restore();
        }
        if (swap > 0) {
          canvas.save();
          canvas.translate(now.left, now.top);
          canvas.scale(now.width / (u * 38));
          _drawPipWindow(canvas, player: true, t: t, alpha: swap);
          canvas.restore();
        }

        final Offset finger;
        if (t < 0.18) {
          finger = Offset.lerp(Offset(full.right - u * 2, size.height + u * 4), gear, _seg(t, 0.04, 0.12))!;
        } else if (t < 0.31) {
          finger = Offset.lerp(gear, item, _seg(t, 0.19, 0.25))!;
        } else if (t < 0.44) {
          finger = Offset.lerp(item, card(0).center, _seg(t, 0.34, 0.39))!;
        } else if (t < 0.52) {
          finger = Offset.lerp(card(0).center, card(2).center, _seg(t, 0.43, 0.47))!;
        } else {
          finger = Offset.lerp(card(2).center, watch, _seg(t, 0.51, 0.55))!;
        }
        final double ring = [
          tapGear,
          tapItem,
          checks[0],
          checks[2],
          tapWatch,
        ].firstWhere((v) => v > 0 && v < 1, orElse: () => 0);
        _drawFinger(canvas, finger, alpha: _seg(t, 0.04, 0.08) * (1 - _seg(t, 0.6, 0.64)), ring: ring);
      case FeatureDiagramScene.chatBubble || FeatureDiagramScene.chatBrowser:
        final bool browser = scene == FeatureDiagramScene.chatBrowser;
        final Rect full = Rect.fromLTWH(u * 3, u * 3, u * 94, u * 56);
        final Offset bubble = browser ? Offset(full.right - u * 13, full.top + u * 4) : Offset(u * 89, u * 50);
        final double tapBubble = _seg(t, 0.15, 0.2);
        final double open = _seg(t, 0.22, 0.34);
        final double tapRow = _seg(t, 0.48, 0.53);
        final double slide = _seg(t, 0.56, 0.68);

        if (browser) {
          _drawBrowser(canvas, full, tabs: const [], active: 0, page: _pages['1']!);
          canvas.save();
          canvas.clipRRect(RRect.fromRectAndRadius(full, Radius.circular(u * 1.5)));
          canvas.drawRect(Rect.fromLTWH(full.left, full.top, full.width, u * 8), Paint()..color = palette.appBar);
          final white = Colors.white.withValues(alpha: 0.9);
          canvas.drawRect(Rect.fromLTWH(full.left + u * 3, full.top + u * 3.4, u * 18, u * 1.2), Paint()..color = white);
          _drawIcon(canvas, Icons.refresh_rounded, Offset(full.right - u * 5, bubble.dy), u * 4.6, white);
          _drawIcon(canvas, Icons.inventory_2_outlined, Offset(full.right - u * 21, bubble.dy), u * 4.2, white);
          _drawIcon(canvas, Icons.chat_bubble_outline_rounded, bubble, u * 4.6, white);
          if (open == 0) {
            final Offset badge = bubble + Offset(u * 2.4, -u * 1.8);
            canvas.drawCircle(badge, u * 1.9, Paint()..color = Colors.red[400]!);
            _drawLabel(canvas, "3", badge, u * 2.5, Colors.white);
          }
          canvas.restore();
        } else {
          _drawApp(canvas, full);
        }
        if (open > 0 && slide < 1) {
          final Rect now = Rect.lerp(Rect.fromCenter(center: bubble, width: u * 9.4, height: u * 5.6), full, open)!;
          final shape = RRect.fromRectAndRadius(full, Radius.circular(u * 1.5));
          canvas.save();
          canvas.translate(now.left, now.top);
          canvas.scale(now.width / full.width);
          canvas.translate(-full.left, -full.top);
          canvas.saveLayer(full.inflate(u * 3), Paint()..color = Color.fromRGBO(0, 0, 0, open));
          canvas.drawShadow(Path()..addRRect(shape), Colors.black, u * 1.5, false);
          _drawChatList(canvas, full, tapRow: tapRow);
          canvas.restore();
          canvas.restore();
        }
        if (slide > 0) {
          canvas.save();
          canvas.clipRRect(RRect.fromRectAndRadius(full, Radius.circular(u * 1.5)));
          _drawChat(canvas, full.shift(Offset(full.width * (1 - slide), 0)));
          canvas.restore();
        }
        if (!browser) _drawChatBubble(canvas, bubble, alpha: 1 - open);

        final Offset finger = t < 0.36
            ? Offset.lerp(Offset(full.right - u * 2, size.height + u * 4), bubble, _seg(t, 0.04, 0.14))!
            : Offset.lerp(bubble, _chatRow(full, 1).center, _seg(t, 0.38, 0.46))!;
        _drawFinger(
          canvas,
          finger,
          alpha: _seg(t, 0.04, 0.08) * (1 - _seg(t, 0.56, 0.62)),
          ring: [tapBubble, tapRow].firstWhere((v) => v > 0 && v < 1, orElse: () => 0),
        );
      case FeatureDiagramScene.chatListReply:
        final Rect full = Rect.fromLTWH(u * 3, u * 3, u * 94, u * 56);
        final Rect first = _chatRow(full, 0);
        final Rect box = _replyBox(full);
        final Offset arrow = Offset(first.right - u * 4, first.center.dy);
        final Offset field = Offset(box.left + u * 10, box.center.dy);
        final Offset send = Offset(box.right + u * 3.5, box.center.dy);
        final double tapArrow = _seg(t, 0.15, 0.2);
        final double tapField = _seg(t, 0.44, 0.48);
        final double tapSend = _seg(t, 0.68, 0.72);

        _drawChatList(canvas, full, reply: _seg(t, 0.22, 0.34), typed: _seg(t, 0.48, 0.62), sent: _seg(t, 0.72, 0.8));
        final Offset finger = t < 0.36
            ? Offset.lerp(Offset(full.right - u * 10, size.height + u * 4), arrow, _seg(t, 0.04, 0.14))!
            : t < 0.62
            ? Offset.lerp(arrow, field, _seg(t, 0.36, 0.43))!
            : Offset.lerp(field, send, _seg(t, 0.62, 0.67))!;
        _drawFinger(
          canvas,
          finger,
          alpha: _seg(t, 0.04, 0.08) * (1 - _seg(t, 0.8, 0.86)),
          ring: [tapArrow, tapField, tapSend].firstWhere((v) => v > 0 && v < 1, orElse: () => 0),
        );
      case FeatureDiagramScene.chatWindow:
        final Rect full = Rect.fromLTWH(u * 3, u * 3, u * 94, u * 56);
        final Rect window = Rect.fromLTWH(u * 7, u * 8, u * 62.7, u * 37.35);
        final double scale = window.width / full.width;
        final Offset pip = Offset(full.right - u * 10, full.top + u * 4);
        final Offset minimize = Offset(window.left + (full.width - u * 16) * scale, window.top + u * 4 * scale);
        final Offset bubble = Offset(u * 89, u * 50);
        final Offset mini = Offset(u * 89, u * 39);
        final double tapPip = _seg(t, 0.15, 0.2);
        final double shrink = _seg(t, 0.24, 0.38);
        final double tapMin = _seg(t, 0.54, 0.59);
        final double collapse = _seg(t, 0.62, 0.74);

        _drawApp(canvas, full);
        _drawChatBubble(canvas, bubble, alpha: _seg(t, 0.32, 0.4));
        if (collapse < 1) {
          final Rect now = Rect.lerp(
            Rect.lerp(full, window, shrink)!,
            Rect.fromCircle(center: mini, radius: u * 3),
            collapse,
          )!;
          final shape = RRect.fromRectAndRadius(now, Radius.circular(u * (1.5 + 1.5 * collapse)));
          if (shrink > 0) canvas.drawShadow(Path()..addRRect(shape), Colors.black, u * 1.5 * shrink, false);
          canvas.save();
          canvas.clipRRect(shape);
          canvas.saveLayer(now, Paint()..color = Color.fromRGBO(0, 0, 0, 1 - collapse));
          canvas.translate(now.left, now.top);
          canvas.scale(now.width / full.width);
          _drawChat(canvas, full.shift(-full.topLeft));
          canvas.restore();
          canvas.drawRRect(shape, Paint()..color = _pages['2']!.withValues(alpha: collapse));
          canvas.restore();
        } else {
          canvas.drawShadow(Path()..addOval(Rect.fromCircle(center: mini, radius: u * 3)), Colors.black, u, false);
          canvas.drawCircle(mini, u * 3, Paint()..color = _pages['2']!);
        }
        if (collapse > 0.6) {
          _drawIcon(canvas, Icons.person_rounded, mini, u * 4, Colors.white.withValues(alpha: _seg(collapse, 0.6, 1)));
        }

        final Offset finger = t < 0.4
            ? Offset.lerp(Offset(full.right - u * 2, size.height + u * 4), pip, _seg(t, 0.04, 0.14))!
            : Offset.lerp(pip, minimize, _seg(t, 0.42, 0.52))!;
        _drawFinger(
          canvas,
          finger,
          alpha: _seg(t, 0.04, 0.08) * (1 - _seg(t, 0.62, 0.68)),
          ring: [tapPip, tapMin].firstWhere((v) => v > 0 && v < 1, orElse: () => 0),
        );
      case FeatureDiagramScene.chatLinkPreview:
        final Rect full = Rect.fromLTWH(u * 3, u * 3, u * 94, u * 56);
        final Offset link = Offset(full.left + u * 20, full.top + u * 35.7);
        final Rect preview = Rect.fromLTWH(u * 14, u * 8, u * 72, u * 46);
        final Rect mainTab = Rect.fromLTWH(preview.center.dx - u * 32, preview.bottom - u * 8, u * 30, u * 6);
        final Rect newTab = Rect.fromLTWH(preview.center.dx + u * 2, preview.bottom - u * 8, u * 30, u * 6);
        final double tapLink = _seg(t, 0.15, 0.2);
        final double open = _seg(t, 0.22, 0.32);
        final double load = ((t - 0.3) / 0.12).clamp(0, 1);
        final double tapNew = _seg(t, 0.56, 0.61);
        final double move = _seg(t, 0.64, 0.72);
        final double swap = _seg(t, 0.72, 0.78);
        final double grow = _seg(t, 0.76, 0.84);
        final ink = palette.ink;

        _drawChat(canvas, full, linkTap: tapLink);
        if (move >= 1) {
          _drawBrowser(
            canvas,
            full,
            tabs: ['1', '2', '3'],
            active: grow > 0.5 ? 2 : 1,
            mainLeading: true,
            growLast: grow,
            page: Color.lerp(_pages['2'], _link, grow)!,
          );
        }
        if (open > 0 && swap < 1) {
          final Rect now = move > 0
              ? Rect.lerp(preview, full, move)!
              : Rect.lerp(Rect.fromCenter(center: link, width: u * 7.2, height: u * 4.6), preview, open)!;
          final shape = RRect.fromRectAndRadius(preview, Radius.circular(u * 1.5));
          canvas.save();
          canvas.translate(now.left, now.top);
          canvas.scale(now.width / preview.width, now.height / preview.height);
          canvas.translate(-preview.left, -preview.top);
          canvas.saveLayer(preview.inflate(u * 3), Paint()..color = Color.fromRGBO(0, 0, 0, open * (1 - swap)));
          canvas.drawShadow(Path()..addRRect(shape), Colors.black, u * 1.5, false);
          canvas.drawRRect(shape, Paint()..color = palette.panel);
          canvas.save();
          canvas.clipRRect(shape);
          canvas.drawRect(
            Rect.fromLTWH(preview.left, preview.top, preview.width, u * 7),
            Paint()..color = Color.alphaBlend(ink.withValues(alpha: 0.08), palette.panel),
          );
          _drawIcon(
            canvas,
            Icons.arrow_back_rounded,
            Offset(preview.left + u * 4, preview.top + u * 3.5),
            u * 4,
            ink.withValues(alpha: 0.4),
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(preview.left + u * 9, preview.top + u * 1.8, u * 24, u * 1.6),
              Radius.circular(u),
            ),
            Paint()..color = ink.withValues(alpha: 0.5),
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(preview.left + u * 9, preview.top + u * 4.3, u * 14, u * 1.2),
              Radius.circular(u),
            ),
            Paint()..color = ink.withValues(alpha: 0.25),
          );
          _drawIcon(
            canvas,
            Icons.open_in_full_rounded,
            Offset(preview.right - u * 10, preview.top + u * 3.5),
            u * 3.6,
            ink.withValues(alpha: 0.7),
          );
          _drawIcon(
            canvas,
            Icons.close_rounded,
            Offset(preview.right - u * 4, preview.top + u * 3.5),
            u * 4,
            ink.withValues(alpha: 0.7),
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(preview.left + u * 3, preview.top + u * 10, preview.width - u * 6, u * 12),
              Radius.circular(u),
            ),
            Paint()..color = _link,
          );
          for (var i = 0; i < 3; i++) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(
                  preview.left + u * 3,
                  preview.top + u * (25 + i * 4.5),
                  (preview.width - u * 6) * (i.isEven ? 0.85 : 0.6),
                  u * 2,
                ),
                Radius.circular(u),
              ),
              Paint()..color = ink.withValues(alpha: 0.14),
            );
          }
          if (load > 0 && load < 1) {
            canvas.drawRect(
              Rect.fromLTWH(preview.left, preview.top + u * 7, preview.width * load, u * 0.9),
              Paint()..color = _blue,
            );
          }
          for (final (rect, icon, label, tapped) in [
            (mainTab, Icons.tab_rounded, "Main tab", 0.0),
            (newTab, Icons.add_box_outlined, "New tab", tapNew),
          ]) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(rect, Radius.circular(u * 1.5)),
              Paint()..color = _blue.withValues(alpha: 0.12 + 0.3 * tapped),
            );
            _drawIcon(canvas, icon, Offset(rect.left + u * 5, rect.center.dy), u * 3.6, _blue);
            _drawLabel(canvas, label, rect.center.translate(u * 2.5, 0), u * 3.2, _blue);
          }
          canvas.restore();
          canvas.restore();
          canvas.restore();
        }

        final Offset finger = t < 0.4
            ? Offset.lerp(Offset(full.right - u * 20, size.height + u * 4), link, _seg(t, 0.04, 0.14))!
            : Offset.lerp(link, newTab.center, _seg(t, 0.44, 0.52))!;
        _drawFinger(
          canvas,
          finger,
          alpha: _seg(t, 0.04, 0.08) * (1 - _seg(t, 0.62, 0.68)),
          ring: [tapLink, tapNew].firstWhere((v) => v > 0 && v < 1, orElse: () => 0),
        );
      case FeatureDiagramScene.chatPlayerCard:
        final Rect full = Rect.fromLTWH(u * 3, u * 3, u * 94, u * 56);
        final Offset name = Offset(full.left + u * 11, full.top + u * 14);
        final double tapName = _seg(t, 0.15, 0.2);
        final double up = _seg(t, 0.22, 0.34);
        final double tapAttack = _seg(t, 0.56, 0.61);
        final Rect sheet = Rect.fromLTWH(full.left, full.bottom - u * 36 * up, full.width, u * 36);
        Offset action(int i) => Offset(sheet.left + u * (10 + i * 14.8), sheet.top + u * 23);
        final ink = palette.ink;

        _drawChat(canvas, full, nameTap: tapName);
        if (up > 0) {
          final shape = RRect.fromRectAndRadius(full, Radius.circular(u * 1.5));
          final card = RRect.fromRectAndCorners(
            sheet,
            topLeft: Radius.circular(u * 3),
            topRight: Radius.circular(u * 3),
          );
          canvas.save();
          canvas.clipRRect(shape);
          canvas.drawRRect(shape, Paint()..color = Colors.black.withValues(alpha: 0.35 * up));
          canvas.drawShadow(Path()..addRRect(card), Colors.black, u * 1.5, false);
          canvas.drawRRect(card, Paint()..color = palette.panel);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(center: Offset(sheet.center.dx, sheet.top + u * 2.2), width: u * 8, height: u),
              Radius.circular(u),
            ),
            Paint()..color = ink.withValues(alpha: 0.3),
          );
          final Offset avatar = Offset(sheet.left + u * 10, sheet.top + u * 10);
          canvas.drawCircle(avatar, u * 4.5, Paint()..color = Colors.orange[400]!);
          _drawIcon(canvas, Icons.person_rounded, avatar, u * 5.5, Colors.white);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromLTWH(sheet.left + u * 18, sheet.top + u * 5.5, u * 22, u * 2.2),
              Radius.circular(u),
            ),
            Paint()..color = ink.withValues(alpha: 0.6),
          );
          _drawLabel(
            canvas,
            "Hospital",
            Offset(sheet.left + u * 25.5, sheet.top + u * 10.5),
            u * 3.4,
            Colors.red[400]!,
          );
          for (final (x, y, w) in [(35.0, 9.5, 16.0), (18.0, 14.0, 30.0)]) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(
                Rect.fromLTWH(sheet.left + u * x, sheet.top + u * y, u * w, u * 2),
                Radius.circular(u),
              ),
              Paint()..color = ink.withValues(alpha: 0.2),
            );
          }
          for (final (i, (icon, label)) in [
            (Icons.chat_rounded, "Chat"),
            (Icons.person_rounded, "Profile"),
            (MdiIcons.pistol, "Attack"),
            (Icons.swap_horiz_rounded, "Trade"),
            (Icons.storefront_rounded, "Bazaar"),
            (Icons.email_rounded, "Mail"),
          ].indexed) {
            canvas.drawCircle(
              action(i),
              u * 3.6,
              Paint()
                ..color = i == 2 && tapAttack > 0
                    ? Color.lerp(ink.withValues(alpha: 0.08), _blue.withValues(alpha: 0.45), tapAttack)!
                    : ink.withValues(alpha: 0.08),
            );
            _drawIcon(canvas, icon, action(i), u * 4, ink.withValues(alpha: 0.75));
            _drawLabel(canvas, label, action(i).translate(0, u * 6), u * 2.8, ink.withValues(alpha: 0.75));
          }
          canvas.restore();
        }

        final Offset finger = t < 0.4
            ? Offset.lerp(Offset(full.left + u * 30, size.height + u * 4), name, _seg(t, 0.04, 0.14))!
            : Offset.lerp(name, action(2), _seg(t, 0.44, 0.52))!;
        _drawFinger(
          canvas,
          finger,
          alpha: _seg(t, 0.04, 0.08) * (1 - _seg(t, 0.62, 0.68)),
          ring: [tapName, tapAttack].firstWhere((v) => v > 0 && v < 1, orElse: () => 0),
        );
      case FeatureDiagramScene.chatDrawer || FeatureDiagramScene.chatMenuBar:
        final bool bar = scene == FeatureDiagramScene.chatMenuBar;
        final Rect full = Rect.fromLTWH(u * 3, u * 3, u * 94, u * 56);
        final Offset menu = Offset(full.left + u * 5, full.top + u * 4);
        final double tapMenu = _seg(t, 0.15, 0.2);
        final double tapBubble = _seg(t, 0.5, 0.55);
        final double slide = _seg(t, 0.58, 0.7);
        final double open = _seg(t, 0.22, 0.32) * (1 - slide);
        final Rect drawer = Rect.fromLTWH(full.left - u * 46 * (1 - open), full.top, u * 46, full.height);
        final double side = u * (bar ? 30 : 34);
        final Rect logo = Rect.fromLTWH(drawer.center.dx - side / 2, drawer.top + u * 2, side, side);
        Offset at(double x, double y) => logo.topLeft + Offset(logo.width * x, logo.height * y);
        final Offset bubble = at(0.8, 0.36);
        final double radius = logo.width * 0.16;
        final ink = palette.ink;
        final shape = RRect.fromRectAndRadius(full, Radius.circular(u * 1.5));
        final Rect chatBar = Rect.fromLTWH(drawer.left + u * 4, logo.bottom + u * 1.5, drawer.width - u * 8, u * 5);
        final Offset target = bar ? Offset(chatBar.left + u * 9, chatBar.center.dy) : bubble;

        _drawApp(canvas, full);
        if (open > 0) {
          canvas.save();
          canvas.clipRRect(shape);
          canvas.drawRRect(shape, Paint()..color = Colors.black.withValues(alpha: 0.35 * open));
          canvas.drawShadow(Path()..addRect(drawer), Colors.black, u * 1.5, false);
          canvas.drawRect(drawer, Paint()..color = palette.panel);
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromPoints(at(0.12, 0.015), at(0.88, 0.97)),
              Radius.circular(logo.width * 0.1),
            ),
            Paint()..color = const Color(0xFF8E8E8E),
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromPoints(at(0.215, 0.11), at(0.786, 0.715)), Radius.circular(u * 0.5)),
            Paint()..color = const Color(0xFF3A3A3A),
          );
          final hat = Paint()..color = const Color(0xFFD0D0D0);
          canvas.drawOval(Rect.fromPoints(at(0.28, 0.25), at(0.72, 0.37)), hat);
          canvas.drawRRect(
            RRect.fromRectAndRadius(Rect.fromPoints(at(0.38, 0.14), at(0.63, 0.29)), Radius.circular(u * 1.2)),
            hat,
          );
          canvas.drawRect(
            Rect.fromPoints(at(0.375, 0.255), at(0.635, 0.285)),
            Paint()..color = const Color(0xFF3A3A3A),
          );
          for (final points in [
            [at(0.389, 0.542), at(0.441, 0.687), at(0.457, 0.615)],
            [at(0.593, 0.542), at(0.539, 0.687), at(0.513, 0.617)],
          ]) {
            canvas.drawPath(Path()..addPolygon(points, true), hat);
          }
          canvas.drawPath(
            Path()
              ..moveTo(at(0.445, 0.515).dx, at(0.445, 0.515).dy)
              ..quadraticBezierTo(at(0.48, 0.495).dx, at(0.48, 0.495).dy, at(0.52, 0.515).dx, at(0.52, 0.515).dy),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = u * 0.6
              ..strokeCap = StrokeCap.round
              ..color = const Color(0xFFD0D0D0),
          );
          for (final (x, y, r) in [(0.29, 0.84, 0.047), (0.5, 0.85, 0.064), (0.69, 0.84, 0.047)]) {
            canvas.drawCircle(at(x, y), logo.width * r, Paint()..color = const Color(0xFF444444));
          }
          final dots = [(_blue, '2'), (Colors.amber[600]!, '1'), (Colors.red[400]!, '3')];
          if (bar) {
            canvas.drawRRect(
              RRect.fromRectAndRadius(chatBar, Radius.circular(chatBar.height / 2)),
              Paint()..color = Color.lerp(_blue, Colors.white, tapBubble * (1 - tapBubble) * 1.6)!,
            );
            _drawIcon(
              canvas,
              Icons.forum_rounded,
              Offset(chatBar.left + u * 3.2, chatBar.center.dy),
              u * 3,
              Colors.white,
            );
            _drawLabel(canvas, "Chat", Offset(chatBar.left + u * 9, chatBar.center.dy), u * 2.8, Colors.white);
            for (final (i, (color, n)) in dots.indexed) {
              final Offset dot = Offset(chatBar.right - u * (12.2 - i * 4.6), chatBar.center.dy);
              canvas.drawCircle(dot, u * 2, Paint()..color = palette.panel);
              canvas.drawCircle(dot, u * 1.7, Paint()..color = color);
              _drawLabel(canvas, n, dot, u * 2.3, Colors.white);
            }
          } else {
            final outline = chatSpeechBubble(bubble, radius, at(0.52, 0.52));
            canvas.drawShadow(outline, Colors.black, u, false);
            canvas.drawPath(outline, Paint()..color = _blue);
            _drawIcon(canvas, Icons.forum_rounded, bubble, radius * 1.1, Colors.white);
            for (final (i, (color, n)) in dots.indexed) {
              final Offset dot = bubble + Offset.fromDirection((i - 1) * 0.73, radius + u * 1.4);
              canvas.drawCircle(dot, u * 2.4, Paint()..color = palette.panel);
              canvas.drawCircle(dot, u * 2, Paint()..color = color);
              _drawLabel(canvas, n, dot, u * 2.6, Colors.white);
            }
          }
          for (var i = 0; i < 3; i++) {
            final Rect row = Rect.fromLTWH(
              drawer.left + u * 4,
              logo.bottom + u * (bar ? 8 : 3) + i * u * 5.2,
              drawer.width - u * 8,
              u * 3.8,
            );
            canvas.drawRRect(
              RRect.fromRectAndRadius(row, Radius.circular(u)),
              Paint()..color = ink.withValues(alpha: 0.08),
            );
            canvas.drawCircle(
              Offset(row.left + u * 2.4, row.center.dy),
              u * 1.2,
              Paint()..color = ink.withValues(alpha: 0.35),
            );
            if (bar && i == 0) {
              _drawLabel(
                canvas,
                "Profile",
                Offset(row.left + u * 10, row.center.dy),
                u * 2.6,
                ink.withValues(alpha: 0.7),
              );
            } else {
              canvas.drawRRect(
                RRect.fromRectAndRadius(
                  Rect.fromLTWH(row.left + u * 5.5, row.center.dy - u * 0.7, u * (i.isEven ? 16 : 12), u * 1.4),
                  Radius.circular(u),
                ),
                Paint()..color = ink.withValues(alpha: 0.3),
              );
            }
          }
          canvas.restore();
        }
        if (slide > 0) {
          canvas.save();
          canvas.clipRRect(shape);
          final Rect shifted = full.shift(Offset(full.width * (1 - slide), 0));
          bar ? _drawChatList(canvas, shifted) : _drawChat(canvas, shifted);
          canvas.restore();
        }

        final Offset finger = t < 0.36
            ? Offset.lerp(Offset(full.left + u * 30, size.height + u * 4), menu, _seg(t, 0.04, 0.14))!
            : Offset.lerp(menu, target, _seg(t, 0.38, 0.46))!;
        _drawFinger(
          canvas,
          finger,
          alpha: _seg(t, 0.04, 0.08) * (1 - _seg(t, 0.58, 0.64)),
          ring: [tapMenu, tapBubble].firstWhere((v) => v > 0 && v < 1, orElse: () => 0),
        );
    }
    canvas.restore();
  }

  Rect _chipRect(Rect panel, int index, {bool mainLeading = false}) {
    final double gap = u * 1.2;
    double x = panel.left + u * 1.5 + index * (u * 7 + gap);
    if (mainLeading && index > 0) x += gap * 1.5;
    return Rect.fromLTWH(x, panel.top + u * 1.25, u * 7, u * 5.5);
  }

  void _drawChip(Canvas canvas, Rect rect, String label, {bool active = false, bool solid = false, double alpha = 1}) {
    final ink = palette.ink;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(u));
    if (solid) canvas.drawRRect(rrect, Paint()..color = palette.panel.withValues(alpha: alpha));
    canvas.drawRRect(
      rrect,
      Paint()..color = active ? _blue.withValues(alpha: 0.28 * alpha) : ink.withValues(alpha: 0.10 * alpha),
    );
    if (active) {
      canvas.drawRect(
        Rect.fromLTWH(rect.left + u * 0.8, rect.bottom - u * 0.8, rect.width - u * 1.6, u * 0.8),
        Paint()..color = _blue.withValues(alpha: alpha),
      );
    }
    if (rect.width < u * 3) return;
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: ink.withValues(alpha: 0.85 * alpha),
          fontSize: u * 3.4,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(canvas, rect.center - Offset(text.width / 2, text.height / 2));
    text.dispose();
  }

  void _drawBrowser(
    Canvas canvas,
    Rect rect, {
    required List<String> tabs,
    required int active,
    required Color page,
    bool mainLeading = false,
    double growLast = 1,
    bool pageReplaced = false,
    double loading = 0,
    int? lifted,
  }) {
    final ink = palette.ink;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(u * 1.5));
    canvas.drawRRect(rrect, Paint()..color = palette.panel);
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(
      Rect.fromLTWH(rect.left, rect.top, rect.width, u * 8),
      Paint()..color = Color.alphaBlend(ink.withValues(alpha: 0.08), palette.panel),
    );
    for (var i = 0; i < tabs.length; i++) {
      Rect chip = _chipRect(rect, i, mainLeading: mainLeading);
      if (i == tabs.length - 1 && growLast < 1) {
        chip = Rect.fromLTWH(chip.left, chip.top, chip.width * growLast, chip.height);
      }
      if (chip.width <= 0) continue;
      _drawChip(canvas, chip, tabs[i], active: i == active && lifted != i, alpha: lifted == i ? 0.3 : 1);
    }
    if (mainLeading) {
      final double x = _chipRect(rect, 1, mainLeading: true).left - u * 1.5;
      canvas.drawLine(
        Offset(x, rect.top + u * 2),
        Offset(x, rect.top + u * 6),
        Paint()
          ..strokeWidth = u * 0.4
          ..color = ink.withValues(alpha: 0.35),
      );
    }

    final double top = rect.top + u * 8;
    if (!pageReplaced) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rect.left + u * 3, top + u * 3, rect.width - u * 6, u * 9),
          Radius.circular(u),
        ),
        Paint()..color = page,
      );
      final linePaint = Paint()..color = ink.withValues(alpha: 0.14);
      for (var i = 0; i < 6; i++) {
        final double width = (rect.width - u * 6) * (i.isEven ? 0.9 : 0.65);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(rect.left + u * 3, top + u * 15.5 + i * u * 5, width, u * 2),
            Radius.circular(u),
          ),
          linePaint,
        );
      }
    }
    if (loading > 0 && loading < 1) {
      canvas.drawRect(Rect.fromLTWH(rect.left, top, rect.width * loading, u * 0.9), Paint()..color = _blue);
    }
    canvas.restore();
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.3
        ..color = ink.withValues(alpha: 0.18),
    );
  }

  void _drawApp(Canvas canvas, Rect rect, {double alpha = 1, double tapped = 0, bool shadow = false}) {
    final ink = palette.ink;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(u * 1.5));
    canvas.saveLayer(rect.inflate(u * 3), Paint()..color = Color.fromRGBO(0, 0, 0, alpha));
    if (shadow) canvas.drawShadow(Path()..addRRect(rrect), Colors.black, u * 1.5, false);
    canvas.drawRRect(rrect, Paint()..color = palette.panel);
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(Rect.fromLTWH(rect.left, rect.top, rect.width, u * 8), Paint()..color = palette.appBar);
    final barPaint = Paint()..color = Colors.white.withValues(alpha: 0.9);
    for (var i = 0; i < 3; i++) {
      canvas.drawRect(Rect.fromLTWH(rect.left + u * 3, rect.top + u * (2.6 + i * 1.2), u * 4, u * 0.6), barPaint);
    }
    canvas.drawRect(Rect.fromLTWH(rect.left + u * 10, rect.top + u * 3.4, u * 14, u * 1.2), barPaint);
    for (var i = 0; i < 4; i++) {
      final row = Rect.fromLTWH(rect.left + u * 3, rect.top + u * 11 + i * u * 9.5, rect.width - u * 6, u * 7);
      canvas.drawRRect(
        RRect.fromRectAndRadius(row, Radius.circular(u)),
        Paint()
          ..color = i == 1 && tapped > 0
              ? Color.lerp(ink.withValues(alpha: 0.08), _link.withValues(alpha: 0.45), tapped)!
              : ink.withValues(alpha: 0.08),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(row.left + u * 2, row.center.dy - u, row.width * (i.isEven ? 0.55 : 0.4), u * 2),
          Radius.circular(u),
        ),
        Paint()..color = ink.withValues(alpha: 0.25),
      );
    }
    canvas.restore();
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.3
        ..color = ink.withValues(alpha: 0.18),
    );
    canvas.restore();
  }

  void _drawZone(Canvas canvas, Rect rect, {required double alpha, required String label}) {
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(u * 1.5));
    canvas.drawRRect(rrect, Paint()..color = _blue.withValues(alpha: 0.22 * alpha));
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.6
        ..color = _blue.withValues(alpha: alpha),
    );
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: alpha),
          fontSize: u * 3.4,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final pill = Rect.fromCenter(
      center: Offset(rect.center.dx, rect.top + u * 13),
      width: text.width + u * 5,
      height: text.height + u * 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(pill, Radius.circular(pill.height / 2)),
      Paint()..color = Colors.black.withValues(alpha: 0.75 * alpha),
    );
    text.paint(canvas, pill.center - Offset(text.width / 2, text.height / 2));
    text.dispose();
  }

  void _drawOtherApp(Canvas canvas, Rect rect, {required double alpha}) {
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(u * 1.5));
    canvas.saveLayer(rect.inflate(u), Paint()..color = Color.fromRGBO(0, 0, 0, alpha));
    canvas.drawRRect(rrect, Paint()..color = palette.panel);
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(Rect.fromLTWH(rect.left, rect.top, rect.width, u * 8), Paint()..color = _pages['2']!);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left + u * 3, rect.top + u * 11, rect.width - u * 6, u * 22),
        Radius.circular(u),
      ),
      Paint()..color = _pages['1']!.withValues(alpha: 0.6),
    );
    final linePaint = Paint()..color = palette.ink.withValues(alpha: 0.14);
    for (var i = 0; i < 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(rect.left + u * 3, rect.top + u * (37 + i * 5), rect.width * (i.isEven ? 0.7 : 0.5), u * 2),
          Radius.circular(u),
        ),
        linePaint,
      );
    }
    canvas.restore();
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.3
        ..color = palette.ink.withValues(alpha: 0.18),
    );
    canvas.restore();
  }

  void _drawPipWindow(Canvas canvas, {required bool player, required double t, required double alpha}) {
    final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, u * 38, u * 22.6), Radius.circular(u * 1.5));
    Color border = palette.ink.withValues(alpha: 0.25);
    canvas.saveLayer(rrect.outerRect.inflate(u), Paint()..color = Color.fromRGBO(0, 0, 0, alpha));
    canvas.drawRRect(rrect, Paint()..color = palette.panel);

    if (player) {
      final int sec = (5 - 5 * ((t - 0.79) / 0.05).clamp(0, 1)).ceil();
      final bool okay = sec == 0;
      if (okay) border = _link;
      final rows = [(okay ? "OKAY" : "0:0$sec", okay ? _link : Colors.red[400]!), ("4:12", Colors.red[400]!)];
      for (var i = 0; i < rows.length; i++) {
        final row = Rect.fromLTWH(u * 2, u * (3.5 + i * 8), u * 34, u * 7);
        if (i == 0 && okay) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(row, Radius.circular(u)),
            Paint()..color = _link.withValues(alpha: 0.3),
          );
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(row.left + u * 1.5, row.center.dy - u, u * 12, u * 2),
            Radius.circular(u),
          ),
          Paint()..color = palette.ink.withValues(alpha: 0.3),
        );
        _drawLabel(canvas, rows[i].$1, Offset(row.right - u * 8, row.center.dy), u * 5, rows[i].$2);
      }
    } else {
      final double p = ((t - 0.54) / 0.4).clamp(0, 1);
      final int sec = (90 - 40 * p).round();
      final double bar = sec / 120;
      final Color state = Color.lerp(Colors.red[400], _link, bar)!;
      if (sec < 65 && (t * 40).floor().isEven) border = Colors.red[400]!;
      canvas.drawCircle(Offset(u * 4, u * 3.4), u * 1.2, Paint()..color = state);
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(u * 7, u * 2.6, u * 14, u * 1.6), Radius.circular(u)),
        Paint()..color = palette.ink.withValues(alpha: 0.2),
      );
      _drawLabel(
        canvas,
        "${sec ~/ 60}:${(sec % 60).toString().padLeft(2, '0')}",
        Offset(u * 19, u * 11.5),
        u * 9,
        palette.ink,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(u * 4, u * 18, u * 30, u * 1.8), Radius.circular(u)),
        Paint()..color = palette.ink.withValues(alpha: 0.14),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(u * 4, u * 18, u * 30 * bar, u * 1.8), Radius.circular(u)),
        Paint()..color = state,
      );
    }
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.7
        ..color = border,
    );
    canvas.restore();
  }

  Rect _chatRow(Rect full, int i) =>
      Rect.fromLTWH(full.left + u * 3, full.top + u * 11 + i * u * 9.5, full.width - u * 6, u * 7);

  Rect _replyBox(Rect full) {
    final Rect first = _chatRow(full, 0);
    return Rect.fromLTWH(first.left + u * 8, first.bottom + u * 15.8, first.width - u * 17, u * 5.5);
  }

  void _drawChatList(Canvas canvas, Rect full, {double tapRow = 0, double? reply, double typed = 0, double sent = 0}) {
    final ink = palette.ink;
    final double open = reply ?? 0;
    final shape = RRect.fromRectAndRadius(full, Radius.circular(u * 1.5));
    canvas.drawRRect(shape, Paint()..color = palette.panel);
    canvas.save();
    canvas.clipRRect(shape);
    canvas.drawRect(Rect.fromLTWH(full.left, full.top, full.width, u * 8), Paint()..color = palette.appBar);
    _drawLabel(canvas, "Chats", Offset(full.left + u * 9, full.top + u * 4), u * 3.6, Colors.white);
    for (var i = 0; i < 4; i++) {
      final Rect r = _chatRow(full, i).shift(Offset(0, i > 0 ? open * u * 23 : 0));
      canvas.drawRRect(
        RRect.fromRectAndRadius(r, Radius.circular(u)),
        Paint()
          ..color = i == 1 && tapRow > 0
              ? Color.lerp(ink.withValues(alpha: 0.08), _link.withValues(alpha: 0.45), tapRow)!
              : ink.withValues(alpha: 0.08),
      );
      canvas.drawCircle(Offset(r.left + u * 4, r.center.dy), u * 2.4, Paint()..color = _pages.values.elementAt(i));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(r.left + u * 8, r.top + u * 1.4, u * (i.isEven ? 18 : 14), u * 1.8),
          Radius.circular(u),
        ),
        Paint()..color = ink.withValues(alpha: 0.45),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(r.left + u * 8, r.top + u * 4.2, r.width * 0.5, u * 1.4),
          Radius.circular(u),
        ),
        Paint()..color = ink.withValues(alpha: 0.2),
      );
      if (i < 2) {
        final double alpha = i == 0 ? 1 - open : 1;
        final Offset badge = Offset(r.right - u * (reply == null ? 4 : 10), r.center.dy);
        canvas.drawCircle(badge, u * 2, Paint()..color = _blue.withValues(alpha: alpha));
        _drawLabel(canvas, "${2 - i}", badge, u * 2.6, Colors.white.withValues(alpha: alpha));
      }
      if (reply != null) {
        _drawIcon(
          canvas,
          i == 0 && open > 0.5 ? Icons.expand_less_rounded : Icons.expand_more_rounded,
          Offset(r.right - u * 4, r.center.dy),
          u * 4.5,
          ink.withValues(alpha: 0.6),
        );
      }
    }
    if (open > 0) {
      final Rect first = _chatRow(full, 0);
      final Rect box = _replyBox(full);
      final double line = u * 4.6;
      final double top = first.bottom + u * 1.5;
      canvas.save();
      canvas.clipRect(Rect.fromLTRB(first.left, first.bottom, first.right, first.bottom + u * 23 * open));
      canvas.save();
      canvas.clipRect(Rect.fromLTWH(box.left, top, first.width, line * 3));
      for (var k = 0; k < 4; k++) {
        if (k == 3 && sent == 0) continue;
        final double y = top + (k - sent) * line + u * 1.5;
        canvas.drawRRect(
          RRect.fromRectAndRadius(Rect.fromLTWH(box.left, y, u * 6, u * 1.6), Radius.circular(u)),
          Paint()..color = k == 3 ? _link : _pages.values.elementAt(k + 1),
        );
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(box.left + u * 7.5, y, u * (k == 3 ? 16 : (k.isEven ? 30 : 22)), u * 1.6),
            Radius.circular(u),
          ),
          Paint()..color = ink.withValues(alpha: 0.3),
        );
      }
      canvas.restore();
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, Radius.circular(box.height / 2)),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = u * 0.4
          ..color = ink.withValues(alpha: 0.3),
      );
      if (sent == 0 && typed > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(box.left + u * 2.5, box.center.dy - u * 0.8, u * 16 * typed, u * 1.6),
            Radius.circular(u),
          ),
          Paint()..color = ink.withValues(alpha: 0.6),
        );
      }
      _drawIcon(
        canvas,
        Icons.send_rounded,
        Offset(box.right + u * 3.5, box.center.dy),
        u * 4,
        typed > 0 && sent == 0 ? _blue : ink.withValues(alpha: 0.3),
      );
      canvas.restore();
    }
    canvas.restore();
  }

  void _drawChat(Canvas canvas, Rect rect, {double nameTap = 0, double linkTap = 0}) {
    final ink = palette.ink;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(u * 1.5));
    canvas.drawRRect(rrect, Paint()..color = palette.panel);
    canvas.save();
    canvas.clipRRect(rrect);
    canvas.drawRect(Rect.fromLTWH(rect.left, rect.top, rect.width, u * 8), Paint()..color = palette.appBar);
    _drawIcon(canvas, Icons.arrow_back_rounded, Offset(rect.left + u * 4.5, rect.top + u * 4), u * 4.5, Colors.white);
    canvas.drawCircle(Offset(rect.left + u * 11, rect.top + u * 4), u * 2.4, Paint()..color = _pages['2']!);
    canvas.drawRect(
      Rect.fromLTWH(rect.left + u * 15, rect.top + u * 3.4, u * 16, u * 1.2),
      Paint()..color = Colors.white.withValues(alpha: 0.9),
    );
    for (final (i, icon) in [
      Icons.minimize_rounded,
      Icons.picture_in_picture_alt_rounded,
      Icons.more_vert_rounded,
    ].indexed) {
      _drawIcon(canvas, icon, Offset(rect.right - u * (16 - i * 6), rect.top + u * 4), u * 4.5, Colors.white);
    }

    for (final (top, width, own, name) in [
      (11.0, 40.0, false, Colors.orange[400]),
      (21.5, 30.0, true, null),
      (29.5, 46.0, false, _pages['4']),
      (40.0, 22.0, true, null),
    ]) {
      final bubble = Rect.fromLTWH(
        own ? rect.right - u * (3 + width) : rect.left + u * 3,
        rect.top + u * top,
        u * width,
        u * (own ? 6 : 8.5),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(bubble, Radius.circular(u * 1.5)),
        Paint()..color = own ? _blue.withValues(alpha: 0.28) : ink.withValues(alpha: 0.08),
      );
      if (name != null) {
        final label = Rect.fromLTWH(bubble.left + u * 2, bubble.top + u * 2, u * 12, u * 1.8);
        final double tap = top == 11 ? nameTap : 0;
        if (tap > 0) {
          canvas.drawRRect(
            RRect.fromRectAndRadius(label.inflate(u * 0.9), Radius.circular(u)),
            Paint()..color = _link.withValues(alpha: 0.45 * tap),
          );
        }
        canvas.drawRRect(RRect.fromRectAndRadius(label, Radius.circular(u)), Paint()..color = name);
      }
      final bool hasLink = top == 29.5;
      final text = Rect.fromLTWH(
        bubble.left + u * 2,
        own ? bubble.top + u * 2.1 : bubble.top + u * 5.3,
        hasLink ? u * 30 : bubble.width - u * 4,
        u * 1.8,
      );
      if (hasLink && linkTap > 0) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(text.inflate(u * 0.9), Radius.circular(u)),
          Paint()..color = _link.withValues(alpha: 0.45 * linkTap),
        );
      }
      canvas.drawRRect(
        RRect.fromRectAndRadius(text, Radius.circular(u)),
        Paint()..color = hasLink ? _link : ink.withValues(alpha: 0.25),
      );
    }

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rect.left + u * 3, rect.bottom - u * 8, rect.width - u * 13, u * 5.5),
        Radius.circular(u * 2.75),
      ),
      Paint()..color = ink.withValues(alpha: 0.08),
    );
    final Offset send = Offset(rect.right - u * 6.5, rect.bottom - u * 5.25);
    canvas.drawCircle(send, u * 2.75, Paint()..color = _blue);
    _drawIcon(canvas, Icons.send_rounded, send, u * 3, Colors.white);
    canvas.restore();
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = u * 0.3
        ..color = ink.withValues(alpha: 0.18),
    );
  }

  void _drawChatBubble(Canvas canvas, Offset center, {double alpha = 1}) {
    if (alpha <= 0) return;
    final double radius = u * 4.5;
    final Offset badge = center + Offset(radius * 0.75, -radius * 0.75);
    canvas.saveLayer(Rect.fromCircle(center: center, radius: u * 9), Paint()..color = Color.fromRGBO(0, 0, 0, alpha));
    canvas.drawShadow(Path()..addOval(Rect.fromCircle(center: center, radius: radius)), Colors.black, u, false);
    canvas.drawCircle(center, radius, Paint()..color = _blue);
    _drawIcon(canvas, Icons.forum_rounded, center, u * 5, Colors.white);
    canvas.drawCircle(badge, u * 2, Paint()..color = Colors.red[400]!);
    _drawLabel(canvas, "3", badge, u * 2.6, Colors.white);
    canvas.restore();
  }

  void _drawLabel(Canvas canvas, String text, Offset center, double size, Color color) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: size, fontWeight: FontWeight.bold, letterSpacing: 0),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
    painter.dispose();
  }

  void _drawIcon(Canvas canvas, IconData icon, Offset center, double size, Color color) {
    final style = TextStyle(fontFamily: icon.fontFamily, package: icon.fontPackage, fontSize: size, color: color);
    final painter = TextPainter(
      text: TextSpan(text: String.fromCharCode(icon.codePoint), style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
    painter.dispose();
  }

  void _drawFinger(Canvas canvas, Offset tip, {required double alpha, double ring = 0}) {
    if (alpha <= 0) return;
    if (ring > 0) {
      canvas.drawCircle(
        tip,
        u * (1.5 + ring * 4),
        Paint()..color = palette.ink.withValues(alpha: 0.25 * (1 - ring) * alpha),
      );
    }
    const icon = Icons.touch_app;
    final double size = u * 11;
    final glyph = String.fromCharCode(icon.codePoint);
    TextStyle style(Paint paint) =>
        TextStyle(fontFamily: icon.fontFamily, package: icon.fontPackage, fontSize: size, height: 1, foreground: paint);
    final outline = TextPainter(
      text: TextSpan(
        text: glyph,
        style: style(
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = u * 0.8
            ..color = palette.frame.withValues(alpha: alpha),
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final fill = TextPainter(
      text: TextSpan(
        text: glyph,
        style: style(Paint()..color = palette.ink.withValues(alpha: 0.85 * alpha)),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final Offset origin = tip - Offset(size * 0.48, size * 0.27);
    outline.paint(canvas, origin);
    fill.paint(canvas, origin);
    outline.dispose();
    fill.dispose();
  }

  @override
  bool shouldRepaint(_FeatureDiagramPainter old) =>
      old.scene != scene || old.animation != animation || old.palette != palette;
}
