import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/models/feedback/feedback_attachment.dart';
import 'package:torn_pda/providers/feedback_upload_queue.dart';

// Attachments already sent
class FeedbackAttachmentStrip extends StatelessWidget {
  const FeedbackAttachmentStrip({super.key, required this.attachments, required this.onOpen, this.onDelete});

  final List<FeedbackAttachment> attachments;
  final void Function(FeedbackAttachment attachment) onOpen;
  final void Function(FeedbackAttachment attachment)? onDelete;

  @override
  Widget build(BuildContext context) {
    if (attachments.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final attachment in attachments)
            _AttachmentTile(
              attachment: attachment,
              onOpen: () => onOpen(attachment),
              onDelete: onDelete == null ? null : () => onDelete!(attachment),
            ),
        ],
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  const _AttachmentTile({required this.attachment, required this.onOpen, this.onDelete});

  final FeedbackAttachment attachment;
  final VoidCallback onOpen;
  final VoidCallback? onDelete;

  static const _size = 92.0;

  Widget _content() {
    final url = attachment.url;
    if (attachment.isImage && url != null) {
      return Image.network(
        url,
        width: _size,
        height: _size,
        fit: BoxFit.cover,
        cacheWidth: 300,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined, color: Colors.grey),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(attachment.isVideo ? Icons.play_circle_outline : Icons.image_outlined, size: 30, color: Colors.grey),
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
          child: Text(
            attachment.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.grey),
          ),
        ),
        Text(feedbackSizeText(attachment.size), style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: Stack(
        children: [
          Positioned.fill(
            child: Material(
              color: Colors.grey.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: InkWell(onTap: onOpen, child: _content()),
            ),
          ),
          if (attachment.isVideo && attachment.url != null)
            const Positioned(left: 4, bottom: 4, child: Icon(Icons.play_circle_fill, size: 20, color: Colors.white)),
          if (onDelete != null)
            Positioned(
              top: 0,
              right: 0,
              child: InkWell(
                onTap: onDelete,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Files chosen, with the add button
class FeedbackPickList extends StatelessWidget {
  const FeedbackPickList({super.key, required this.queue, this.enabled = true});

  final FeedbackUploadQueue queue;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: queue,
      builder: (context, _) {
        final busy = queue.uploading;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final pick in queue.picks)
              _PickRow(pick: pick, onRemove: busy || !enabled ? null : () => queue.remove(pick)),
            if (queue.problem != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(queue.problem!, style: const TextStyle(color: Colors.orange, fontSize: 12)),
              ),
            if (!queue.isFull)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: busy || !enabled ? null : queue.add,
                  icon: const Icon(Icons.attach_file, size: 18),
                  label: const Text('Attach'),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PickRow extends StatelessWidget {
  const _PickRow({required this.pick, required this.onRemove});

  final FeedbackPick pick;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final failed = pick.state == FeedbackPickState.failed;
    final uploading = pick.state == FeedbackPickState.uploading;
    final done = pick.state == FeedbackPickState.done;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(
            done
                ? Icons.check_circle_outline
                : (isFeedbackVideoType(pick.contentType) ? Icons.videocam_outlined : Icons.image_outlined),
            size: 18,
            color: done ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pick.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13)),
                if (uploading) LinearProgressIndicator(value: pick.progress > 0 ? pick.progress : null),
                if (failed && pick.error != null)
                  Text(pick.error!, style: const TextStyle(color: Colors.orange, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(feedbackSizeText(pick.size), style: const TextStyle(fontSize: 11, color: Colors.grey)),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              tooltip: 'Remove',
              visualDensity: VisualDensity.compact,
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}

void showFeedbackImage(BuildContext context, String url) {
  showDialog<void>(
    context: context,
    builder: (context) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              child: Center(
                child: Image.network(
                  url,
                  fit: BoxFit.contain,
                  loadingBuilder: (_, child, progress) =>
                      progress == null ? child : const Center(child: CircularProgressIndicator()),
                  errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined, color: Colors.grey, size: 48),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
