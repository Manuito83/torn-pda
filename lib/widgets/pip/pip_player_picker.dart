import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/pip_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';

class PipSelection extends ChangeNotifier {
  static final _active = ValueNotifier<PipSelection?>(null);

  List<PipPlayer>? _picked;

  bool get active => _picked != null;
  int get count => _picked?.length ?? 0;
  bool isPicked(int id) => _picked?.any((p) => p.id == id) ?? false;

  static bool allowed(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    return settings.pipEnabled && settings.pipPlayerButtons && Get.find<PipController>().supported;
  }

  // Back button handler in main
  static bool cancelActive() {
    final selection = _active.value;
    if (selection == null) return false;
    selection.cancel();
    return true;
  }

  void start({required bool empty}) {
    if (empty) {
      _toast('No players to watch here');
      return;
    }
    _active.value?.cancel();
    _active.value = this;
    _picked = [];
    notifyListeners();
  }

  void cancel() {
    if (_active.value == this) _active.value = null;
    if (_picked == null) return;
    _picked = null;
    notifyListeners();
  }

  void toggle(int id, String name) {
    final picked = _picked;
    if (picked == null) return;
    if (isPicked(id)) {
      picked.removeWhere((p) => p.id == id);
    } else if (picked.length >= PipController.maxPlayers) {
      _toast('Up to ${PipController.maxPlayers} players');
      return;
    } else {
      picked.add(PipPlayer(id: id, name: name.isEmpty ? '#$id' : name));
    }
    notifyListeners();
  }

  void watch() {
    final picked = _picked;
    if (picked == null || picked.isEmpty) return;
    cancel();
    Get.find<PipController>().watchPlayers(picked);
  }

  void _toast(String text) {
    BotToast.showText(
      text: text,
      textStyle: const TextStyle(fontSize: 14, color: Colors.white),
      contentColor: Colors.grey[800]!,
      contentPadding: const EdgeInsets.all(10),
    );
  }

  @override
  void dispose() {
    if (_active.value == this) _active.value = null;
    super.dispose();
  }
}

class PipSelectionBackGuard extends StatelessWidget {
  final Widget child;

  const PipSelectionBackGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<PipSelection?>(
      valueListenable: PipSelection._active,
      builder: (context, selection, child) => PopScope(canPop: selection == null, child: child!),
      child: child,
    );
  }
}

class PipSelectionAppBar extends StatelessWidget implements PreferredSizeWidget {
  final PipSelection selection;
  final AppBar Function() appBar;

  const PipSelectionAppBar({super.key, required this.selection, required this.appBar});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: selection,
      builder: (context, _) {
        if (!selection.active) return appBar();
        final count = selection.count;
        return AppBar(
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(icon: const Icon(Icons.close), tooltip: 'Cancel', onPressed: selection.cancel),
          title: Text(
            count == 0 ? 'Tap up to ${PipController.maxPlayers}' : '$count selected',
            style: const TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.white, disabledForegroundColor: Colors.white38),
              onPressed: count == 0 ? null : selection.watch,
              child: Text(count == 1 ? 'Watch 1 player' : 'Watch ${count == 0 ? '' : '$count '}players'),
            ),
            const SizedBox(width: 6),
          ],
        );
      },
    );
  }
}

class PipSelectionScope extends InheritedNotifier<PipSelection> {
  const PipSelectionScope({super.key, required PipSelection selection, required super.child})
    : super(notifier: selection);

  static PipSelection? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PipSelectionScope>()?.notifier;
}

class PipSelectable extends StatelessWidget {
  final int id;
  final String name;
  final Widget child;

  const PipSelectable({super.key, required this.id, required this.name, required this.child});

  @override
  Widget build(BuildContext context) {
    final selection = PipSelectionScope.of(context);
    if (selection == null) return child;
    final selecting = selection.active;
    final picked = selection.isPicked(id);
    return Stack(
      children: [
        Row(
          children: [
            if (selecting)
              SizedBox(
                width: 34,
                child: Icon(
                  picked ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 22,
                  color: picked ? Colors.blue : Colors.grey,
                ),
              ),
            Expanded(key: const ValueKey('card'), child: child),
          ],
        ),
        if (selecting)
          Positioned.fill(
            child: Material(
              color: picked ? Colors.blue.withValues(alpha: 0.12) : Colors.transparent,
              child: InkWell(onTap: () => selection.toggle(id, name)),
            ),
          ),
      ],
    );
  }
}

class PipPlayersButton extends StatelessWidget {
  final VoidCallback onPressed;

  const PipPlayersButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final enabled = context.select<SettingsProvider, bool>((s) => s.pipEnabled && s.pipPlayerButtons);
    if (!enabled || !Get.find<PipController>().supported) return const SizedBox.shrink();
    return IconButton(
      tooltip: 'Watch players in a floating window',
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      padding: EdgeInsets.zero,
      style: const ButtonStyle(tapTargetSize: MaterialTapTargetSize.shrinkWrap),
      icon: const Icon(Icons.picture_in_picture_alt_outlined, color: Colors.white),
      onPressed: onPressed,
    );
  }
}
