import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/feedback/feedback_input.dart';
import 'package:torn_pda/pages/feedback/feedback_pin_dialog.dart';
import 'package:torn_pda/pages/feedback/feedback_private_page.dart';
import 'package:torn_pda/pages/feedback/feedback_widgets.dart';
import 'package:torn_pda/providers/feedback_account_controller.dart';

enum _MenuAction { alerts, pin, removePin }

class FeedbackAppBarActions extends StatelessWidget {
  const FeedbackAppBarActions({super.key, required this.onCreate, required this.onReport});

  final VoidCallback onCreate;
  final VoidCallback onReport;

  Future<void> _toggleAlerts() async {
    try {
      await Get.find<FeedbackAccountController>().toggleSubscribeAll();
    } catch (e) {
      showFeedbackError(e);
    }
  }

  void _select(BuildContext context, _MenuAction action) {
    switch (action) {
      case _MenuAction.alerts:
        _toggleAlerts();
      case _MenuAction.pin:
        showFeedbackPinDialog(context, FeedbackPinMode.change);
      case _MenuAction.removePin:
        showFeedbackPinDialog(context, FeedbackPinMode.remove);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<FeedbackAccountController>(
      builder: (controller) {
        final account = controller.account;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(icon: const Icon(Icons.add), tooltip: 'New', onPressed: onCreate),
            IconButton(icon: const Icon(Icons.bug_report_outlined), tooltip: 'Report a bug', onPressed: onReport),
            if (account.isModerator && controller.unlocked)
              IconButton(
                icon: const Icon(Icons.lock_open),
                tooltip: 'Bugs',
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FeedbackPrivatePage())),
              )
            else if (account.isModerator)
              IconButton(
                icon: const Icon(Icons.lock_outline),
                tooltip: 'Unlock',
                onPressed: () => showFeedbackPinDialog(context, FeedbackPinMode.unlock),
              ),
            PopupMenuButton<_MenuAction>(
              onSelected: (action) => _select(context, action),
              itemBuilder: (_) => [
                CheckedPopupMenuItem(
                  value: _MenuAction.alerts,
                  checked: account.subscribedToAll,
                  child: const Text('New feedback alerts'),
                ),
                const PopupMenuItem(value: _MenuAction.pin, child: Text('PIN')),
                const PopupMenuItem(value: _MenuAction.removePin, child: Text('Remove PIN')),
              ],
            ),
          ],
        );
      },
    );
  }
}
