import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/feedback/feedback_models.dart';
import 'package:torn_pda/pages/feedback/feedback_card.dart';
import 'package:torn_pda/pages/feedback/feedback_detail_page.dart';
import 'package:torn_pda/pages/feedback/feedback_route.dart';
import 'package:torn_pda/pages/feedback/feedback_widgets.dart';
import 'package:torn_pda/providers/feedback_account_controller.dart';
import 'package:torn_pda/providers/feedback_controller.dart';
import 'package:torn_pda/providers/feedback_pager.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/feedback_functions.dart';
import 'package:torn_pda/widgets/pda_scaffold.dart';

class FeedbackPrivatePage extends StatefulWidget {
  const FeedbackPrivatePage({super.key});

  @override
  State<FeedbackPrivatePage> createState() => _FeedbackPrivatePageState();
}

class _FeedbackPrivatePageState extends State<FeedbackPrivatePage> with FeedbackSubRoute {
  late final _pager = FeedbackPager<FeedbackItem>(fetchPrivateFeedback, onModLocked: _onModLocked);

  @override
  String get subRouteName => 'feedback_private';

  void _onModLocked() {
    Get.find<FeedbackAccountController>().markLocked();
    if (mounted && ModalRoute.of(context)?.isCurrent == true) goBack();
  }

  @override
  void initState() {
    super.initState();
    _pager.reload();
  }

  @override
  void dispose() {
    _pager.dispose();
    super.dispose();
  }

  Future<void> _open(FeedbackItem item) async {
    final tags = Get.find<FeedbackController>().tags;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FeedbackDetailPage(item: item, tags: tags),
      ),
    );
    _pager.reload();
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
        title: const Text('Private bugs', style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: goBack),
      ),
      body: Container(
        color: themeProvider.canvas,
        child: ListenableBuilder(listenable: _pager, builder: (_, _) => _buildList()),
      ),
    );
  }

  Widget _buildList() {
    final tags = Get.find<FeedbackController>().tags;
    return FeedbackPagedList<FeedbackItem>(
      pager: _pager,
      emptyText: 'No private bugs',
      itemBuilder: (item) => FeedbackCard(item: item, tags: tags, onTap: () => _open(item)),
    );
  }
}
