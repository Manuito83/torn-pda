import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:get/get.dart';
import 'package:torn_pda/providers/chain_status_controller.dart';

const String chainWebHandler = 'PDA_chainWeb';

const String chainWebReader = r"""
(function () {
  var host = location.hostname;
  if (host !== 'torn.com' && !host.endsWith('.torn.com')) return;
  if (window.__pdaChainReader) {
    window.__pdaChainReader.check(true);
    return;
  }

  var BAR = 'a[class*="chainBar___"]';
  var store = null;
  var last = null;

  function nowSec() {
    // Torn clock corrected by the server
    if (typeof window.getCurrentTimestamp === 'function') {
      return Math.ceil(window.getCurrentTimestamp() / 1000);
    }
    return Math.ceil(Date.now() / 1000);
  }

  function fiberOf(el) {
    var keys = Object.keys(el);
    for (var i = 0; i < keys.length; i++) {
      if (keys[i].indexOf('__reactFiber') === 0) return el[keys[i]];
    }
    return null;
  }

  function findStore(el) {
    var f = el ? fiberOf(el) : null;
    var n = 0;
    while (f && n < 80) {
      var p = f.memoizedProps;
      if (p && p.value && p.value.store && typeof p.value.store.getState === 'function') {
        return p.value.store;
      }
      f = f.return;
      n++;
    }
    return null;
  }

  function attachStore(el) {
    if (store) return;
    var s = findStore(el) || findStore(document.getElementById('sidebar'));
    if (!s) return;
    try {
      if (!s.getState().sidebar.bars.chain) return;
    } catch (e) {
      return;
    }
    store = s;
    store.subscribe(function () {
      check(false);
    });
  }

  function fromStore() {
    var c;
    try {
      c = store.getState().sidebar.bars.chain;
    } catch (e) {
      return null;
    }
    if (!c) return null;
    var now = nowSec();
    var cd = c.endCoolDownTimestamp ? Math.max(0, c.endCoolDownTimestamp - now) : 0;
    return {
      // Cooldown shows the max reached, like Torn
      current: cd > 0 ? +c.max || 0 : +c.amount || 0,
      max: +c.max || null,
      timeout: c.timestampToUpdate ? Math.max(0, c.timestampToUpdate - now) : 0,
      cooldown: cd,
    };
  }

  function parseNum(t) {
    var m = /^([\d.,]+)(k?)$/i.exec(t);
    if (!m) return null;
    var n = parseFloat(m[1].replace(/,/g, ''));
    return m[2] ? Math.round(n * 1000) : n;
  }

  function parseTime(t) {
    if (!t) return null;
    t = t.replace(/[()\s]/g, '');
    if (t.indexOf(':') >= 0) {
      var p = t.split(':'), s = 0;
      for (var i = 0; i < p.length; i++) s = s * 60 + (parseInt(p[i], 10) || 0);
      return s;
    }
    var u = { d: 86400, h: 3600, m: 60, s: 1 }, r = /(\d+)([dhms])/g, m, tot = 0, hit = false;
    while ((m = r.exec(t))) {
      tot += +m[1] * u[m[2]];
      hit = true;
    }
    return hit ? tot : null;
  }

  function fromDom(el) {
    var v = el.querySelector('[class*="barValue___"]');
    var t = el.querySelector('[class*="barTimeLeft___"]');
    var pr = el.querySelector('[class*="progress___"]');
    if (!v) return null;
    var parts = v.textContent.replace(/\s/g, '').split('/');
    var cur = parseNum(parts[0]);
    var max = parts.length > 1 ? parseNum(parts[1]) : null;
    var secs = t ? parseTime(t.textContent) : null;
    var inCd = !!(pr && /cooldown___/.test(pr.className));
    if (inCd && max === null) max = cur;
    return {
      current: cur,
      max: max,
      timeout: inCd ? 0 : secs,
      cooldown: inCd ? secs : 0,
    };
  }

  var ATTACK = /^\/(page|loader)\.php$/.test(location.pathname) && /[?&]sid=attack/.test(location.search);
  var attackStore = null;

  function attachAttack() {
    if (attackStore) return;
    var roots = document.querySelectorAll('[class*="coreWrap___"], [class*="titleContainer___"]');
    for (var i = 0; i < roots.length && !attackStore; i++) {
      var s = findStore(roots[i]);
      try {
        if (s && s.getState().attack.attackerUser) attackStore = s;
      } catch (e) {}
    }
    if (attackStore) {
      attackStore.subscribe(function () {
        check(false);
      });
    }
  }

  // Attack header: "808 (03:46)"
  function fromAttack() {
    attachAttack();
    var u;
    try {
      u = attackStore.getState().attack.attackerUser;
    } catch (e) {
      return null;
    }
    if (!u || typeof u.chain !== 'number' || u.chain <= 0) return null;
    var secs = null;
    var label = document.querySelector('[class*="labelTitle___"]');
    var m = label ? /^\s*([\d,]+)\s*(\([\d:\s]+\))/.exec(label.textContent) : null;
    if (m && parseNum(m[1]) === u.chain) secs = parseTime(m[2]);
    if (secs === null) secs = Math.max(0, +u.chainEnd || 0);
    return { current: u.chain, max: null, timeout: secs, cooldown: null, attack: true };
  }

  function read() {
    var el = document.querySelector(BAR);
    if (el) attachStore(el);
    var d = store ? fromStore() : null;
    if (d) d.store = true;
    if (!d && el) d = fromDom(el);
    if (!d && !el && ATTACK) {
      d = fromAttack();
      if (d) d.store = true;
    }
    if (!d) return null;
    var cd = d.cooldown || 0;
    d.active = cd === 0 && d.current > 0 && (d.timeout === null || d.timeout > 0);
    d.ts = Date.now();
    return d;
  }

  function endOf(secs, ts) {
    return secs === null ? null : ts / 1000 + secs;
  }

  function changed(a, b) {
    if (!b) return true;
    if (a.current !== b.current || a.max !== b.max || a.active !== b.active) return true;
    if ((a.cooldown > 0) !== (b.cooldown > 0)) return true;
    if ((a.timeout === null) !== (b.timeout === null)) return true;
    if ((a.timeout > 0) !== (b.timeout > 0)) return true;
    // A hit restarts the timer
    if (a.timeout > 0 && Math.abs(endOf(a.timeout, a.ts) - endOf(b.timeout, b.ts)) > 2) return true;
    if (a.cooldown > 0 && Math.abs(endOf(a.cooldown, a.ts) - endOf(b.cooldown, b.ts)) > 2) return true;
    return false;
  }

  function send(d) {
    try {
      if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
        window.flutter_inappwebview.callHandler('PDA_chainWeb', d);
      }
    } catch (e) {}
  }

  var saidNone = false;
  function check(force) {
    // PDA flags the tabs on screen
    if (window.__pdaChainShown !== true || document.visibilityState !== 'visible') return;
    var d = read();
    if (!d) {
      if (!saidNone) send({ none: true });
      saidNone = true;
      last = null;
      return;
    }
    if (!force && !changed(d, last)) return;
    saidNone = false;
    last = d;
    api.last = d;
    send(d);
  }

  var pending = false;
  new MutationObserver(function () {
    if (pending) return;
    pending = true;
    setTimeout(function () {
      pending = false;
      check(false);
    }, 100);
  }).observe(document.documentElement, { subtree: true, childList: true, characterData: true });

  setInterval(function () {
    check(last !== null && Date.now() - last.ts >= 5000);
  }, 1000);

  document.addEventListener('visibilitychange', function () {
    check(true);
  });

  var api = {
    check: check,
    read: read,
    readDom: function () {
      var el = document.querySelector(BAR);
      return el ? fromDom(el) : null;
    },
    last: null,
  };
  window.__pdaChainReader = api;
  check(true);
})();
""";

void addChainWebHandler(InAppWebViewController webview, {required bool Function() onScreen}) {
  webview.addJavaScriptHandler(
    handlerName: chainWebHandler,
    callback: (JavaScriptHandlerFunctionData data) {
      if (data.args.isEmpty || !Get.isRegistered<ChainStatusController>()) return;
      Get.find<ChainStatusController>().applyWebChain(data.args.first, onScreen: onScreen);
    },
  );
}
