import 'package:flutter/material.dart';
import 'package:torn_pda/pages/chat/settings/chat_settings_subpage.dart';
import 'package:torn_pda/providers/chat/chat_image_upload.dart';
import 'package:torn_pda/widgets/chat/native_chat.dart';

class ChatUploadSettingsPage extends StatelessWidget {
  const ChatUploadSettingsPage({super.key});

  Future<void> _editCredential(BuildContext context, ChatImageHost host) async {
    var typed = NativeChat.prefs.credentialFor(host);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${host.label} ${host.credentialName}'),
        content: TextFormField(
          initialValue: typed,
          onChanged: (v) => typed = v,
          autofocus: true,
          autocorrect: false,
          enableSuggestions: false,
          decoration: InputDecoration(hintText: 'Paste the ${host.credentialName}'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, ''), child: const Text('Clear')),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, typed), child: const Text('Save')),
        ],
      ),
    );
    if (value != null) NativeChat.prefs.setCredential(host, value);
  }

  @override
  Widget build(BuildContext context) {
    return ChatSettingsSubpage(
      title: 'Image upload',
      builder: (context) {
        final theme = Theme.of(context);
        final prefs = NativeChat.prefs;
        final host = prefs.imageHost;
        return [
          ListTile(
            leading: const Icon(Icons.cloud_upload_outlined),
            title: const Text('Image host'),
            trailing: DropdownButton<ChatImageHost>(
              value: host,
              underline: const SizedBox(),
              items: [for (final h in ChatImageHost.values) DropdownMenuItem(value: h, child: Text(h.label))],
              onChanged: (h) => h == null ? null : prefs.setImageHost(h),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Images you attach go to ${host.label}, a third party, and anyone with the link can see '
              'them. ${switch (host) {
                ChatImageHost.imgur => 'It needs the Client-ID of a free imgur app registered with anonymous use',
                ChatImageHost.imgbb => 'It needs the API key of a free ImgBB account',
                ChatImageHost.catbox => 'It works without an account, a userhash keeps the uploads in yours',
              }}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.key_rounded),
            title: Text('${host.label} ${host.credentialName}${host.needsCredential ? '' : ' (optional)'}'),
            subtitle: Text(
              prefs.credentialFor(host).isNotEmpty
                  ? 'Set'
                  : host.needsCredential
                  ? 'Not set, image upload is off'
                  : 'Not set, uploads are anonymous',
            ),
            trailing: const Icon(Icons.edit_rounded),
            onTap: () => _editCredential(context, host),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => NativeChat.openUrl(host.registerUrl),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text(
                  host.needsCredential ? 'Get your ${host.credentialName} at ${host.label}' : 'Open ${host.label}',
                ),
              ),
            ),
          ),
        ];
      },
    );
  }
}
