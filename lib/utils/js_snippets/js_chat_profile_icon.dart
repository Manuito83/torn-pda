import 'package:flutter_inappwebview/flutter_inappwebview.dart';

const String chatProfileIconHandler = 'PDA_chatProfileIcon';

final UserScript chatProfileIconScript = UserScript(
  groupName: 'pda_chatProfileIcon',
  injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
  source:
      """
    (function () {
      var host = location.hostname;
      if (host !== 'torn.com' && !host.endsWith('.torn.com')) return;
      var replaying = false;
      window.addEventListener('chat.openChannel', function (e) {
        if (replaying) return;
        var detail = e.detail;
        var stopped = false;
        var replayed = false;
        var replay = function () {
          if (replayed) return;
          replayed = true;
          replaying = true;
          try { window.dispatchEvent(new CustomEvent(e.type, { detail: detail })); } finally { replaying = false; }
        };
        try {
          var bridge = window.flutter_inappwebview;
          if (!bridge || !bridge.callHandler || !detail || detail.pda || detail.userId == null) return;
          e.stopImmediatePropagation();
          stopped = true;
          var result = bridge.callHandler('$chatProfileIconHandler', String(detail.userId));
          if (!result || typeof result.then !== 'function') {
            replay();
            return;
          }
          result.then(function (done) {
            if (done !== true) replay();
          }, replay);
        } catch (err) {
          if (stopped) replay();
        }
      }, true);
    })();
  """,
);
