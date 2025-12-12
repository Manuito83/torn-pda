import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';

/// Opens a dialog and ensures touch interaction is restored on iOS afterwards
Future<T?> showWebviewDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
  Color? barrierColor,
  String? barrierLabel,
  Offset? anchorPoint,
}) async {
  final result = await showDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    barrierColor: barrierColor,
    barrierLabel: barrierLabel,
    anchorPoint: anchorPoint,
    builder: builder,
  );

  try {
    await context.read<WebViewProvider>().notifyDialogClosed();
  } catch (_) {
    // Provider might be unavailable depending on the caller lifecycle
  }

  return result;
}
