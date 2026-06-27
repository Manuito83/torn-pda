// Project imports:
import 'package:torn_pda/models/userscript_model.dart';

// JS snippet that ships compiled, but a newer version from RC can replace it at runtime
class RemoteSnippet {
  final String id;
  final String version;
  final String Function() buildBase;

  const RemoteSnippet({required this.id, required this.version, required this.buildBase});
}

class _Override {
  final String version;
  final String js;
  const _Override(this.version, this.js);
}

// Things to avoid (so that it works when pasted into RC):
//   - no backticks / template strings
//       bad:  addStyle(`.x{color:red}`)
//       ok:   addStyle('.x{color:red}')
//   - no backslashes (so /\d/ style regex is out, but new RegExp('[0-9]') is fine)
//       bad:  url.match(/city_items\/(\d+)\//)[1]
//       ok:   url.match(new RegExp('city_items/([0-9]+)/'))[1]
//       ok:   url.substring(url.indexOf('city_items/') + 11).split('/')[0]
class RemoteSnippets {
  RemoteSnippets._();

  static const String cityItemsHighlight = 'city_items_highlight';
  static const String cityShopsMax = 'city_shops_max';
  static const String travelRemovePlane = 'travel_remove_plane';
  static const String travelBuyMax = 'travel_buy_max';
  static const String barsDoubleClick = 'bars_double_click';
  static const String pdaApi = 'pda_api';

  static final Map<String, RemoteSnippet> _registry = {
    pdaApi: const RemoteSnippet(id: pdaApi, version: '1.0.0', buildBase: _pdaApiBaseJS),
    cityItemsHighlight: const RemoteSnippet(
      id: cityItemsHighlight,
      version: '1.0.0',
      buildBase: _cityItemsHighlightBaseJS,
    ),
    cityShopsMax: const RemoteSnippet(id: cityShopsMax, version: '1.0.0', buildBase: _cityShopsMaxBaseJS),
    travelRemovePlane: const RemoteSnippet(
      id: travelRemovePlane,
      version: '1.0.0',
      buildBase: _travelRemovePlaneBaseJS,
    ),
    travelBuyMax: const RemoteSnippet(id: travelBuyMax, version: '1.0.0', buildBase: _travelBuyMaxBaseJS),
    barsDoubleClick: const RemoteSnippet(id: barsDoubleClick, version: '1.0.0', buildBase: _barsDoubleClickBaseJS),
  };

  static final Map<String, _Override> _overrides = {};

  // Registered ids; drawer reads snippet_<id>_js + snippet_<id>_version for each
  static Iterable<String> get ids => _registry.keys;

  // Store a per-snippet override; empty js or version clears it
  static void setOverride(String id, String version, String js) {
    if (version.trim().isEmpty || js.trim().isEmpty) {
      _overrides.remove(id);
    } else {
      _overrides[id] = _Override(version.trim(), js);
    }
  }

  // Override JS if it's newer than the base, else the compiled base
  static String resolve(String id) {
    final base = _registry[id];
    if (base == null) return '';
    if (usingOverride(id)) return _overrides[id]!.js;
    return base.buildBase();
  }

  // Is the RC override (not the base) the one in use for id
  static bool usingOverride(String id) {
    final base = _registry[id];
    if (base == null) return false;
    final over = _overrides[id];
    return over != null && over.js.isNotEmpty && UserScriptModel.isNewerVersion(over.version, base.version);
  }

