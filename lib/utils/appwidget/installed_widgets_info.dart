import 'dart:io';

import 'package:home_widget/home_widget.dart';

class InstalledWidgetsInfo {
  final bool isPdaWidgetInstalled;
  final bool isRankedWarWidgetInstalled;

  InstalledWidgetsInfo({
    this.isPdaWidgetInstalled = false,
    this.isRankedWarWidgetInstalled = false,
  });

  bool get anyWidgetInstalled => isPdaWidgetInstalled || isRankedWarWidgetInstalled;
}

Future<InstalledWidgetsInfo> getInstalledWidgetsInfo() async {
  final installedWidgets = await HomeWidget.getInstalledWidgets();
  if (installedWidgets.isEmpty) {
    return InstalledWidgetsInfo();
  }

  bool isPdaWidgetInstalled = false;
  bool isRankedWarWidgetInstalled = false;

  if (Platform.isAndroid) {
    isPdaWidgetInstalled = installedWidgets.any((w) => w.androidClassName?.contains('HomeWidgetTornPda') ?? false);
    isRankedWarWidgetInstalled =
        installedWidgets.any((w) => w.androidClassName?.contains('HomeWidgetRankedWar') ?? false);
  } else if (Platform.isIOS) {
    isPdaWidgetInstalled = installedWidgets.any((w) => w.iOSKind == 'HomeWidgetTornPda');
    isRankedWarWidgetInstalled = installedWidgets.any((w) => w.iOSKind == 'HomeWidgetRankedWar');
  }

  return InstalledWidgetsInfo(
    isPdaWidgetInstalled: isPdaWidgetInstalled,
    isRankedWarWidgetInstalled: isRankedWarWidgetInstalled,
  );
}
