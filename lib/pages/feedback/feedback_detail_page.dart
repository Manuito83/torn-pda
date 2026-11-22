import 'dart:math';

import 'package:material_ui/material_ui.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/feedback/feedback_models.dart';
import 'package:torn_pda/pages/feedback/feedback_comment_box.dart';
import 'package:torn_pda/pages/feedback/feedback_mod_sheets.dart';
import 'package:torn_pda/pages/feedback/feedback_route.dart';
import 'package:torn_pda/pages/feedback/feedback_widgets.dart';
import 'package:torn_pda/providers/feedback_account_controller.dart';
import 'package:torn_pda/providers/feedback_controller.dart';
import 'package:torn_pda/providers/feedback_pager.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/feedback_firestore.dart';
import 'package:torn_pda/utils/feedback_functions.dart';
import 'package:torn_pda/widgets/pda_scaffold.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

enum _ModAction { status, tags, visibility, delete }

class FeedbackDetailPage extends StatefulWidget {
  const FeedbackDetailPage({super.key, required this.item, required this.tags});

  final FeedbackItem item;
  final List<FeedbackTag> tags;

  @override
  State<FeedbackDetailPage> createState() => _FeedbackDetailPageState();
}

class _FeedbackDetailPageState extends State<FeedbackDetailPage> with FeedbackSubRoute {
  late FeedbackItem _item = widget.item;
  late final FeedbackPager<FeedbackComment> _comments = FeedbackPager((cursor) {
    return _item.isPrivate ? fetchPrivateComments(_item.id, cursor) : fetchFeedbackComments(_item.id, cursor);
  }, onModLocked: _account.markLocked);
  final _scroll = ScrollController();
  final _controller = Get.find<FeedbackController>();
  final _account = Get.find<FeedbackAccountController>();
  late SettingsProvider _settingsProvider;
  late ThemeProvider _themeProvider;
  late WebViewProvider _webViewProvider;

  @override
  String get subRouteName => 'feedback_detail';