  // pda_api base
  // RC keys: snippet_pda_api_js + snippet_pda_api_version
  static String _pdaApiBaseJS() {
    return '''
      (function() {
        if (typeof window.__PDA_platformReadyPromise === 'undefined') {
          window.__PDA_platformReadyPromise = new Promise(function(resolve) {
            if (window.flutter_inappwebview && window.flutter_inappwebview._platformReady) return resolve();
            window.addEventListener('flutterInAppWebViewPlatformReady', resolve);
          });
        }

        // Each helper de-duplicates identical calls fired within 2s

        window.loadedPdaApiGetUrls = window.loadedPdaApiGetUrls || {};
        window.PDA_httpGet = async function(url, headers) {
          headers = headers || {};
          var now = Date.now();
          if (window.loadedPdaApiGetUrls[url] && (now - window.loadedPdaApiGetUrls[url] < 2000)) return;
          window.loadedPdaApiGetUrls[url] = now;
          await window.__PDA_platformReadyPromise;
          return window.flutter_inappwebview.callHandler('PDA_httpGet', url, headers);
        };

        window.loadedPdaApiPostUrls = window.loadedPdaApiPostUrls || {};
        window.PDA_httpPost = async function(url, headers, body) {
          var key = url + '+' + JSON.stringify(headers) + '+' + body;
          var now = Date.now();
          if (window.loadedPdaApiPostUrls[key] && (now - window.loadedPdaApiPostUrls[key] < 2000)) return;
          window.loadedPdaApiPostUrls[key] = now;
          await window.__PDA_platformReadyPromise;
          return window.flutter_inappwebview.callHandler('PDA_httpPost', url, headers, body);
        };

        window.loadedPdaApiPutUrls = window.loadedPdaApiPutUrls || {};
        window.PDA_httpPut = async function(url, headers, body) {
          var key = url + '+' + JSON.stringify(headers) + '+' + body;
          var now = Date.now();
          if (window.loadedPdaApiPutUrls[key] && (now - window.loadedPdaApiPutUrls[key] < 2000)) return;
          window.loadedPdaApiPutUrls[key] = now;
          await window.__PDA_platformReadyPromise;
          return window.flutter_inappwebview.callHandler('PDA_httpPut', url, headers, body);
        };

        window.loadedPdaApiDeleteUrls = window.loadedPdaApiDeleteUrls || {};
        window.PDA_httpDelete = async function(url, headers) {
          headers = headers || {};
          var key = url + '+' + JSON.stringify(headers);
          var now = Date.now();
          if (window.loadedPdaApiDeleteUrls[key] && (now - window.loadedPdaApiDeleteUrls[key] < 2000)) return;
          window.loadedPdaApiDeleteUrls[key] = now;
          await window.__PDA_platformReadyPromise;
          return window.flutter_inappwebview.callHandler('PDA_httpDelete', url, headers);
        };

        window.loadedPdaApiPatchUrls = window.loadedPdaApiPatchUrls || {};
        window.PDA_httpPatch = async function(url, headers, body) {
          var key = url + '+' + JSON.stringify(headers) + '+' + body;
          var now = Date.now();
          if (window.loadedPdaApiPatchUrls[key] && (now - window.loadedPdaApiPatchUrls[key] < 2000)) return;
          window.loadedPdaApiPatchUrls[key] = now;
          await window.__PDA_platformReadyPromise;
          return window.flutter_inappwebview.callHandler('PDA_httpPatch', url, headers, body);
        };
      })();
    ''';
  }

  // city_items_highlight base
  // RC keys: snippet_city_items_highlight_js + snippet_city_items_highlight_version
  static String _cityItemsHighlightBaseJS() {
    return '''
      (function() {
        function addStyle(css) {
          let s = document.getElementById('pda-cityitem-style');
          if (!s) { s = document.createElement('style'); s.id = 'pda-cityitem-style'; document.head.append(s); }
          s.textContent = css;
        }

        function getMap() {
          try {
            if (window.torn && window.torn.map && window.torn.map.lmap) return window.torn.map.lmap;
          } catch (e) {}
          return null;
        }

        // City items are the canvas markers whose icon points at /city_items/<id>/
        function collectItems(map) {
          const out = [];
          try {
            map.eachLayer(function(l) {
              try {
                const o = l.options;
                if (o && o.iconUrls && o.iconUrls[0] && typeof l.getLatLng === 'function') {
                  const u = String(o.iconUrls[0]);
                  const idx = u.indexOf('city_items/');
                  if (idx > -1) {
                    const id = u.substring(idx + 11).split('/')[0];
                    if (id && !isNaN(Number(id))) out.push({ marker: l, latlng: l.getLatLng(), id: id });
                  }
                }
              } catch (e) {}
            });
          } catch (e) {}
          return out;
        }

        function buildHighlights() {
          const map = getMap();
          if (!map || typeof L === 'undefined') return;

          const items = collectItems(map);
          const ids = items.map(function(it) { return it.id; });
          window._pdaCityItemIds = ids; // stashed for the return value below

          if (!window._pdaHighlightLayer) {
            window._pdaHighlightLayer = L.layerGroup().addTo(map);
          }
          const layer = window._pdaHighlightLayer;

          // Hidden via the widget toggle
          if (window._pdaCityHighlightHidden) { layer.clearLayers(); window._pdaCityItemSig = null; return; }

          // Only rebuild the rings when the set of items actually changed
          const sig = ids.join(',');
          if (sig === window._pdaCityItemSig) return;
          window._pdaCityItemSig = sig;
          layer.clearLayers();

          const SIZE = 40;
          for (let i = 0; i < items.length; i++) {
            try {
              const icon = L.divIcon({
                className: '',
                html: '<img class="pdaCityItemBig" src="/images/items/' + items[i].id + '/large.png">',
                iconSize: [SIZE, SIZE],
                iconAnchor: [SIZE / 2, SIZE / 2]
              });

              // Interactive so the whole 40px is clickable
              const canvasMarker = items[i].marker;
              L.marker(items[i].latlng, { icon: icon, interactive: true, keyboard: false, bubblingMouseEvents: false })
                .on('click', function() { try { canvasMarker.fire('click'); } catch (e) {} })
                .addTo(layer);
            } catch (e) {}
          }
        }

        // Exposed so the city widget show/hide button can toggle the overlay
        window._pdaSetCityHighlightHidden = function(hidden) {
          window._pdaCityHighlightHidden = !!hidden;
          window._pdaCityItemSig = null;
          buildHighlights();
        };

        addStyle('.pdaCityItemBig{box-sizing:border-box !important;display:block !important;width:40px !important;height:40px !important;object-fit:contain;border:3px dashed rgb(21 101 255);border-radius:50% !important;background:rgb(206 202 184 / 77%);box-shadow:0 0 6px 2px rgb(21 101 255 / 55%);padding:3px;cursor:pointer}');

        // Only start highlighting once the map is ready
        if (getMap() && typeof L !== 'undefined') {
          buildHighlights();
          if (window._pdaHlInterval) clearInterval(window._pdaHlInterval);
          window._pdaHlInterval = setInterval(buildHighlights, 2500);
        }

        // Single return for Flutter: the item ids, or NOT_READY while the map is still loading
        try {
          if (!(window.torn && window.torn.map && window.torn.map.lmap)) return "NOT_READY";
          return JSON.stringify(window._pdaCityItemIds || []);
        } catch (e) {
          return "NOT_READY";
        }
      })();
    ''';
  }

