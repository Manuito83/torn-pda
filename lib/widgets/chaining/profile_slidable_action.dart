import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';

SlidableAction profileSlidableAction(int? playerId) {
  return SlidableAction(
    label: 'Profile',
    backgroundColor: Colors.teal,
    icon: MdiIcons.accountOutline,
    onPressed: (context) {
      if (playerId == null) return;
      Provider.of<WebViewProvider>(context, listen: false).openBrowserPreference(
        context: context,
        url: 'https://www.torn.com/profiles.php?XID=$playerId',
        browserTapType: BrowserTapType.short,
      );
    },
  );
}
