import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/pda_browser_icon.dart';

class LockedTabsNavigationExceptionsPage extends StatefulWidget {
  final SettingsProvider settingsProvider;

  const LockedTabsNavigationExceptionsPage({required this.settingsProvider, super.key});

  @override
  LockedTabsNavigationExceptionsPageState createState() => LockedTabsNavigationExceptionsPageState();
}

class LockedTabsNavigationExceptionsPageState extends State<LockedTabsNavigationExceptionsPage> {
  final TextEditingController _urlController1 = TextEditingController();
  final TextEditingController _urlController2 = TextEditingController();
  String? _errorMessage;

  @override
  void dispose() {
    _urlController1.dispose();
    _urlController2.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Locked Tabs Exceptions'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                "By adding URL pairs, you can allow navigation between both in a locked tab. Note: the browser will "
                "look for matching patterns between URLs (e.g., if you just input 'item' in both, browsing between URLs "
                "containing 'item' will be allowed). You can be as specific or as general as you prefer.",
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Toggle Browser"),
                  const SizedBox(width: 10),
                  PdaBrowserIcon(color: context.read<ThemeProvider>().mainText),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _urlController1,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  labelText: 'URL 1',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _urlController2,
                decoration: const InputDecoration(
                  isDense: true,
                  border: OutlineInputBorder(),
                  labelText: 'URL 2',
                ),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 10),
                Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
              ],
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                  });

                  String url1 = _urlController1.text.trim();
                  String url2 = _urlController2.text.trim();

                  if (url1.isEmpty || url2.isEmpty) {
                    setState(() {
                      _errorMessage = "Both URLs must be provided.";
                    });
                    return;
                  }

                  setState(() {
                    widget.settingsProvider.addLockedTabNavigationException(url1, url2);
                    _urlController1.clear();
                    _urlController2.clear();
                  });
                },
                child: const Text('Add Exception'),
              ),
              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 10),
              const Text(
                "EXCEPTIONS",
                style: TextStyle(fontSize: 11),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.settingsProvider.lockedTabsNavigationExceptions.length,
                itemBuilder: (context, index) {
                  var pair = widget.settingsProvider.lockedTabsNavigationExceptions[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('URL 1', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(pair[0], style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('URL 2', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text(pair[1], style: const TextStyle(color: Colors.blueAccent, fontSize: 12)),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            setState(() {
                              widget.settingsProvider.removeLockedTabNavigationException(index);
                            });
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