  // city_shops_max base (MAX buy/sell buttons inside city shops)
  // RC keys: snippet_city_shops_max_js + snippet_city_shops_max_version
  static String _cityShopsMaxBaseJS() {
    return '''
    (function() {
      const BUY_CLASS = 'pda-buy-100-btn';
      const SELL_CLASS = 'pda-sell-max-btn';
      const STYLE_ID = 'pda-shop-max-style';
      const BUY_LABEL = 'MAX';
      const SELL_LABEL = 'MAX';

      function parseNumber(text) {
        if (!text) return 0;
        const clean = String(text).replace(/[^0-9]/g, '');
        return clean ? parseInt(clean, 10) : 0;
      }

      function parseMoney(text) {
        if (!text) return 0;
        let clean = String(text).split('\$').join('').split(',').join('').trim().toLowerCase();
        let multiplier = 1;
        if (clean.endsWith('b')) {
          multiplier = 1000000000;
          clean = clean.slice(0, -1);
        } else if (clean.endsWith('m')) {
          multiplier = 1000000;
          clean = clean.slice(0, -1);
        } else if (clean.endsWith('k')) {
          multiplier = 1000;
          clean = clean.slice(0, -1);
        }
        const value = parseFloat(clean.replace(/[^0-9.]/g, ''));
        return Number.isNaN(value) ? 0 : Math.floor(value * multiplier);
      }

      function findMoney() {
        const moneyEl = document.querySelector('#user-money') ||
          document.querySelector('[data-currency-money]') ||
          document.querySelector('.user-information .money');
        if (!moneyEl) return 0;
        const attr = moneyEl.getAttribute('data-money') || moneyEl.getAttribute('data-currency-money');
        if (attr) return parseNumber(attr);
        return parseMoney(moneyEl.textContent);
      }

      function hasMoneyIndicator() {
        return !!(document.querySelector('#user-money') ||
          document.querySelector('[data-currency-money]') ||
          document.querySelector('.user-information .money'));
      }

      function findPrice(card) {
        const priceEl = card.querySelector(':scope > .desc > .price');
        if (priceEl) return parseMoney(priceEl.textContent);
        const text = card.innerText || card.textContent || '';
        const match = text.match(new RegExp('[\$][ ]*([0-9][0-9,]*(?:[.][0-9]+)?)[ ]*([kmb])?', 'i'));
        if (!match) return 0;
        return parseMoney('\$' + match[1] + (match[2] || ''));
      }

      function findStock(card) {
        const stockEl = card.querySelector(':scope > .desc > .stock');
        if (stockEl) {
          const t = stockEl.textContent;
          if (/out of stock/i.test(t)) return 0;
          const m = t.match(new RegExp('[(][ ]*([0-9,]+)[ ]+in[ ]+stock[ ]*[)]', 'i'));
          if (m) return parseNumber(m[1]);
        }
        return -1;
      }

      function setNativeInputValue(input, value) {
        const proto = window.HTMLInputElement && window.HTMLInputElement.prototype;
        const descriptor = proto && Object.getOwnPropertyDescriptor(proto, 'value');
        if (descriptor && descriptor.set) {
          descriptor.set.call(input, String(value));
        } else {
          input.value = value;
        }
        const tracker = input._valueTracker;
        if (tracker) tracker.setValue('');
        input.dispatchEvent(new Event('input', { bubbles: true }));
        input.dispatchEvent(new Event('change', { bubbles: true }));
        if (window.jQuery) {
          try { window.jQuery(input).val(value).trigger('change'); } catch (e) {}
        }
      }

      function findBuyInput(card) {
        const wrap = card.querySelector(':scope > .buy-act-wrap');
        if (!wrap) return null;
        return wrap.querySelector('input[name="buyAmount[]"]') ||
          wrap.querySelector('input[name^="buyAmount"]') ||
          wrap.querySelector('input.input-money') ||
          wrap.querySelector('input[class*="buyAmountInput"]');
      }

      function findSellInput(card) {
        return card.querySelector(':scope > li.amount input[id^="sell"]') ||
          card.querySelector(':scope > li.amount input.input-money');
      }

      function getBuyTarget(card, input) {
        const price = findPrice(card);
        const money = findMoney();
        const stock = findStock(card);
        const maxFromInput = parseNumber(input.getAttribute('max'));

        let quantity = 100;
        if (price > 0 && money > 0) {
          quantity = Math.min(quantity, Math.floor(money / price));
        }
        if (stock >= 0) {
          quantity = Math.min(quantity, stock);
        }
        if (maxFromInput > 0) {
          quantity = Math.min(quantity, maxFromInput);
        }
        if (!isFinite(quantity) || quantity < 0) return 0;
        return quantity;
      }

      function getSellTarget(input) {
        const dataMoney = parseNumber(input.getAttribute('data-money'));
        const maxFromInput = parseNumber(input.getAttribute('max'));
        if (dataMoney > 0 && maxFromInput > 0) return Math.min(dataMoney, maxFromInput);
        if (dataMoney > 0) return dataMoney;
        if (maxFromInput > 0) return maxFromInput;
        return 0;
      }

      function injectStyle() {
        if (document.getElementById(STYLE_ID)) return;

        // Shared style for the small inline MAX buttons (buy + sell).
        // Explicit bg/color so they stay readable in dark mode.
        const btnCss =
          'display:inline-block !important;' +
          'margin:0 0 0 4px !important;' +
          'padding:0 4px !important;' +
          'height:16px !important;' +
          'line-height:14px !important;' +
          'font-size:9px !important;' +
          'font-weight:bold !important;' +
          'letter-spacing:0.3px !important;' +
          'background:#777 !important;' +
          'color:#fff !important;' +
          'border:1px solid #555 !important;' +
          'border-radius:3px !important;' +
          'cursor:pointer !important;' +
          'white-space:nowrap !important;' +
          'vertical-align:middle !important;';

        const style = document.createElement('style');
        style.id = STYLE_ID;
        style.textContent = '.' + BUY_CLASS + '{' + btnCss + '} .' + SELL_CLASS + '{' + btnCss + '}';
        document.head.appendChild(style);
      }

      function injectButtons() {
        if (!hasMoneyIndicator()) return;
        injectStyle();

        document.querySelectorAll('.item-desc').forEach((card) => {
          const wrap = card.querySelector(':scope > .buy-act-wrap');
          if (!wrap) return;
          if (card.querySelector('.' + BUY_CLASS)) return;
          if (!findBuyInput(card)) return;

          const price = card.querySelector(':scope > .desc > .price');
          const name = card.querySelector(':scope > .desc > .name');
          const slot = price || name;
          if (!slot) return;

          const buyButton = document.createElement('button');
          buyButton.type = 'button';
          buyButton.className = BUY_CLASS;
          buyButton.textContent = BUY_LABEL;
          buyButton.title = 'Buy max affordable / in stock';
          buyButton.dataset.pdaBuyMax = '1';

          buyButton.addEventListener('click', (event) => {
            event.preventDefault();
            event.stopPropagation();
            const liveCard = buyButton.closest('.item-desc');
            if (!liveCard) return;
            const liveInput = findBuyInput(liveCard);
            if (liveInput) setNativeInputValue(liveInput, getBuyTarget(liveCard, liveInput));
          });

          slot.appendChild(buyButton);
        });

        document.querySelectorAll('ul.item').forEach((card) => {
          if (card.querySelector('.' + SELL_CLASS)) return;
          const input = findSellInput(card);
          if (!input) return;
          const desc = card.querySelector(':scope > li.desc');
          if (!desc) return;

          const sellButton = document.createElement('button');
          sellButton.type = 'button';
          sellButton.className = SELL_CLASS;
          sellButton.textContent = SELL_LABEL;
          sellButton.title = 'Sell all owned';
          sellButton.dataset.pdaSellMax = '1';

          sellButton.addEventListener('click', (event) => {
            event.preventDefault();
            event.stopPropagation();
            const liveCard = sellButton.closest('ul.item');
            if (!liveCard) return;
            const liveInput = findSellInput(liveCard);
            if (liveInput) setNativeInputValue(liveInput, getSellTarget(liveInput));
          });

          desc.appendChild(sellButton);
        });
      }

      injectButtons();

      if (!window.__pdaShopMaxObserver) {
        window.__pdaShopMaxObserver = new MutationObserver(() => injectButtons());
        window.__pdaShopMaxObserver.observe(document.body, { childList: true, subtree: true });
      }

      return 123;
    })();
    ''';
  }

