import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';

/// Bottom panel shown over the foregrounded browser to tweak text size live.
/// Text zoom scales everything proportionally; text scale only raises the minimum font size.
class BrowserTextLivePanel extends StatefulWidget {
  final VoidCallback onClose;

  const BrowserTextLivePanel({required this.onClose, super.key});

  @override
  BrowserTextLivePanelState createState() => BrowserTextLivePanelState();
}

class BrowserTextLivePanelState extends State<BrowserTextLivePanel> {
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
                  Icon(Icons.format_size, size: 18, color: _themeProvider.mainText),
                  const SizedBox(width: 8),
                  Text(
                    "Browser text size",
                    style: TextStyle(color: _themeProvider.mainText, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    color: _themeProvider.mainText,
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              _sliderRow(
                label: "Zoom",
                value: _settingsProvider.androidBrowserTextZoom.toDouble(),
                min: 50,
                max: 200,
                divisions: 30,
                suffix: "%",
                onChanged: (v) {
                  setState(() => _settingsProvider.changeAndroidBrowserTextZoom = v.round());
                  _webViewProvider.changeTextZoom(v.round());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String suffix,
    required ValueChanged<double> onChanged,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 40,
          child: Text(label, style: TextStyle(color: _themeProvider.mainText, fontSize: 13)),
        ),
        Expanded(
          child: Slider(
            min: min,
            max: max,
            divisions: divisions,
            value: value.clamp(min, max),
            activeColor: Colors.orange[800],
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 45,
          child: Text(
            "${value.round()}$suffix",
            textAlign: TextAlign.end,
            style: TextStyle(color: _themeProvider.mainText, fontSize: 12),
          ),
        ),
      ],
    );
  }
}
