import 'package:bot_toast/bot_toast.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:get/get.dart';
import 'package:torn_pda/models/feedback/feedback_account.dart';
import 'package:torn_pda/models/feedback/feedback_models.dart';
import 'package:torn_pda/providers/feedback_account_controller.dart';
import 'package:torn_pda/providers/feedback_pager.dart';
import 'package:torn_pda/providers/theme_provider.dart';
import 'package:torn_pda/utils/feedback_functions.dart';

Color feedbackStatusColor(FeedbackStatus status) {
  switch (status) {
    case FeedbackStatus.open:
      return Colors.blue;
    case FeedbackStatus.planned:
      return Colors.purple;
    case FeedbackStatus.started:
      return Colors.orange;
    case FeedbackStatus.completed:
      return Colors.green;
    case FeedbackStatus.declined:
    case FeedbackStatus.duplicate:
      return Colors.grey;
  }
}

class FeedbackBadge extends StatelessWidget {
  const FeedbackBadge({super.key, required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        border: Border.all(color: color.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class FeedbackBadges extends StatelessWidget {
  const FeedbackBadges({super.key, required this.item, required this.tags});

  final FeedbackItem item;
  final List<FeedbackTag> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        if (item.isBug && !item.isReport) const FeedbackBadge(text: 'Bug', color: Colors.red),
        if (item.isReport) const FeedbackBadge(text: 'Report', color: Colors.red),
        if (item.isPrivate) const FeedbackBadge(text: 'Private', color: Colors.red),
        FeedbackBadge(text: item.status.label, color: feedbackStatusColor(item.status)),
        for (final tag in feedbackTagsOf(item, tags)) FeedbackBadge(text: tag.name, color: Color(tag.color)),
      ],
    );
  }
}

class FeedbackVotes extends StatelessWidget {
  const FeedbackVotes({super.key, required this.count, this.voted = false, this.onTap});

  final int count;
  final bool voted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = voted ? Colors.blue : null;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 42,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.arrow_drop_up, size: 26, color: color),
            Text(
              '$count',
              style: TextStyle(fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

void showFeedbackError(Object error) {
  final reason = error is FeedbackCallError ? error.reason : null;
  if (reason == 'mod_locked') Get.find<FeedbackAccountController>().markLocked();
  BotToast.showText(
    text: error is FeedbackCallError ? error.text : feedbackReasonText(null),
    textStyle: const TextStyle(fontSize: 14, color: Colors.white),
    contentColor: Colors.orange[700]!,
    duration: const Duration(seconds: 3),
    contentPadding: const EdgeInsets.all(10),
  );
}

Future<bool> confirmFeedbackAction(BuildContext context, String title, String action) async {
  final answer = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: Text(action)),
      ],
    ),
  );
  return answer == true;
}

class FeedbackErrorView extends StatelessWidget {
  const FeedbackErrorView({super.key, required this.text, required this.onRetry, this.compact = false});

  final String text;
  final VoidCallback onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.cloud_off, size: compact ? 16 : 22, color: Colors.grey),
        const SizedBox(width: 8),
        Flexible(child: Text(text, style: const TextStyle(fontSize: 13))),
        TextButton(onPressed: onRetry, child: const Text('Retry')),
      ],
    );
    return Center(
      child: Padding(padding: EdgeInsets.all(compact ? 4 : 24), child: row),
    );
  }
}

class FeedbackPagedList<T> extends StatefulWidget {
  const FeedbackPagedList({super.key, required this.pager, required this.emptyText, required this.itemBuilder});

  final FeedbackPager<T> pager;
  final String emptyText;
  final Widget Function(T item) itemBuilder;

  @override
  State<FeedbackPagedList<T>> createState() => _FeedbackPagedListState<T>();
}

class _FeedbackPagedListState<T> extends State<FeedbackPagedList<T>> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 300) widget.pager.loadMore();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pager = widget.pager;
    final items = pager.items;
    if (items.isEmpty) {
      if (pager.failed) return FeedbackErrorView(text: pager.errorText, onRetry: pager.reload);
      if (pager.loading || pager.loadedAt == null) return const Center(child: CircularProgressIndicator());
      return Center(child: Text(widget.emptyText));
    }

    return RefreshIndicator(
      onRefresh: pager.reload,
      child: ListView.builder(
        controller: _scroll,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(10, 4, 10, 40),
        itemCount: items.length + 1,
        itemBuilder: (_, index) {
          if (index < items.length) return widget.itemBuilder(items[index]);
          if (pager.moreFailed) {
            return FeedbackErrorView(text: pager.errorText, onRetry: pager.loadMore, compact: true);
          }
          if (pager.loadingMore) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class FeedbackMarkdown extends StatelessWidget {
  const FeedbackMarkdown({super.key, required this.data, required this.themeProvider, required this.onOpenLink});

  final String data;
  final ThemeProvider themeProvider;
  final void Function(String url) onOpenLink;

  @override
  Widget build(BuildContext context) {
    final text = TextStyle(fontSize: 14, height: 1.4, color: themeProvider.mainText);
    return MarkdownBody(
      data: data,
      selectable: true,
      styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
        p: text,
        listBullet: text,
        a: const TextStyle(color: Colors.lightBlue, decoration: TextDecoration.underline),
        blockquote: text.copyWith(color: Colors.grey),
      ),
      onTapLink: (_, href, _) {
        if (isFeedbackWebUrl(href)) onOpenLink(href!);
      },
      imageBuilder: (uri, _, alt) {
        final url = uri.toString();
        if (!isFeedbackImageUrl(url)) {
          return GestureDetector(
            onTap: () => isFeedbackWebUrl(url) ? onOpenLink(url) : null,
            child: Text(
              alt?.isNotEmpty == true ? alt! : url,
              style: const TextStyle(color: Colors.lightBlue, decoration: TextDecoration.underline),
            ),
          );
        }
        return ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 360),
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) => progress == null
                ? child
                : const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
            errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined, color: Colors.grey),
          ),
        );
      },
    );
  }
}