  // travel_remove_plane base
  // RC keys: snippet_travel_remove_plane_js + snippet_travel_remove_plane_version
  static String _travelRemovePlaneBaseJS() {
    return '''
      (function() {
        if (!document.getElementById('pda-remove-plane')) {
          var s = document.createElement('style');
          s.id = 'pda-remove-plane';
          s.textContent = '[class*="airspaceScene___"],[class*="factWrapper___"]{display:none !important;}';
          document.head.appendChild(s);
        }
        return 123;
      })();
    ''';
  }

  // travel_buy_max base (MAX/FILL buttons in foreign stock shops)
  // RC keys: snippet_travel_buy_max_js + snippet_travel_buy_max_version
  // preventBasketKeyboard is passed in via window.__pdaPreventBasketKeyboard (defaults true)
  static String _travelBuyMaxBaseJS() {
    return '''
    (function() {
      var preventBasketKeyboard = window.__pdaPreventBasketKeyboard !== false;

      function parseMoney(text) {
        var clean = text.split('\$').join('').trim().toLowerCase();
        var multiplier = 1;
        if (clean.endsWith('m')) {
            multiplier = 1000000;
            clean = clean.substring(0, clean.length - 1);
        } else if (clean.endsWith('b')) {
            multiplier = 1000000000;
            clean = clean.substring(0, clean.length - 1);
        } else if (clean.endsWith('k')) {
            multiplier = 1000;
            clean = clean.substring(0, clean.length - 1);
        }

        clean = clean.replace(/[^0-9.]/g, '');

        var val = parseFloat(clean);
        if (isNaN(val)) return 0;
        return Math.floor(val * multiplier);
      }

      function addFillMaxButtons() {

        // 0. SAFETY CHECK: Ensure we can detect user money
        // If we can't find money, we might be elsewhere (e.g. Bank)
        // or simply can't calculate the max amount
        const moneyElCheck = document.querySelector('#user-money') || document.querySelector('[data-currency-money]') || document.querySelector('.user-information .money');
        if (!moneyElCheck) {
            return;
        }

        // Improved Mode Detection
        const isHorizontalMode = () => {
            // 1. Check for VISIBLE "Type" header
            const headers = Array.from(document.querySelectorAll('[class*="itemsHeader___"] > div'));
            const visibleTypeHeader = headers.find(h =>
                h.textContent.trim().toUpperCase() === 'TYPE' && h.offsetParent !== null
            );

            if (visibleTypeHeader) {
                 return true;
            }

            // 2. Check Button Text
            const buyBtn = document.querySelector('button.torn-btn[type="submit"]');
            if (buyBtn) {
                const text = buyBtn.innerText.trim().toUpperCase();
                if (text === 'BUY') {
                    return true;
                }
            }

            // 3. Fallback to width
            return window.innerWidth > 700;
        };

        const isHorizontal = isHorizontalMode();

        // 1. CSS INJECTION
        let style = document.getElementById('pda-buy-max-style');
        if (!style) {
            style = document.createElement('style');
            style.id = 'pda-buy-max-style';
            document.head.appendChild(style);
        }

        // VERTICAL CSS
        const verticalCSS =
            '[class*="row___"], [class*="stockHeader___"] { gap: 0 !important; }' +
            '[class*="row___"] > div, [class*="stockHeader___"] > div { padding-left: 2px !important; padding-right: 2px !important; margin: 0 !important; }' +
            '[class*="stockHeader___"] > div:nth-child(3), [class*="row___"] > div:nth-child(3) { display: none !important; }' +
            '[class*="stockHeader___"] > div:nth-child(4), [class*="row___"] > div:nth-child(4), [class*="stockHeader___"] > div:nth-child(5), [class*="row___"] > div:nth-child(5) { flex: 0 0 auto !important; width: auto !important; min-width: 0 !important; max-width: none !important; }' +
            '[class*="itemName___"] { flex: 1 1 auto !important; min-width: 40px !important; overflow: hidden !important; }' +
            '[class*="itemName___"] button { white-space: nowrap !important; overflow: hidden !important; text-overflow: ellipsis !important; max-width: 100% !important; display: block !important; }' +
            '[class*="buyCell___"] { flex: 0 0 auto !important; width: auto !important; max-width: none !important; }';

        // HORIZONTAL CSS
        const horizontalCSS =
            '[class*="itemsHeader___"] > div:nth-child(3) { display: none !important; }' +
            'li > div[class*="row___"] > div:nth-child(3) { display: none !important; }' +
            '[class*="tabletColE___"] { min-width: 100px !important; overflow: visible !important; }';

        const desiredMode = isHorizontal ? 'horizontal' : 'vertical';
        if (style.getAttribute('data-mode') !== desiredMode) {
            style.setAttribute('data-mode', desiredMode);
            style.innerHTML = isHorizontal ? horizontalCSS : verticalCSS;
        }

        // 2. JS HIDING FOR HORIZONTAL MODE (Type Column)
        if (isHorizontal) {
            // Hide Header
            const headers = document.querySelectorAll('[class*="itemsHeader___"] > div');
            headers.forEach((h, index) => {
                if (h.textContent.trim().toUpperCase() === 'TYPE') {
                    h.style.display = 'none';
                    // Also try to hide the corresponding column in rows if we found the index
                    const rows = document.querySelectorAll('li > div[class*="row___"]');
                    rows.forEach(row => {
                        if (row.children.length > index) {
                            row.children[index].style.display = 'none';
                        }
                    });
                }
            });
        }

        // 3. BUTTON INJECTION
        const buttons = document.querySelectorAll('button.torn-btn[type="submit"]');

        buttons.forEach(btn => {
            if (btn.dataset.pdaMaxAdded) return;

            // Ensure button is inside a list item (item row)
            // in order to prevent injection on pages like Bank in Cayman
            if (!btn.closest('li')) return;

            btn.dataset.pdaMaxAdded = 'true';

            const maxBtn = document.createElement('button');
            maxBtn.innerText = 'MAX';
            maxBtn.className = 'torn-btn pda-max-btn';
            maxBtn.style.padding = '0 8px';
            maxBtn.style.fontSize = '11px';
            maxBtn.style.height = '30px';
            maxBtn.style.lineHeight = '12px';
            maxBtn.type = 'button';

            if (btn.parentNode) {
                const wrapper = document.createElement('div');
                wrapper.style.display = 'inline-flex';
                wrapper.style.flexDirection = 'row';
                wrapper.style.alignItems = 'center';
                wrapper.style.marginTop = '3px';

                btn.parentNode.insertBefore(wrapper, btn);

                wrapper.appendChild(btn);
                wrapper.appendChild(maxBtn);

                btn.style.flex = '0 0 auto';
                btn.style.width = 'auto';
                btn.style.margin = '0';
                btn.style.marginBottom = '0';
                btn.style.marginRight = '5px';

                maxBtn.style.flex = '0 0 auto';
                maxBtn.style.margin = '0';
            }

            // 4. CALCULATION LOGIC
            maxBtn.onclick = (e) => {
                e.preventDefault();
                e.stopPropagation();

                const form = btn.form;
                const li = btn.closest('li');
                const currentIsHorizontal = isHorizontalMode();

                let money = 0;
                const moneyEl = document.querySelector('#user-money') || document.querySelector('[data-currency-money]');
                if (moneyEl) {
                  const txt = moneyEl.getAttribute('data-money') || moneyEl.textContent;
                  money = parseInt(txt.replace(/[^0-9]/g, ''));
                }

                let cost = 0;
                let stock = 0;
                let capacityLeft = 1000;

                let limitFromInput = 0;
                if (form) {
                    const input = form.querySelector('input.input-money');
                    if (input && input.getAttribute('data-money')) {
                        limitFromInput = parseInt(input.getAttribute('data-money'));
                    }
                }

                if (currentIsHorizontal) {
                    // ===== HORIZONTAL MODE =====

                    if (li) {
                        // 1. Cost Detection (Match Dart Logic: Scan spans)
                        const spans = li.querySelectorAll('span');
                        for (const span of spans) {
                            const txt = span.textContent.trim();
                            if (txt.includes('\$') && span.getAttribute('aria-hidden') !== 'true') {
                                 cost = parseMoney(txt);
                            }
                        }

                        // 2. Stock Detection
                        // Try specific class
                        let stockCell = li.querySelector('[class*="tabletColC___"]');
                        if (stockCell) {
                            const stockText = stockCell.textContent.trim();
                            const match = stockText.match(new RegExp('([0-9,]+)'));
                            if (match) {
                                stock = parseInt(match[1].split(',').join(''));
                            }
                        } else {
                            // Fallback: Look for "Stock" text
                             const all = li.querySelectorAll('*');
                            for (let el of all) {
                                if (el.textContent.toLowerCase().includes('stock')) {
                                    const match = el.textContent.match(new RegExp('([0-9,]+)'));
                                    if (match) {
                                        stock = parseInt(match[1].split(',').join(''));
                                        break;
                                    }
                                }
                            }
                        }
                    }

                    // 3. Capacity
                    const msgEl = document.querySelector('.messageContent___LhCmx');
                    if (msgEl) {
                        const match = msgEl.textContent.match(new RegExp('purchased[ ]*([0-9]+)[ ]*/[ ]*([0-9]+)'));
                        if (match) {
                            const current = parseInt(match[1]);
                            const maxCap = parseInt(match[2]);
                            capacityLeft = maxCap - current;
                        }
                    }

                } else {
                    // ===== VERTICAL MODE =====
                    const buyPanel = btn.closest('div[class*="buyPanel___"]');
                    if (buyPanel) {
                        const question = buyPanel.querySelector('p[class*="question___"]');
                        if (question) {
                            const parts = question.textContent.split('\$');
                            if (parts.length > 1) {
                                cost = parseMoney(parts[parts.length - 1]);
                            }
                        }
                    }

                    if (cost === 0 && li) {
                        const cells = li.querySelectorAll('div[class*="cell___"]');
                        for (const cell of cells) {
                            const txt = cell.textContent.toLowerCase();
                            if (txt.includes('cost') && txt.includes('\$')) {
                                const parts = cell.textContent.split('\$');
                                if (parts.length > 1) {
                                    cost = parseMoney(parts[parts.length - 1]);
                                    break;
                                }
                            }
                        }
                    }
                        if (li) {
                        const inlineStock = li.querySelector('[class*="inlineStock___"]');
                        if (inlineStock) {
                            const match = inlineStock.textContent.match(new RegExp('x([0-9,]+)'));
                            if (match) {
                                stock = parseInt(match[1].split(',').join(''));
                            }
                        }

                        if (stock === 0) {
                            const cells = li.querySelectorAll('div[class*="cell___"]');
                            for (const cell of cells) {
                                const txt = cell.textContent.toLowerCase();
                                if (txt.includes('stock')) {
                                    const match = cell.textContent.match(new RegExp('stock[ ]*([0-9,]+)', 'i')) || cell.textContent.match(new RegExp('([0-9,]+)'));
                                    if (match) {
                                        stock = parseInt(match[1].split(',').join(''));
                                    }
                                }
                            }
                        }
                    }

                    const itemsBar = document.querySelector('[class*="items-"]');
                    if (itemsBar) {
                        const capMatch = itemsBar.textContent.match(new RegExp('([0-9]+)[ ]*/[ ]*([0-9]+)'));
                        if (capMatch) {
                            capacityLeft = parseInt(capMatch[2]) - parseInt(capMatch[1]);
                        }
                    }
                }

                let max = 0;
                let maxAffordable = 999999;
                if (cost > 0) {
                    maxAffordable = Math.floor(money / cost);
                }

                const effectiveStock = stock > 0 ? stock : 999999;
                const effectiveCapacity = capacityLeft >= 0 ? capacityLeft : 999999;

                max = Math.min(effectiveStock, effectiveCapacity, maxAffordable);

                if (limitFromInput > 0) {
                    max = Math.min(limitFromInput, maxAffordable);
                }

                if (form) {
                    const input = form.querySelector('input.input-money');
                    if (input) {
                        input.value = max;
                        input.dispatchEvent(new Event('input', { bubbles: true }));
                        input.dispatchEvent(new Event('change', { bubbles: true }));
                    }
                }
            };
        });

        // 5. PREVENT KEYBOARD ON BASKET CLICK (Vertical Mode)
        if (preventBasketKeyboard) {
          const basketButtons = document.querySelectorAll('button[class*="buyIconButton___"]');
          basketButtons.forEach(btn => {
              if (btn.dataset.pdaBlurAdded) return;
              btn.dataset.pdaBlurAdded = 'true';

              btn.addEventListener('click', (e) => {
                  [50, 150, 300, 500].forEach(delay => {
                      setTimeout(() => {
                          if (document.activeElement && document.activeElement.tagName === 'INPUT') {
                              document.activeElement.blur();
                          }
                      }, delay);
                  });
              });
          });
        }
      }

      addFillMaxButtons();
      if (!window.__pdaBuyMaxObserver) {
        window.__pdaBuyMaxObserver = new MutationObserver((mutations) => {
          addFillMaxButtons();
        });
        window.__pdaBuyMaxObserver.observe(document.body, { childList: true, subtree: true });
      }
    })();
    ''';
  }

