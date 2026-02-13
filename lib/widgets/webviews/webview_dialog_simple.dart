import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/config/webview_config.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';

/// Opens a very simple webview dialog with just a CLOSE button.
/// No tabs, no navigation — just view a URL and close.
/// Used for quick URL viewing (e.g. Torn API key creation page, policy pages).
Future<void> openSimpleWebViewDialog({
  required BuildContext context,
  required String url,
  String title = '',
}) async {
  final double width = MediaQuery.of(context).size.width;
  double hPad = 15;
  double frame = 6;

  if (width < 400) {
    hPad = 6;
    frame = 2;
  }

  return showDialog(
    useRootNavigator: false,
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return Dialog(
        insetPadding: EdgeInsets.symmetric(horizontal: hPad, vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 8, horizontal: frame),
          child: _SimpleWebViewContent(url: url, title: title),
        ),
      );
    },
  );
}

class _SimpleWebViewContent extends StatefulWidget {
  final String url;
  final String title;

  const _SimpleWebViewContent({required this.url, required this.title});

  @override
  State<_SimpleWebViewContent> createState() => _SimpleWebViewContentState();
}

class _SimpleWebViewContentState extends State<_SimpleWebViewContent> {
  late InAppWebViewSettings _settings;
  late URLRequest _initialUrl;
  late ThemeProvider _themeProvider;
  bool _requestClose = false;

  @override
  void initState() {
    super.initState();
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _initialUrl = URLRequest(url: WebUri(widget.url));

    PlatformInAppWebViewController.debugLoggingSettings.enabled = false;

    final uaSuffix = _buildUserAgentSuffix();
    _settings = InAppWebViewSettings(
      transparentBackground: true,
      applicationNameForUserAgent: uaSuffix.isEmpty ? null : uaSuffix,
      initialScale: settingsProvider.androidBrowserScale,
      useWideViewPort: false,
      allowsLinkPreview: settingsProvider.iosAllowLinkPreview,
      disableLongPressContextMenuOnLinks: true,
      ignoresViewportScaleLimits: settingsProvider.iosBrowserPinch,
    );
  }

  String _buildUserAgentSuffix() {
    const unknown = "##deviceBrand=unknown##deviceModel=unknown##deviceSoftware=unknown##";
    final deviceInfo = WebviewConfig.userAgentForUser.isNotEmpty ? WebviewConfig.userAgentForUser : unknown;
    return "${WebviewConfig.agent} $deviceInfo".trim();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Container(
        color: _themeProvider.currentTheme == AppTheme.light
            ? Colors.blueGrey
            : _themeProvider.currentTheme == AppTheme.dark
                ? Colors.grey[900]
                : Colors.black,
        child: SafeArea(
          top: false,
          child: Scaffold(
            backgroundColor: _themeProvider.canvas,
            body: Column(
              children: [
                if (widget.title.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    color: _themeProvider.secondBackground,
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        color: _themeProvider.mainText,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Expanded(
                  child: _requestClose ? const SizedBox.shrink() : _buildWebView(),
                ),
                _bottomBar(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWebView() {
    return InAppWebView(
      initialUrlRequest: _initialUrl,
      initialSettings: _settings,
    );
  }

  Widget _bottomBar() {
    return Container(
      color: _themeProvider.secondBackground,
      height: 38,
      child: Center(
        child: GestureDetector(
          onTap: () async {
            setState(() => _requestClose = true);
            await Future.delayed(const Duration(milliseconds: 200));
            if (mounted) Navigator.of(context).pop();
          },
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 40),
            color: Colors.transparent,
            child: Center(
              child: Text(
                "CLOSE",
                style: TextStyle(
                  color: _themeProvider.mainText,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
