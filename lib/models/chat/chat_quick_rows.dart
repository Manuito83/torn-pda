const List<String> chatQuickActionIds = [
  'price',
  'player',
  'tab',
  'script',
  'status',
  'wiki',
  'time',
  'bank',
  'emoji',
  'replies',
];

const String chatQuickRowBreak2 = 'row2';
const String chatQuickRowBreak3 = 'row3';
const List<String> chatQuickRowBreaks = [chatQuickRowBreak2, chatQuickRowBreak3];

/// Editor marker, disabled actions sit below it
const String chatQuickOffBreak = 'off';

const List<int> chatQuickRowsOptions = [1, 2, 3];

/// One break less than the action rows
List<String> chatQuickActiveBreaks(int actionRows) =>
    chatQuickRowBreaks.take((actionRows - 1).clamp(0, chatQuickRowBreaks.length)).toList();

List<String> chatQuickWithAll(List<String> saved) {
  final ids = [...saved.where((id) => chatQuickActionIds.contains(id) || chatQuickRowBreaks.contains(id)).toSet()];
  return [...ids, ...chatQuickActionIds.where((id) => !saved.contains(id))];
}

/// A missing break splits the last row
List<String> chatQuickWithActiveBreaks(List<String> saved, List<String> activeBreaks, bool Function(String id) shown) {
  final order = [...saved];
  for (final id in activeBreaks.where((b) => !order.contains(b))) {
    final start = order.lastIndexWhere((e) => chatQuickRowBreaks.contains(e) && shown(e)) + 1;
    final end = order.lastIndexWhere(shown) + 1;
    order.insert(start + (end - start + 1) ~/ 2, id);
  }
  return order;
}

/// Shown, the off marker, then disabled
List<String> chatQuickEditor(List<String> order, bool Function(String id) shown) => [
  for (final id in order)
    if (shown(id)) id,
  chatQuickOffBreak,
  for (final id in order)
    if (!chatQuickRowBreaks.contains(id) && !shown(id)) id,
];

/// Off is null for a row break
({List<String> order, String id, bool? off}) chatQuickMoved(
  List<String> editor,
  int from,
  int to, {
  required List<String> saved,
  required List<String> activeBreaks,
}) {
  final list = [...editor];
  final id = list.removeAt(from);
  list.insert(to, id);
  var at = list.indexOf(chatQuickOffBreak);
  final isBreak = chatQuickRowBreaks.contains(id);
  if (isBreak && to > at) {
    list
      ..remove(id)
      ..insert(at, id);
    at = list.indexOf(chatQuickOffBreak);
  }
  list.removeAt(at);
  for (final parked in chatQuickRowBreaks.where((b) => !activeBreaks.contains(b))) {
    final was = saved.indexOf(parked);
    if (was >= 0) list.insert(was.clamp(0, at), parked);
  }
  final first = list.indexOf(chatQuickRowBreak2);
  final second = list.indexOf(chatQuickRowBreak3);
  if (first > second && second >= 0) {
    list[first] = chatQuickRowBreak3;
    list[second] = chatQuickRowBreak2;
  }
  return (order: list, id: id, off: isBreak ? null : to > at);
}

/// Extra breaks are ignored
List<List<String>> chatQuickRowsSplit(List<String> order, {required int rows}) {
  final split = [<String>[]];
  for (final id in order) {
    if (chatQuickActionIds.contains(id)) {
      split.last.add(id);
    } else if (chatQuickRowBreaks.contains(id) && split.length < rows) {
      split.add([]);
    }
  }
  while (split.length < rows) {
    split.add([]);
  }
  return split;
}
