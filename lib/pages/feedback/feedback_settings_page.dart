import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/feedback/feedback_input.dart';
import 'package:torn_pda/pages/feedback/feedback_pin_dialog.dart';
import 'package:torn_pda/pages/feedback/feedback_route.dart';
import 'package:torn_pda/pages/feedback/feedback_widgets.dart';
import 'package:torn_pda/providers/feedback_account_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/widgets/pda_scaffold.dart';

class FeedbackSettingsPage extends StatefulWidget {
  const FeedbackSettingsPage({super.key});

  @override
  State<FeedbackSettingsPage> createState() => _FeedbackSettingsPageState();
}

class _FeedbackSettingsPageState extends State<FeedbackSettingsPage> with FeedbackSubRoute {
  @override
  String get subRouteName => 'feedback_settings';

  Future<void> _toggleAlerts() async {
    try {
      await Get.find<FeedbackAccountController>().toggleSubscribeAll();
    } catch (e) {
      showFeedbackError(e);
    }
  }

  Widget _title(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Center(child: Text(text, style: const TextStyle(fontSize: 10))),
    );
  }

  Widget _line(String text) {
    return Text(
      text,
      style: TextStyle(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    return PdaScaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: settings.appBarTop ? 2 : 0,
        toolbarHeight: 50,
        title: const Text('Feedback settings', style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: goBack),
      ),
      body: Container(
        color: themeProvider.canvas,
        child: GetBuilder<FeedbackAccountController>(
          builder: (controller) {
            final account = controller.account;
            final hasPin = account.hasPin;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
              children: [
                _title('ALERTS'),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('New feedback alerts'),
                    Switch(
                      value: account.subscribedToAll,
                      onChanged: (_) => _toggleAlerts(),
                      activeTrackColor: Colors.lightGreenAccent,
                      activeThumbColor: Colors.green,
                    ),
                  ],
                ),
                _line(
                  account.isModerator
                      ? 'Get a notification for every new post, comment and bug report'
                      : 'Get a notification for every new post',
                ),
                _title('PIN'),
                _line('Stops anyone with your API key from signing in as you on the web'),
                if (account.isModerator) _line('Moderators also need it to unlock moderation'),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  children: [
                    if (hasPin != true)
                      OutlinedButton(
                        onPressed: () => showFeedbackPinDialog(context, FeedbackPinMode.set),
                        child: const Text('Set PIN'),
                      ),
                    if (hasPin != false) ...[
                      OutlinedButton(
                        onPressed: () => showFeedbackPinDialog(context, FeedbackPinMode.change),
                        child: const Text('Change PIN'),
                      ),
                      if (!account.isModerator)
                        OutlinedButton(
                          onPressed: () => showFeedbackPinDialog(context, FeedbackPinMode.remove),
                          child: const Text('Remove PIN'),
                        ),
                    ],
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
