import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/models/feedback/feedback_models.dart';
import 'package:torn_pda/pages/feedback/feedback_account_menu.dart';
import 'package:torn_pda/pages/feedback/feedback_card.dart';
import 'package:torn_pda/pages/feedback/feedback_create_page.dart';
import 'package:torn_pda/pages/feedback/feedback_detail_page.dart';
import 'package:torn_pda/pages/feedback/feedback_widgets.dart';
import 'package:torn_pda/providers/feedback_account_controller.dart';
import 'package:torn_pda/providers/feedback_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/feedback_functions.dart';
import 'package:torn_pda/widgets/pda_browser_icon.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  final _controller = Get.find<FeedbackController>();
  final _account = Get.find<FeedbackAccountController>();
  late SettingsProvider _settingsProvider;
  late ThemeProvider _themeProvider;
  late WebViewProvider _webViewProvider;

  @override
  void initState() {
    super.initState();
    routeWithDrawer = true;
    routeName = "feedback";
    _controller.open();
    _account.load([]);
    _openPendingSoon();
  }

  void _openPendingSoon() {
    if (!_controller.hasPendingOpen) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _openPending());
  }

  Future<void> _openPending() async {
    final id = _controller.takePendingOpen();
    if (id == null || !mounted) return;
    final stopLoading = BotToast.showLoading();
    try {
      final item = await fetchFeedbackItemOrReport(id);
      if (item == null) throw const FeedbackCallError('not-found');
      _account.load([id]);
      stopLoading();
      if (mounted) await _openDetail(item, _controller);
    } catch (e) {
      stopLoading();
      final reason = e is TimeoutException ? 'timeout' : (e is FeedbackCallError ? e.reason : 'not-found');
      showFeedbackError(FeedbackCallError(reason));
    }
  }

  Future<void> _create({bool report = false}) async {
    final id = await Navigator.of(
      context,
    ).push<String>(MaterialPageRoute(builder: (_) => FeedbackCreatePage(report: report)));
    if (id == null) return;
    _controller.reload();
    _controller.requestOpen(id);
  }

  Future<void> _vote(String id) async {
    try {
      await _controller.vote(id);
    } catch (e) {
      showFeedbackError(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _themeProvider = Provider.of<ThemeProvider>(context);
    _webViewProvider = Provider.of<WebViewProvider>(context);

    return Scaffold(
      backgroundColor: _themeProvider.canvas,
      drawer: !_webViewProvider.splitScreenAndBrowserLeft() ? const Drawer() : null,
      appBar: _settingsProvider.appBarTop ? _buildAppBar() : null,
      bottomNavigationBar: !_settingsProvider.appBarTop
          ? SizedBox(height: AppBar().preferredSize.height, child: _buildAppBar())
          : null,
      body: Container(
        color: _themeProvider.canvas,
        child: GetBuilder<FeedbackController>(
          builder: (controller) {
            _openPendingSoon();
            return Column(
              children: [
                _buildFilters(controller),
                Expanded(
                  child: FeedbackPagedList<FeedbackItem>(
                    pager: controller.pager,
                    emptyText: 'No feedback here yet',
                    itemBuilder: (item) => _buildCard(item, controller),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      iconTheme: const IconThemeData(color: Colors.white),
      elevation: _settingsProvider.appBarTop ? 2 : 0,
      systemOverlayStyle: SystemUiOverlayStyle.light,
      leadingWidth: _webViewProvider.appCanOpenBrowser ? 88 : 50,
      leading: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              final ScaffoldState? scaffoldState = context.findRootAncestorStateOfType();
              if (scaffoldState == null) return;
              if (_webViewProvider.splitScreenAndBrowserLeft()) {
                scaffoldState.openEndDrawer();
              } else {
                scaffoldState.openDrawer();
              }
            },
          ),
          if (_webViewProvider.appCanOpenBrowser) const PdaBrowserIcon(),
        ],
      ),
      title: const Text('Feedback', style: TextStyle(color: Colors.white)),
      actions: [FeedbackAppBarActions(onCreate: _create, onReport: () => _create(report: true))],
    );
  }

  Widget _buildFilters(FeedbackController controller) {
    final filter = controller.filter;
    final active = filter.tab == FeedbackTab.active;
    return Column(
      children: [
        SizedBox(
          height: 46,
          child: Row(
            children: [
              const SizedBox(width: 10),
              _chip('Active', active, () => controller.setFilter(filter.withTab(FeedbackTab.active))),
              _chip('Mine', !active, () => controller.setFilter(filter.withTab(FeedbackTab.mine))),
              const Spacer(),
              if (active)
                PopupMenuButton<FeedbackSort>(
                  tooltip: 'Sort',
                  onSelected: (sort) => controller.setFilter(filter.withSort(sort)),
                  itemBuilder: (_) => [
                    for (final sort in FeedbackSort.values) PopupMenuItem(value: sort, child: Text(sort.label)),
                  ],
                  child: Row(
                    children: [
                      const Icon(Icons.sort, size: 18),
                      const SizedBox(width: 4),
                      Text(filter.sort.label, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),
            ],
          ),
        ),
        if (active)
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                for (final status in feedbackListedStatuses)
                  _chip(
                    status.label,
                    filter.status == status,
                    () => controller.setFilter(filter.withStatus(filter.status == status ? null : status)),
                  ),
                for (final tag in controller.tags)
                  _chip(
                    tag.name,
                    filter.tagId == tag.id,
                    () => controller.setFilter(filter.withTag(filter.tagId == tag.id ? null : tag.id)),
                    color: Color(tag.color),
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        selected: selected,
        selectedColor: color?.withValues(alpha: 0.35),
        visualDensity: VisualDensity.compact,
        onSelected: (_) => onTap(),
      ),
    );
  }

  Widget _buildCard(FeedbackItem item, FeedbackController controller) {
    return GetBuilder<FeedbackAccountController>(
      builder: (account) => FeedbackCard(
        item: item,
        tags: controller.tags,
        voted: account.isVoted(item.id),
        onTap: () => _openDetail(item, controller),
        onVote: () => _vote(item.id),
      ),
    );
  }

  Future<void> _openDetail(FeedbackItem item, FeedbackController controller) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FeedbackDetailPage(item: item, tags: controller.tags),
      ),
    );
  }
}
