import 'package:flutter_inappwebview/flutter_inappwebview.dart';

// Selectors from Torn Chat Banking Helper 1.3
final UserScript bankVaultScript = UserScript(
  groupName: 'pda_bankVault',
  injectionTime: UserScriptInjectionTime.AT_DOCUMENT_START,
  source: r"""
(function () {
  var host = location.hostname;
  if (host !== 'torn.com' && !host.endsWith('.torn.com')) return;
  var HELPER = 'TornChatBankingHelper';
  var STORE = 'pda-bank-allow-negative';
  var TOGGLE = 'pda-bank-allow-negative';
  var MONEY = 'input.input-money:not([type="hidden"])';
  var BALANCE = '[class*="form"] p span[class*="nowrap"]';
  var BUTTON = '[class*="ctaButton"]';
  var handled = null;

  function request() {
    if (location.pathname.indexOf('factions.php') < 0) return null;
    var hash = location.hash;
    var p = new URLSearchParams(hash.split('?')[1] || hash.replace(/^#\/?/, ''));
    if (p.get('tab') !== 'controls' || !p.get('giveMoneyTo')) return null;
    return p;
  }

  function helperHere() {
    if (document.getElementById(HELPER + '-container-script-allow-negative')) return true;
    var styles = document.querySelectorAll('style');
    for (var i = 0; i < styles.length; i++) {
      if ((styles[i].textContent || '').indexOf(HELPER) >= 0) return true;
    }
    return false;
  }

  function balance() {
    var el = document.querySelector(BALANCE);
    var m = el && (el.textContent || '').match(/\$\s*([\d,]+)/);
    return m ? parseInt(m[1].replace(/,/g, ''), 10) : null;
  }

  function allowNegative() {
    try { return localStorage.getItem(STORE) === '1'; } catch (e) { return false; }
  }

  function when(ready, then) {
    if (ready()) return then();
    var obs = new MutationObserver(function () {
      if (!ready()) return;
      obs.disconnect();
      then();
    });
    obs.observe(document.documentElement, { childList: true, subtree: true, characterData: true });
    setTimeout(function () { obs.disconnect(); }, 30000);
  }

  function guard() {
    var input = document.querySelector(MONEY);
    var button = document.querySelector(BUTTON);
    var bal = balance();
    if (!input || !button || bal === null) return;
    var value = parseInt((input.value || '').replace(/,/g, ''), 10);
    if (!isNaN(value) && value > bal && !allowNegative()) {
      button.disabled = true;
      button.setAttribute('data-pda-capped', '1');
    } else if (button.hasAttribute('data-pda-capped')) {
      button.disabled = false;
      button.removeAttribute('data-pda-capped');
    }
  }

  function fill(money) {
    var input = document.querySelector(MONEY);
    var bal = balance();
    if (!input || bal === null) return;
    var wanted = parseInt(money, 10);
    var value = money === 'SEND_FULL' || isNaN(wanted) || wanted > bal ? bal : wanted;
    var setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value').set;
    setter.call(input, String(value));
    input.dispatchEvent(new Event('input', { bubbles: true }));
  }

  function addToggle() {
    if (helperHere() || document.getElementById(TOGGLE)) return;
    var radios = document.querySelector('[role="radiogroup"]');
    if (!radios) return;
    var box = document.createElement('div');
    box.className = 'choice-container';
    box.style.width = '100%';
    var input = document.createElement('input');
    input.type = 'checkbox';
    input.id = TOGGLE;
    input.className = 'radio-css dark-bg';
    input.checked = allowNegative();
    input.addEventListener('change', function () {
      try { localStorage.setItem(STORE, input.checked ? '1' : '0'); } catch (e) {}
      guard();
    });
    var label = document.createElement('label');
    label.className = 'marker-css';
    label.htmlFor = TOGGLE;
    label.textContent = 'Allow negative balances';
    box.appendChild(input);
    box.appendChild(label);
    radios.insertAdjacentElement('afterend', box);
    var obs = new MutationObserver(function () {
      if (!document.getElementById(HELPER + '-container-script-allow-negative')) return;
      obs.disconnect();
      var button = document.querySelector(BUTTON + '[data-pda-capped]');
      if (button) {
        button.disabled = false;
        button.removeAttribute('data-pda-capped');
      }
      box.remove();
    });
    obs.observe(document.documentElement, { childList: true, subtree: true });
    setTimeout(function () { obs.disconnect(); }, 30000);
  }

  function run() {
    var p = request();
    if (!p || handled === location.hash) return;
    handled = location.hash;
    when(function () {
      return document.querySelector(MONEY) && balance() !== null && document.querySelector('[role="radiogroup"]');
    }, function () {
      // Let the userscript go first
      setTimeout(function () {
        if (helperHere()) return;
        if (p.get('money')) fill(p.get('money'));
        addToggle();
        guard();
      }, 400);
    });
  }

  document.addEventListener('input', function (e) {
    if (e.target && e.target.matches && e.target.matches(MONEY) && handled !== null && !helperHere()) guard();
  }, true);
  window.addEventListener('hashchange', run);
  run();
})();
""",
);