  // bars_double_click base
  // RC keys: snippet_bars_double_click_js + snippet_bars_double_click_version
  static String _barsDoubleClickBaseJS() {
    return '''
      (function() {
        if (window.pdaBarsListenerAdded) {
          return;
        }

        const ua = navigator.userAgent || '';
        const isIOS = ua.indexOf('iPhone') > -1 || ua.indexOf('iPad') > -1 || ua.indexOf('iPod') > -1;

        function onEnergyClick() {
          window.location.href = 'https://www.torn.com/gym.php';
        }

        function onNerveClick() {
          window.location.href = 'https://www.torn.com/crimes.php';
        }

        function addBarsListener() {
          const barElements = Array.from(document.querySelectorAll('[class*="bar___"]'));
          const energyBar = barElements.find((el) => el.className.includes('energy___'));
          const nerveBar = barElements.find((el) => el.className.includes('nerve___'));

          if (!energyBar || !nerveBar) {
            return false;
          }

          if (isIOS) {
            let energyClickCount = 0;
            let nerveClickCount = 0;
            const doubleClickInterval = 1500;

            energyBar.addEventListener('click', () => {
              energyClickCount++;
              if (energyClickCount === 1) {
                setTimeout(() => {
                  if (energyClickCount >= 2) {
                    onEnergyClick();
                  }
                  energyClickCount = 0;
                }, doubleClickInterval);
              }
            });

            nerveBar.addEventListener('click', () => {
              nerveClickCount++;
              if (nerveClickCount === 1) {
                setTimeout(() => {
                  if (nerveClickCount >= 2) {
                    onNerveClick();
                  }
                  nerveClickCount = 0;
                }, doubleClickInterval);
              }
            });
          } else {
            energyBar.addEventListener('dblclick', onEnergyClick);
            nerveBar.addEventListener('dblclick', onNerveClick);
          }

          window.pdaBarsListenerAdded = true;
          return true;
        }

        let pass = 0;
        const waitForBarsAndRun = setInterval(() => {
          if (addBarsListener()) {
            return clearInterval(waitForBarsAndRun);
          }

          pass++;
          if (pass > 20) {
            clearInterval(waitForBarsAndRun);
          }
        }, 300);
      })();
    ''';
  }
}

// city item highlighter (RC-overridable)
String highlightCityItemsJS() => RemoteSnippets.resolve(RemoteSnippets.cityItemsHighlight);

// MAX buy/sell buttons inside city shops (RC-overridable)
String cityShopsBuy100JS() => RemoteSnippets.resolve(RemoteSnippets.cityShopsMax);

// MAX buy buttons in foreign stock shops (RC-overridable)
String buyMaxAbroadJS({bool preventBasketKeyboard = true}) {
  // The base reads window.__pdaPreventBasketKeyboard (defaults to true)
  return '''
    window.__pdaPreventBasketKeyboard = $preventBasketKeyboard;
    ${RemoteSnippets.resolve(RemoteSnippets.travelBuyMax)}
  ''';
}

// remove the plane animation while traveling (RC-overridable)
String travelRemovePlaneJS() => RemoteSnippets.resolve(RemoteSnippets.travelRemovePlane);

// double-click the energy/nerve bars to jump to gym/crimes (RC-overridable)
String barsDoubleClickRedirectJS() => RemoteSnippets.resolve(RemoteSnippets.barsDoubleClick);
