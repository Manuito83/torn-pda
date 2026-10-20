// Dart imports:
import 'dart:math' as math;

// Flutter imports:
import 'package:flutter/material.dart';
// Package imports:
import 'package:provider/provider.dart';
// Project imports:
import 'package:torn_pda/models/drawer_section.dart';
import 'package:torn_pda/providers/chat/chat_prefs.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

class DrawerSectionsPage extends StatefulWidget {
  static const chatId = 'chat';

  /// New sections join, chat above Profile
  static List<String> fullOrder(List<String> saved) {
    final order = [...saved.where((id) => id == chatId || DrawerSection.fromId(id) != null)];
    if (!order.contains(chatId)) order.insert(math.max(0, order.indexOf(DrawerSection.profile.name)), chatId);
    for (final section in DrawerSection.values) {
      if (!order.contains(section.name)) order.add(section.name);
    }
    return order;
  }

  @override
  DrawerSectionsPageState createState() => DrawerSectionsPageState();
}

class DrawerSectionsPageState extends State<DrawerSectionsPage> {
  late SettingsProvider _settingsProvider;

  List<String> _order = [];

  @override
  void initState() {
    super.initState();
    _settingsProvider = context.read<SettingsProvider>();
    _order = DrawerSectionsPage.fullOrder(_settingsProvider.drawerSectionOrder);
  }

  void _save() {
    _settingsProvider.drawerSectionOrder = List.of(_order);
  }

  void _resetToDefaults() {
    setState(() {
      _order = DrawerSectionsPage.fullOrder(const []);
    });
    _settingsProvider.changeDisableTravelSection = false;
    _settingsProvider.changeRankedWarsInMenu = false;
    _settingsProvider.changeStockExchangeInMenu = false;
    _settingsProvider.showWikiInDrawer = true;
    _settingsProvider.drawerSectionHidden = [];
    _save();
  }

  bool _isVisible(DrawerSection section) {
    switch (section) {
      case DrawerSection.travel:
        return !_settingsProvider.disableTravelSection;
      case DrawerSection.rankedWars:
        return _settingsProvider.rankedWarsInMenu;
      case DrawerSection.stockMarket:
        return _settingsProvider.stockExchangeInMenu;
      case DrawerSection.wiki:
        return _settingsProvider.showWikiInDrawer;
      default:
        return !_settingsProvider.drawerSectionHidden.contains(section.name);
    }
  }

  void _toggleVisibility(DrawerSection section) {
    final currentlyVisible = _isVisible(section);
    switch (section) {
      case DrawerSection.travel:
        _settingsProvider.changeDisableTravelSection = currentlyVisible;
        break;
      case DrawerSection.rankedWars:
        _settingsProvider.changeRankedWarsInMenu = !currentlyVisible;
        break;
      case DrawerSection.stockMarket:
        _settingsProvider.changeStockExchangeInMenu = !currentlyVisible;
        break;
      case DrawerSection.wiki:
        _settingsProvider.showWikiInDrawer = !currentlyVisible;
        break;
      default:
        final hidden = List<String>.from(_settingsProvider.drawerSectionHidden);
        if (currentlyVisible) {
          hidden.add(section.name);
        } else {
          hidden.remove(section.name);
        }
        _settingsProvider.drawerSectionHidden = hidden;
        break;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _save();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Drawer Sections'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              _save();
              Navigator.of(context).pop();
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text("Reset to default?"),
                    content: const Text("This will restore the default order and visibility for all drawer sections."),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text("Cancel")),
                      TextButton(
                        onPressed: () {
                          _resetToDefaults();
                          Navigator.of(context).pop();
                        },
                        child: const Text("Reset"),
                      ),
                    ],
                  ),
                );
              },
              child: const Text("RESET", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        body: ReorderableListView.builder(
          padding: const EdgeInsets.only(bottom: 20),
          itemCount: _order.length,
          onReorderItem: (oldIndex, newIndex) {
            // newIndex is already corrected by the framework as of Flutter 3.44
            setState(() {
              final item = _order.removeAt(oldIndex);
              _order.insert(newIndex, item);
            });
            _save();
          },
          itemBuilder: (context, index) {
            if (_order[index] == DrawerSectionsPage.chatId) {
              if (!NativeChat.compiled) return const SizedBox.shrink(key: ValueKey(DrawerSectionsPage.chatId));
              final shown = NativeChat.prefs.launcher == ChatLauncher.menuBar;
              return Card(
                key: const ValueKey(DrawerSectionsPage.chatId),
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: ListTile(
                  leading: const Icon(Icons.forum_rounded),
                  title: const Text('Chat'),
                  subtitle: shown ? null : const Text('Shown with Menu bar in Chat settings'),
                  trailing: const Icon(Icons.drag_handle),
                  tileColor: shown ? null : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08),
                ),
              );
            }
            final section = DrawerSection.fromId(_order[index])!;
            final isVisible = _isVisible(section);
            final canHide = section.canHide;

            return Card(
              key: ValueKey(section.name),
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: ListTile(
                leading: Icon(section.icon),
                title: Text(section.title),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (canHide)
                      IconButton(
                        icon: Icon(
                          isVisible ? Icons.visibility : Icons.visibility_off,
                          color: isVisible ? null : Colors.grey,
                        ),
                        tooltip: isVisible ? 'Hide' : 'Show',
                        onPressed: () => _toggleVisibility(section),
                      ),
                    const Icon(Icons.drag_handle),
                  ],
                ),
                tileColor: !isVisible ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.08) : null,
              ),
            );
          },
        ),
      ),
    );
  }
}
