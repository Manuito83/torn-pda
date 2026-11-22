import 'package:material_ui/material_ui.dart';
import 'package:torn_pda/models/chat/chat_links.dart';
import 'package:torn_pda/models/territory_map/map_share.dart';
import 'package:torn_pda/widgets/chat/chat_link_widgets.dart';
import 'package:torn_pda/widgets/territory_map/map_thumbnail.dart';

class ChatMapCard extends StatelessWidget {
  const ChatMapCard({super.key, required this.link, required this.view, required this.color});

  final ChatLink link;
  final SharedMapView view;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChatInsertFrame(
      color: color,
      child: InkWell(
        onTap: () => openChatLink(context, link),
        onLongPress: () => showChatLinkMenu(context, link),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              ExcludeSemantics(child: MapThumbnail(key: ValueKey(link.url), camera: view.camera, aspect: 2)),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: Text(
                  link.detail == null ? link.title : '${link.title} - ${link.detail}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(color: color, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
