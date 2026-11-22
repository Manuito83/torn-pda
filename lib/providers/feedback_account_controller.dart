import 'package:get/get.dart';
import 'package:torn_pda/models/feedback/feedback_account.dart';
import 'package:torn_pda/utils/feedback_functions.dart';

const _idsPerCall = 50;

class FeedbackAccountController extends GetxController {
  FeedbackAccountController({
    Future<Map<String, dynamic>> Function(List<String> ids)? loadState,
    Future<int> Function(String id, bool on)? vote,
    Future<void> Function(String id, bool on)? subscribe,
    Future<void> Function(bool on)? subscribeAll,
    Future<DateTime> Function(String pin)? unlock,
  }) : _loadState = loadState ?? fetchFeedbackState,
       _vote = vote ?? voteFeedback,
       _subscribe = subscribe ?? subscribeFeedback,
       _subscribeAll = subscribeAll ?? subscribeAllFeedback,
       _unlock = unlock ?? unlockFeedbackModeration;

  final Future<Map<String, dynamic>> Function(List<String> ids) _loadState;
  final Future<int> Function(String id, bool on) _vote;
  final Future<void> Function(String id, bool on) _subscribe;
  final Future<void> Function(bool on) _subscribeAll;
  final Future<DateTime> Function(String pin) _unlock;

  FeedbackAccount _account = const FeedbackAccount();
  final _asked = <String>{};
  final _pending = <String>{};
  final _busy = <String>{};
  bool _loading = false;

  FeedbackAccount get account => _account;
  bool get unlocked => _account.isUnlocked(DateTime.now());

  bool isVoted(String id) => _account.votedIds.contains(id);

  bool isSubscribed(String id) => _account.subscribedIds.contains(id);

  bool isLocked(String id) => _account.lockedIds.contains(id);

  // Only ids not asked before
  Future<void> load(List<String> ids) async {
    _pending.addAll(ids.where((id) => !_asked.contains(id)));
    if (_loading || (_account.known && _pending.isEmpty)) return;
    _loading = true;
    try {
      do {
        final batch = _pending.take(_idsPerCall).toList();
        _account = _account.fromState(await _loadState(batch), batch);
        _asked.addAll(batch);
        _pending.removeAll(batch);
        update();
      } while (_pending.isNotEmpty);
    } catch (_) {
      // Marks stay empty
    }
    _loading = false;
  }

  Future<void> reload() async {
    _asked.clear();
    _pending.clear();
    _account = const FeedbackAccount();
    await load([]);
  }

  void _requireWrite() {
    if (_account.known && !_account.canWrite) throw FeedbackCallError(_account.reason ?? 'not_verified');
  }

  // Flip first, undo on failure
  Future<T?> _toggle<T>(String key, Future<T> Function() run, void Function() flip) async {
    if (_busy.contains(key)) return null;
    _requireWrite();
    _busy.add(key);
    flip();
    update();
    try {
      return await run();
    } catch (_) {
      flip();
      rethrow;
    } finally {
      _busy.remove(key);
      update();
    }
  }

  Set<String> _flipped(Set<String> ids, String id) => ids.contains(id) ? ({...ids}..remove(id)) : {...ids, id};

  // New count, null when ignored
  Future<int?> toggleVote(String id, {void Function(int delta)? onDelta}) {
    return _toggle('vote_$id', () => _vote(id, isVoted(id)), () {
      onDelta?.call(isVoted(id) ? -1 : 1);
      _account = _account.copyWith(votedIds: _flipped(_account.votedIds, id));
    });
  }

  Future<void> toggleSubscription(String id) async {
    await _toggle(
      'sub_$id',
      () => _subscribe(id, isSubscribed(id)),
      () => _account = _account.copyWith(subscribedIds: _flipped(_account.subscribedIds, id)),
    );
  }

  Future<void> toggleSubscribeAll() async {
    await _toggle(
      'all',
      () => _subscribeAll(_account.subscribedToAll),
      () => _account = _account.copyWith(subscribedToAll: !_account.subscribedToAll),
    );
  }

  Future<void> unlock(String pin) async {
    final until = await _unlock(pin);
    _account = _account.copyWith(modUnlockedUntil: until);
    update();
  }

  // The server ended the session
  void markLocked() {
    _account = _account.copyWith(clearUnlock: true);
    update();
  }
}
