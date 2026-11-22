import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/drawer.dart';
import 'package:torn_pda/providers/settings_provider.dart';

// Route names and back for sub pages
mixin FeedbackSubRoute<T extends StatefulWidget> on State<T> {
  late final StreamSubscription _backSubscription;
  late final String _previousName;
  late final bool _previousDrawer;

  String get subRouteName;

  @override
  void initState() {
    super.initState();
    _previousName = routeName;
    _previousDrawer = routeWithDrawer;
    routeWithDrawer = false;
    routeName = subRouteName;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    _backSubscription = settings.willPopShouldGoBackStream.stream.listen((_) {
      if (mounted && routeName == subRouteName) goBack();
    });
  }

  void goBack() => Navigator.of(context).pop();

  @override
  void dispose() {
    _backSubscription.cancel();
    routeName = _previousName;
    routeWithDrawer = _previousDrawer;
    super.dispose();
  }
}
