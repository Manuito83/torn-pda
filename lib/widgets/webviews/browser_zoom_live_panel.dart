import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';

class BrowserZoomLivePanel extends StatefulWidget {
  final VoidCallback onClose;

  const BrowserZoomLivePanel({required this.onClose, super.key});

  static OverlayEntry? _entry;

  static void show(OverlayState overlay) {
    if (_entry != null) return;
    _entry = OverlayEntry(
      builder: (_) => const Positioned(left: 0, right: 0, bottom: 0, child: BrowserZoomLivePanel(onClose: hide)),
    );
    overlay.insert(_entry!);
  }

  static void hide() {
    _entry?.remove();
    _entry = null;
  }

  @override
  BrowserZoomLivePanelState createState() => BrowserZoomLivePanelState();
}

class BrowserZoomLivePanelState extends State<BrowserZoomLivePanel> {
  late SettingsProvider _settingsProvider;
  late WebViewProvider _webViewProvider;
  late ThemeProvider _themeProvider;

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _webViewProvider = Provider.of<WebViewProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
  }

  // initialScale ignores screen density, so 100% of the page is devicePixelRatio * 100
  int get _neutral => (MediaQuery.devicePixelRatioOf(context) * 100).round();

  int get _percent {
    final int scale = _settingsProvider.androidBrowserScale;
    return scale == 0 ? 100 : (scale * 100 / _neutral).round();
  }

  void _apply(int scale) {
    setState(() => _settingsProvider.setAndroidBrowserScale = scale);
    for (final tab in _webViewProvider.tabList) {
      final InAppWebViewController? controller = tab.webViewKey?.currentState?.webViewController;
      if (controller == null) continue;
      controller
          .getSettings()
          .then((settings) {
            if (settings == null) return;
            settings.initialScale = scale;
            controller.setSettings(settings: settings);
          })
          .catchError((_) {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.all(10),
          padding: const EdgeInsets.fromLTRB(15, 5, 5, 10),
          decoration: BoxDecoration(
            color: _themeProvider.secondBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange[800]!),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.zoom_in, size: 18, color: _themeProvider.mainText),
                  const SizedBox(width: 8),
                  Text(
                    "Browser zoom",
                    style: TextStyle(color: _themeProvider.mainText, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _settingsProvider.androidBrowserScale == 0 ? null : () => _apply(0),
                    child: const Text("Reset"),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: _themeProvider.mainText,
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      min: 50,
                      max: 130,
                      divisions: 16,
                      value: _percent.clamp(50, 130).toDouble(),
                      activeColor: Colors.orange[800],
                      onChanged: (v) => _apply((_neutral * v / 100).round()),
                    ),
                  ),
                  SizedBox(
                    width: 45,
                    child: Text(
                      "$_percent%",
                      textAlign: TextAlign.end,
                      style: TextStyle(color: _themeProvider.mainText, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