  @override
  void initState() {
    super.initState();
    _settingsProvider = Provider.of<SettingsProvider>(context, listen: false);
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 300) _comments.loadMore();
    });
    if (_item.commentsCount > 0) _comments.reload();
    _account.load([_item.id]);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _comments.dispose();
    super.dispose();
  }

  void _openLink(String url) {
    _webViewProvider.openBrowserPreference(context: context, url: url, browserTapType: BrowserTapType.short);
  }

  void _apply(FeedbackItem item) {
    if (mounted) setState(() => _item = item);
    _controller.patchItem(item.id, (_) => item);
  }

  void _shiftVotes(int delta) {
    if (mounted) setState(() => _item = _item.copyWith(votesCount: max(0, _item.votesCount + delta)));
  }

  Future<void> _vote() async {
    try {
      final count = await _controller.vote(_item.id, onDelta: _shiftVotes);
      if (count != null && mounted) setState(() => _item = _item.copyWith(votesCount: count));
    } catch (e) {
      showFeedbackError(e);
    }
  }

  Future<void> _toggleBell() async {
    try {
      await _account.toggleSubscription(_item.id);
    } catch (e) {
      showFeedbackError(e);
    }
  }

  Future<void> _sendComment(String text) async {
    await commentFeedback(_item.id, text);
    _apply(_item.copyWith(commentsCount: _item.commentsCount + 1));
    await _comments.reload();
    while (mounted && _comments.hasMore && !_comments.failed) {
      await _comments.loadMore();
    }
  }

  Future<void> _deleteComment(FeedbackComment comment) async {
    if (!await confirmFeedbackAction(context, 'Delete comment', 'Delete')) return;
    try {
      if (comment.authorPlayerId == _account.account.playerId) {
        await deleteOwnFeedbackComment(_item.id, comment.id);
      } else {
        await moderateFeedback('deleteComment', {'feedbackId': _item.id, 'commentId': comment.id});
      }
    } catch (e) {
      showFeedbackError(e);
      return;
    }
    _comments.remove((c) => c.id == comment.id);
    if (mounted) _apply(_item.copyWith(commentsCount: _item.commentsCount > 0 ? _item.commentsCount - 1 : 0));
  }

  Future<void> _moderate(_ModAction action) async {
    switch (action) {
      case _ModAction.status:
        final updated = await showFeedbackStatusSheet(context, _item);
        if (updated != null) _apply(updated);
      case _ModAction.tags:
        final updated = await showFeedbackTagsSheet(context, _item, _controller.tags);
        if (updated != null) _apply(updated);
      case _ModAction.visibility:
        await _changeVisibility();
      case _ModAction.delete:
        await _deleteItem();
    }
  }

  Future<void> _changeVisibility() async {
    final toPublic = _item.isPrivate;
    if (!await confirmFeedbackAction(context, toPublic ? 'Make public' : 'Make private', 'Confirm')) return;
    try {
      await moderateFeedback('setVisibility', {'feedbackId': _item.id, 'visibility': toPublic ? 'public' : 'private'});
    } catch (e) {
      showFeedbackError(e);
      return;
    }
    if (toPublic) {
      _controller.reload();
    } else {
      _controller.removeItem(_item.id);
    }
    if (mounted) goBack();
  }

  Future<void> _deleteItem() async {
    if (!await confirmFeedbackAction(context, 'Delete feedback', 'Delete')) return;
    try {
      await moderateFeedback('deleteFeedback', {'feedbackId': _item.id});
    } catch (e) {
      showFeedbackError(e);
      return;
    }
    _controller.removeItem(_item.id);
    if (mounted) goBack();
  }

  List<Widget> _buildActions() {
    return [
      GetBuilder<FeedbackAccountController>(
        builder: (account) {
          final locked = account.isLocked(_item.id);
          final on = locked || account.isSubscribed(_item.id);
          return IconButton(
            icon: Icon(on ? Icons.notifications_active : Icons.notifications_none),
            tooltip: 'Alerts',
            onPressed: locked ? null : _toggleBell,
          );
        },
      ),
      GetBuilder<FeedbackAccountController>(
        builder: (account) => !account.unlocked
            ? const SizedBox.shrink()
            : PopupMenuButton<_ModAction>(
                onSelected: _moderate,
                itemBuilder: (_) => [
                  const PopupMenuItem(value: _ModAction.status, child: Text('Status')),
                  const PopupMenuItem(value: _ModAction.tags, child: Text('Tags')),
                  if (_item.isBug)
                    PopupMenuItem(
                      value: _ModAction.visibility,
                      child: Text(_item.isPrivate ? 'Make public' : 'Make private'),
                    ),
                  const PopupMenuItem(value: _ModAction.delete, child: Text('Delete')),
                ],
              ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    _themeProvider = Provider.of<ThemeProvider>(context);
    _webViewProvider = Provider.of<WebViewProvider>(context);

    return PdaScaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: _settingsProvider.appBarTop ? 2 : 0,
        toolbarHeight: 50,
        title: const Text('Feedback', style: TextStyle(color: Colors.white, fontSize: 16)),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: goBack),
        actions: _buildActions(),
      ),
      body: Container(
        color: _themeProvider.canvas,
        child: Column(
          children: [
            Expanded(
              child: GetBuilder<FeedbackAccountController>(
                builder: (_) => ListenableBuilder(listenable: _comments, builder: (_, _) => _buildList()),
              ),
            ),
            GetBuilder<FeedbackAccountController>(
              builder: (account) => FeedbackCommentBox(
                onSend: _sendComment,
                blockedReason: account.account.known && !account.account.canWrite ? account.account.reason : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    final comments = _comments.items;
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
      itemCount: comments.length + 2,
      itemBuilder: (_, index) {
        if (index == 0) return _buildHeader();
        if (index <= comments.length) return _buildComment(comments[index - 1]);
        return _buildFooter();
      },
    );
  }

  Widget _buildHeader() {
    final item = _item;
    final response = item.response;
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FeedbackVotes(count: item.votesCount, voted: _account.isVoted(item.id), onTap: _vote),
            Expanded(
              child: Text(item.heading, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FeedbackBadges(item: item, tags: widget.tags),
        const SizedBox(height: 8),
        Text(
          '${item.authorName} - ${feedbackDate(item.createdAt, now)}',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 12),
        if (item.body.isNotEmpty)
          FeedbackMarkdown(data: item.body, themeProvider: _themeProvider, onOpenLink: _openLink),
        if (response != null) ...[
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              border: const Border(left: BorderSide(color: Colors.green, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Response from ${response.authorName} - ${feedbackDate(response.at, now)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                FeedbackMarkdown(data: response.text, themeProvider: _themeProvider, onOpenLink: _openLink),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        Text('Comments (${item.commentsCount})', style: const TextStyle(fontWeight: FontWeight.bold)),
        const Divider(),
      ],
    );
  }

  Widget _buildComment(FeedbackComment comment) {
    final own = comment.authorPlayerId != null && comment.authorPlayerId == _account.account.playerId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(comment.authorName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              if (comment.isModerator) ...[
                const SizedBox(width: 6),
                const FeedbackBadge(text: 'Moderator', color: Colors.green),
              ],
              const SizedBox(width: 8),
              Text(
                feedbackDate(comment.createdAt, DateTime.now()),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const Spacer(),
              if (own || _account.unlocked)
                InkWell(
                  onTap: () => _deleteComment(comment),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.delete_outline, size: 18, color: Colors.grey),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          FeedbackMarkdown(data: comment.body, themeProvider: _themeProvider, onOpenLink: _openLink),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    if (_comments.failed || _comments.moreFailed) {
      return FeedbackErrorView(
        text: _comments.errorText,
        onRetry: _comments.failed ? _comments.reload : _comments.loadMore,
        compact: true,
      );
    }
    if (_comments.loading || _comments.loadingMore) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_comments.items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text('No comments yet', style: TextStyle(color: Colors.grey)),
      );
    }
    return const SizedBox.shrink();
  }
}
