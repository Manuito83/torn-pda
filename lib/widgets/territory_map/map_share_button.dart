import 'package:material_ui/material_ui.dart';

class MapShareButton extends StatelessWidget {
  const MapShareButton({super.key, required this.onPicture, required this.onView, this.onVideo, this.onChat});

  final VoidCallback onPicture;
  final VoidCallback onView;

  // Null hides Video
  final VoidCallback? onVideo;
  final VoidCallback? onChat;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<VoidCallback>(
      style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
      icon: const Icon(Icons.share),
      tooltip: 'Share',
      onSelected: (action) => action(),
      itemBuilder: (_) => [
        mapMenuItem(Icons.image_outlined, 'Picture', onPicture, subtitle: 'The map as it is now'),
        mapMenuItem(Icons.link, 'View', onView, subtitle: 'A link that opens this part of the map'),
        if (onVideo case final onVideo?)
          mapMenuItem(Icons.movie_outlined, 'Video', onVideo, subtitle: 'The map over time'),
        if (onChat case final onChat?) mapMenuItem(Icons.forum_outlined, 'Send to faction chat', onChat),
      ],
    );
  }
}

PopupMenuItem<VoidCallback> mapMenuItem(
  IconData icon,
  String title,
  VoidCallback? action, {
  String? subtitle,
  bool enabled = true,
}) {
  return PopupMenuItem(
    value: action,
    enabled: enabled,
    child: ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      enabled: enabled,
      leading: Icon(icon),
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
    ),
  );
}
