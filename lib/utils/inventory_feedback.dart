// Package imports:
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/material.dart';

// Project imports:
import 'package:torn_pda/providers/inventory_provider.dart';

void inventoryToast(String text) {
  BotToast.showText(
    text: text,
    textStyle: const TextStyle(fontSize: 13, color: Colors.white),
    contentColor: Colors.grey[700]!,
    duration: const Duration(seconds: 3),
    contentPadding: const EdgeInsets.all(10),
  );
}

String inventoryLoadingMessage(Set<String> pending) =>
    "Loading inventory: ${pending.length} API call${pending.length == 1 ? '' : 's'}";

String inventoryUpToDateMessage(InventoryProvider provider, Set<String> categories) {
  if (categories.isEmpty) return "Nothing here needs your inventory";
  final DateTime? next = provider.nextRefresh(categories);
  if (next == null) return "Inventory is up to date";
  final int minutes = next.difference(DateTime.now()).inMinutes;
  if (minutes < 1) return "Inventory is up to date, Torn refreshes it in less than a minute";
  return "Inventory is up to date, Torn refreshes it in $minutes min";
}
