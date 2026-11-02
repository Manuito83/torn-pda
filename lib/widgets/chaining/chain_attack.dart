import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:torn_pda/models/chaining/ffscouter/ffscouter_targets_model.dart';
import 'package:torn_pda/models/chaining/retal_model.dart';
import 'package:torn_pda/providers/player_notes_controller.dart';
import 'package:torn_pda/providers/retals_controller.dart';
import 'package:torn_pda/providers/settings_provider.dart';
import 'package:torn_pda/providers/targets_provider.dart';
import 'package:torn_pda/providers/war_controller.dart';
import 'package:torn_pda/providers/webview_provider.dart';
import 'package:torn_pda/utils/number_formatter.dart';
import 'package:torn_pda/utils/shared_prefs.dart';
import 'package:torn_pda/widgets/webviews/chaining_payload.dart';
import 'package:torn_pda/widgets/webviews/webview_stackview.dart';
import 'package:url_launcher/url_launcher.dart';

/// One stop of the chaining browser
class ChainAttackTarget {
  final int id;
  final String? name;
  final String? note;
  final String? noteColor;

  const ChainAttackTarget(this.id, {this.name, this.note, this.noteColor});
}

/// Chaining browser in the Targets order
Future<void> attackFromTargets(
  BuildContext context,
  int? playerId, {
  String? name,
  required bool shortTap,
}) async {
  if (playerId == null) return;
  final targets = context.read<TargetsProvider>().allTargets;
  final from = targets.indexWhere((t) => t.playerId == playerId);
  final queue = from == -1
      ? [_withNote(playerId, name ?? '')]
      : [
          for (final t in targets.sublist(from))
            if (t.playerId != null) _withNote(t.playerId!, t.name),
        ];
  await openChainAttack(context, queue, shortTap: shortTap);
}

/// Chaining browser in the War page order
Future<void> attackFromWar(BuildContext context, int? memberId, String? name, {required bool shortTap}) async {
  if (memberId == null) return;
  final cards = Get.find<WarController>().orderedCardsDetails;
  final from = cards.indexWhere((c) => c.memberId == memberId);
  final queue = from == -1
      ? [_withNote(memberId, name)]
      : [
          for (final c in cards.sublist(from))
            if (c.memberId != null) _withNote(c.memberId!, c.name),
        ];
  await openChainAttack(context, queue, shortTap: shortTap, war: true);
}

/// Chaining browser in the Target finder order
Future<void> attackFromTargetFinder(
  BuildContext context,
  List<FFScouterTarget> targets,
  FFScouterTarget target, {
  required bool shortTap,
}) async {
  if (target.playerId == null) return;
  final from = targets.indexWhere((t) => t.playerId == target.playerId);
  final queue = [
    for (final t in from == -1 ? [target] : targets.sublist(from))
      if (t.playerId != null) _fromFinder(t),
  ];
  await openChainAttack(context, queue, shortTap: shortTap, finder: true);
}

/// Chaining browser in the Retals order
Future<void> attackFromRetals(BuildContext context, Retal retal) async {
  final id = retal.retalId;
  if (id == null) return;
  final r = Get.put(RetalsController());
  final cards = r.orderedCardsDetails;
  final from = cards.indexWhere((c) => c.retalId == id);
  final queue = from == -1
      ? [ChainAttackTarget(id, name: retal.name, note: retal.personalNote, noteColor: retal.personalNoteColor)]
      : [
          for (final c in cards.sublist(from))
            if (c.retalId != null)
              ChainAttackTarget(c.retalId!, name: c.name, note: c.personalNote, noteColor: c.personalNoteColor),
        ];
  r.browserIsOpen = true;
  try {
    await openChainAttack(context, queue, shortTap: true, war: true);
  } finally {
    r.browserIsOpen = false;
  }
}

/// Loot Rangers order, time on the first
Future<void> attackFromLootRangers(
  BuildContext context,
  List<String> ids,
  List<String?> names,
  String timeNote, {
  bool fromNotification = false,
}) {
  final queue = [
    for (var i = 0; i < ids.length; i++)
      if (int.tryParse(ids[i]) case final id?)
        ChainAttackTarget(id, name: names.elementAtOrNull(i), note: i == 0 ? timeNote : '', noteColor: 'green'),
  ];
  return openChainAttack(context, queue, shortTap: true, loot: true, fromNotification: fromNotification);
}

/// Opens the queue, or one target outside
Future<void> openChainAttack(
  BuildContext context,
  List<ChainAttackTarget> targets, {
  required bool shortTap,
  bool war = false,
  bool finder = false,
  bool loot = false,
  bool fromNotification = false,
}) async {
  if (targets.isEmpty) return;
  final url = 'https://www.torn.com/page.php?sid=attack&user2ID=${targets.first.id}';
  if (context.read<SettingsProvider>().currentBrowser == BrowserSetting.external) {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
    return;
  }

  final webViewProvider = context.read<WebViewProvider>();
  final payload = ChainingPayload()
    ..war = war
    ..attackIdList = [for (final t in targets) t.id.toString()]
    ..attackNameList = [for (final t in targets) t.name]
    ..attackNotesList = [for (final t in targets) t.note]
    ..attackNotesColorList = [for (final t in targets) t.noteColor];
  if (finder || loot) {
    payload
      ..showNotes = true
      ..showBlankNotes = false
      ..showOnlineFactionWarning = false
      ..skipAutoUpdate = finder;
  } else {
    final showNotes = await Prefs().getShowTargetsNotes();
    final showBlankNotes = await Prefs().getShowBlankTargetsNotes();
    final showOnlineFactionWarning = await Prefs().getShowOnlineFactionWarning();
    if (!context.mounted) return;
    payload
      ..showNotes = showNotes
      ..showBlankNotes = showBlankNotes
      ..showOnlineFactionWarning = showOnlineFactionWarning;
  }

  await webViewProvider.openBrowserPreference(
    context: context,
    url: url,
    browserTapType: shortTap ? BrowserTapType.chainShort : BrowserTapType.chainLong,
    fromNotification: fromNotification,
    isChainingBrowser: true,
    chainingPayload: payload,
  );
}

ChainAttackTarget _withNote(int id, String? name) {
  final note = Get.find<PlayerNotesController>().getNoteForPlayer(id.toString());
  return ChainAttackTarget(id, name: name, note: note?.note, noteColor: note?.color);
}

/// FFScouter estimate ahead of the player note
ChainAttackTarget _fromFinder(FFScouterTarget t) {
  final id = t.playerId!;
  final bsText = t.bsEstimateHuman ?? (t.bsEstimate != null ? formatBigNumbers(t.bsEstimate!) : null);
  final ffText = t.fairFight?.toStringAsFixed(2);
  final parts = <String>[if (bsText != null) 'BS: $bsText', if (ffText != null) 'FF: $ffText'];
  final playerNote = Get.find<PlayerNotesController>().getNoteForPlayer(id.toString());
  if (playerNote != null && playerNote.note.isNotEmpty) parts.add(playerNote.note);
  return ChainAttackTarget(
    id,
    name: t.name,
    note: parts.isNotEmpty ? parts.join(' | ') : null,
    noteColor: playerNote?.color ?? '',
  );
}
