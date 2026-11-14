import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/providers/webview_provider.dart';

class SplitAppSafeArea extends StatelessWidget {
  const SplitAppSafeArea({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final SplitSide? appSide = context.select<WebViewProvider, SplitSide?>((w) => w.splitAppSide);
    return SafeArea(left: appSide == SplitSide.left, right: appSide == SplitSide.right, child: child);
  }
}
