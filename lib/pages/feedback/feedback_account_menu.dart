import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/feedback/feedback_input.dart';
import 'package:torn_pda/pages/feedback/feedback_pin_dialog.dart';
import 'package:torn_pda/pages/feedback/feedback_private_page.dart';
import 'package:torn_pda/pages/feedback/feedback_settings_page.dart';
import 'package:torn_pda/providers/feedback_account_controller.dart';

class FeedbackAppBarActions extends StatelessWidget {
  const FeedbackAppBarActions({super.key, required this.onCreate, required this.onReport});

  final VoidCallback onCreate;
  final VoidCallback onReport;

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
            if (account.canWrite)
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Settings',
                onPressed: () =>
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const FeedbackSettingsPage())),
              ),
          ],
        );
      },
    );
  }
}
