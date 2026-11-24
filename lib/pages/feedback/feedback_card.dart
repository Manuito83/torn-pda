import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/models/feedback/feedback_models.dart';
import 'package:torn_pda/pages/feedback/feedback_widgets.dart';

class FeedbackCard extends StatelessWidget {
  const FeedbackCard({
    super.key,
    required this.item,
    required this.tags,
    required this.onTap,
    this.voted = false,
    this.onVote,
  });

  final FeedbackItem item;
  final List<FeedbackTag> tags;
  final bool voted;
  final VoidCallback onTap;
  final VoidCallback? onVote;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 12, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.isReport)
                const SizedBox(width: 8)
              else
                FeedbackVotes(count: item.votesCount, voted: voted, onTap: onVote),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.heading,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    const SizedBox(height: 6),
                    FeedbackBadges(item: item, tags: tags),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline, size: 13, color: Colors.grey),
                        const SizedBox(width: 3),
                        Text('${item.commentsCount}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            '${item.authorName} - ${feedbackDate(item.createdAt, DateTime.now())}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
