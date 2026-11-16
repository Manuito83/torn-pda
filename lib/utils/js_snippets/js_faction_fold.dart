// Project imports:
import 'package:torn_pda/utils/js_snippets/js_quick_items.dart';
import 'package:torn_pda/utils/js_snippets/remote_snippets.dart';

// Fold the faction profile description (RC-overridable)
String factionDescriptionFoldJS({required bool always}) {
  return snippetWithArgs(RemoteSnippets.factionDescriptionFold, '__pdaFactionFoldArgs', {'always': always});
}

// faction_description_fold base
// RC keys: snippet_faction_description_fold_js + snippet_faction_description_fold_version
String factionDescriptionFoldBaseJS() {
  return '''
    (function() {
      var args = window.__pdaFactionFoldArgs || {};
      var HEAD = '.faction-title[data-title="description"]';
      var BODY = '.faction-description';

      // GIF, or taller than the window
      function isLargeOrAnimated(box) {
        var imgs = box.querySelectorAll('img');
        for (var i = 0; i < imgs.length; i++) {
          var src = (imgs[i].currentSrc || imgs[i].src || '').split('?')[0].split('#')[0].toLowerCase();
          if (src.endsWith('.gif')) return true;
          var h = Math.max(imgs[i].naturalHeight, imgs[i].getBoundingClientRect().height);
          if (h > window.innerHeight) return true;
        }
        return false;
      }

      // Mobile: use Torn's own toggle
      function fold(box, head) {
        if (document.body.classList.contains('r')) {
          var open = (box.getAttribute('class') || '').indexOf('active___') > -1;
          if (!open || window.__pdaFoldTouched) return;
          box.__pdaFoldDone = true;
          head.click();
          return;
        }
        box.__pdaFoldDone = true;
        box.classList.add('pda-fold');
        box.classList.remove('pda-open');
        head.classList.add('pda-fold-head');
        head.classList.remove('pda-open');
      }

      function apply() {
        var box = document.querySelector(BODY);
        var head = document.querySelector(HEAD);
        if (!box || !head || box.__pdaFoldDone) return;
        if (!args.always && !isLargeOrAnimated(box)) {
          box.querySelectorAll('img').forEach(function(img) {
            if (img.__pdaFoldWatch) return;
            img.__pdaFoldWatch = true;
            img.addEventListener('load', apply);
          });
          return;
        }
        fold(box, head);
      }

      if (!document.getElementById('pda-faction-fold-style')) {
        var style = document.createElement('style');
        style.id = 'pda-faction-fold-style';
        style.textContent =
          '.faction-description.pda-fold:not(.pda-open){display:none !important;}' +
          '.faction-title.pda-fold-head{cursor:pointer;}' +
          '.faction-title.pda-fold-head [class*="titleArrow___"]{display:inline-block;float:none;vertical-align:middle;' +
          'margin:0 8px 2px 0;border-left:7px solid currentColor !important;}' +
          '.faction-title.pda-fold-head.pda-open [class*="titleArrow___"]{transform:rotate(90deg);}' +
          '.faction-title.pda-fold-head:not(.pda-open)::after{content:" (tap to show)";}';
        document.head.appendChild(style);
      }

      if (!window.__pdaFoldClick) {
        window.__pdaFoldClick = true;
        document.addEventListener('click', function(e) {
          var head = e.target.closest ? e.target.closest(HEAD) : null;
          if (!head) return;
          if (e.isTrusted) window.__pdaFoldTouched = true;
          var box = document.querySelector(BODY);
          if (!box || !head.classList.contains('pda-fold-head')) return;
          box.classList.toggle('pda-open');
          head.classList.toggle('pda-open');
        }, true);
      }

      var frame = 0;
      if (window.pdaFactionFoldObserver) window.pdaFactionFoldObserver.disconnect();
      window.pdaFactionFoldObserver = new MutationObserver(function() {
        if (frame) return;
        frame = requestAnimationFrame(function() {
          frame = 0;
          apply();
        });
      });
      window.pdaFactionFoldObserver.observe(document.body, { childList: true, subtree: true });
      apply();
      return 123;
    })();
  ''';
}
