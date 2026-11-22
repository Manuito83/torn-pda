import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/feedback/feedback_account.dart';
import 'package:torn_pda/models/feedback/feedback_input.dart';
import 'package:torn_pda/pages/feedback/feedback_route.dart';
import 'package:torn_pda/providers/feedback_account_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/feedback_functions.dart';
import 'package:torn_pda/widgets/pda_scaffold.dart';

class FeedbackCreatePage extends StatefulWidget {
  const FeedbackCreatePage({super.key});

  @override
  State<FeedbackCreatePage> createState() => _FeedbackCreatePageState();
}

class _FeedbackCreatePageState extends State<FeedbackCreatePage> with FeedbackSubRoute {
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  String get subRouteName => 'feedback_create';

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  bool get _valid => isValidFeedbackTitle(_title.text) && isValidFeedbackBody(_body.text);

  Future<void> _send() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final id = await createFeedback(_title.text.trim(), _body.text.trim());
      if (mounted) Navigator.of(context).pop(id);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = e is FeedbackCallError ? e.text : feedbackReasonText(null);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final account = Get.find<FeedbackAccountController>().account;
    final blocked = account.known && !account.canWrite;
    return PdaScaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: settings.appBarTop ? 2 : 0,
        toolbarHeight: 50,
        title: const Text('New feedback', style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: goBack),
        actions: [
          TextButton(
            onPressed: _valid && !_sending && !blocked ? _send : null,
            child: _sending
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('Send'),
          ),
        ],
      ),
      body: Container(
        color: themeProvider.canvas,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            TextField(
              controller: _title,
              enabled: !_sending,
              maxLength: feedbackTitleMax,
              decoration: const InputDecoration(labelText: 'Title'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _body,
              enabled: !_sending,
              maxLength: feedbackBodyMax,
              minLines: 6,
              maxLines: 14,
              keyboardType: TextInputType.multiline,
              decoration: const InputDecoration(labelText: 'Details', alignLabelWithHint: true),
              onChanged: (_) => setState(() {}),
            ),
            if (blocked || _error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error ?? feedbackReasonText(account.reason),
                  style: const TextStyle(color: Colors.orange, fontSize: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
