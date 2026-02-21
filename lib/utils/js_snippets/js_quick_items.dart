import 'dart:convert';

String runQuickItemJS({
  required String item,
  required String itemName,
  bool faction = false,
  bool? eRefill = false,
  bool? nRefill = false,
  String? instanceId,
  bool isEquip = false,
  bool isTemporary = false,
  bool kDebugMode = false,
}) {
  const String timeRegex =
      r'/<span class="counter-wrap[\s=\-"a-zA-Z0-9]*data-time="[0-9]+"[\s=\-"a-zA-Z0-9]*>[0-9:]*<\/span>/g';

  return '''
    // Credits:
    // Partially based on Torn Tools & reTorn
    
    // =======================================================
    // ####################### OVERVIEW ###################### 
    // =======================================================
    // 
    // Core Logic:
    // - runAction(): Entry Point. Chain Level 1 -> 2 -> 3
    // - executeAction(): API calls (Equip/Use) and handles "Wrong itemID" retries
    //
    // Strategies for Temporary Items:
    // - Level 1: Flutter persistente (checks injected `resolvedId`)
    // - Level 2: TORN search API. `fetchItemViaSearch()`, if Level 1 fails
    // - Level 3: Scroll fallback. `doScrollForTemporary()`. Physical scroll if Level 2 fails
    //
    // Caching & Interception:
    // - installTempInterceptor(): XHR/Fetch to sniff IDs
    // - startTempDomCacheObserver(): Watches DOM changes to sniff IDs from UI updates
    // - setTempCache() / getTempCache(): Manages browser memory cache & syncs to Flutter
    // - resolveTemporaryEquipId(): Quick lookups in Cache or current DOM (Strategy 0)
    //
    // UI Helpers:
    // - fixTime(): Formats time strings in responses
    // - addStyle(): Injects result box CSS
    // - updateEquippedUI(): Refreshes Torn's loadout panel after equip via loadEquippedItems()
    //
    // Network & Utilities:
    // - getRFC() / addRFC(): Handles security tokens
    // - useItemWithJQuery(): Action execution via jQuery (preferred)
    // - ajaxWrapper(): Action execution via vanilla JS (fallback)
    // - logTemp(): Debug logging
    // =======================================================
    
    // Fixed time string for faction armoury replies
    function fixTime(str) {
      let regexp = $timeRegex
      let matches = str.match(regexp);

      if (matches == null || Object.keys(matches).length === 0) {
        return "";
      }

      function secondsToHms(d) {
        d = Number(d);
        var h = Math.floor(d / 3600);
        var m = Math.floor(d % 3600 / 60);
        var s = Math.floor(d % 3600 % 60);

        var hDisplay = minTwoDigits(h) + ":";
        var mDisplay = minTwoDigits(m) + ":";
        var sDisplay = minTwoDigits(s);
        return hDisplay + mDisplay + sDisplay; 
      }

      function minTwoDigits(n) {
        return (n < 10 ? '0' : '') + n;
      }

      var final = str;
      for (var m of matches) {
        let regTime = /data-time="([0-9:]+)"/
        let timeMatch = m.match(regTime);
        final = final.replace(m, secondsToHms(timeMatch[1]));
      }
      return final;
    }

    // Decode HTML entities if Torn returns escaped HTML
    function decodeHtmlEntities(str) {
      if (!str || typeof str !== 'string') return str;
      if (str.indexOf('&lt;') === -1 && str.indexOf('&gt;') === -1 && str.indexOf('&amp;') === -1) return str;
      const txt = document.createElement('textarea');
      txt.innerHTML = str;
      return txt.value;
    }

    // Render links array from Torn response (if present)
    function buildLinksHtml(links) {
      if (!links || !Array.isArray(links) || links.length === 0) return '';
      try {
        return links.map(function(link) {
          if (!link) return '';
          var title = link.title || link.text || 'Link';
          var url = link.url || '#';
          var cls = link.class || '';
          var attr = link.attr || '';
          return '<a href="' + url + '" class="' + cls + '" ' + attr + '>' + title + '</a>';
        }).join(' ');
      } catch (_) {
        return '';
      }
    }

    // Add style for result box
    function addStyle(styleString) {
      let style = document.getElementById('pda-resultbox-style');
      if (!style) {
        style = document.createElement('style');
        style.id = 'pda-resultbox-style';
        document.head.append(style);
      }
      style.textContent = styleString;
    } 
        
    var darkModeFound = document.querySelectorAll('#body.dark-mode');
    if (darkModeFound.length > 0) {
      addStyle(`
        .resultBox {
          border: 2px dotted black;
          margin-top: 20px;
          margin-bottom: 20px;
          padding:5px;
          background-color: #242424;
        }
        .resultBox a {
          color: #82c8e0;
          cursor: pointer;
          text-decoration: underline;
        }
      `);
    } else {
      addStyle(`
        .resultBox {
          border: 2px dotted black;
          margin-top: 20px;
          margin-bottom: 20px;
          padding:5px;
          background-color: #fff;
        }
        .resultBox a {
          color: #006994;
          cursor: pointer;
          text-decoration: underline;
        }
      `);
    }
    
    // If there any boxes remaining (from previous calls), remove them
    for (let box of document.querySelectorAll('.resultBox')) {
      box.remove();
    }
 
    // Retrieves the RF security token from cookies
    function getRFC() {
      const rfc = getCookie("rfc_v");
      if (!rfc) {
        const cookies = document.cookie.split("; ");
        for (let i in cookies) {
          let cookie = cookies[i].split("=");
          if (cookie[0] === "rfc_v") {
            return cookie[1];
          }
        }
      }
      return rfc;
    }
    
    // From TornTools by Mephiles
    function addRFC(url) {
      url = url || "";
      url += (url.split("?").length > 1 ? "&" : "?") + "rfcv=" + getRFC();
      return url;
    }

    // Intercepts XHR/Fetch requests to sniff item IDs from JSON/HTML responses
    // Usage: Called at initialization to passively populate cache from background network activity
    // [Passive Support for Strategy 0 & Level 3]
    function installTempInterceptor() {
      try {
        if (window._pdaTempInterceptorInstalled) return;
        window._pdaTempInterceptorInstalled = true;

        function cacheFromHtml(text) {
          try {
            const parser = new DOMParser();
            const doc = parser.parseFromString(text, 'text/html');
            const nodes = doc.querySelectorAll('li[data-item][data-category="Temporary"]');
            if (!nodes || !nodes.length) return;
            nodes.forEach(function(li) {
              const itemId = li.getAttribute('data-item') || li.getAttribute('data-itemid');
              const armoryId = li.getAttribute('data-armoryid') || li.getAttribute('data-id');
              if (itemId && armoryId) {
                setTempCache(String(itemId), String(armoryId));
              }
            });
            logTemp('Interceptor: Cached temp item', itemId);
          } catch (_) {}
        }

        function cacheFromJson(text) {
          let json;
          try {
            json = JSON.parse(text);
          } catch (_) {
            return false;
          }
          const itemsList = json.items || json.list || json.data || json;
          if (!itemsList) return false;
          const scanItem = function(it) {
            if (!it) return;
            const type = it.type || it.category || it.itemType;
            if (type !== 'Temporary') return;
            const itemId = it.ID || it.id || it.itemID || it.itemId || it.number || it.item;
            const equipId = it.UID || it.uid || it.instanceId || it.instance_id || it.armoryID || it.armoryId || it.equip_id || it.equipId || it.id || it.ID;
            if (itemId && equipId) {
              setTempCache(String(itemId), String(equipId));
            }
          };
          if (Array.isArray(itemsList)) {
            itemsList.forEach(scanItem);
          } else if (typeof itemsList === 'object') {
            Object.keys(itemsList).forEach(function(k) {
              scanItem(itemsList[k]);
            });
          }
          return true;
        }

        const originalFetch = window.fetch;
        if (originalFetch) {
          window.fetch = function(input, init) {
            return originalFetch(input, init).then(function(resp) {
              try {
                const clone = resp.clone();
                clone.text().then(function(text) {
                  if (!cacheFromJson(text)) {
                    cacheFromHtml(text);
                  }
                });
              } catch (_) {}
              return resp;
            });
          };
        }

        const origOpen = XMLHttpRequest.prototype.open;
        const origSend = XMLHttpRequest.prototype.send;
        XMLHttpRequest.prototype.open = function(method, url) {
          this._pdaUrl = url;
          return origOpen.apply(this, arguments);
        };
        XMLHttpRequest.prototype.send = function(body) {
          this.addEventListener('load', function() {
            try {
              const text = this.responseText || '';
              if (!cacheFromJson(text)) {
                cacheFromHtml(text);
              }
            } catch (_) {}
          });
          return origSend.apply(this, arguments);
        };

        logTemp('Interceptor: Installed');
      } catch (_) {}
    }

    // Monitors DOM changes to detect new items appearing in the UI
    // Usage: Called at initialization to passively populate cache as elements are added to the page
    // [Passive Support for Strategy 0 & Level 3]
    function startTempDomCacheObserver() {
      try {
        if (window._pdaTempDomObserver) return;

        function cacheFromDom(root) {
          try {
            const scope = root || document;
            const nodes = scope.querySelectorAll('li[data-item][data-category="Temporary"], li[data-item][data-category="Temporary"] *');
            if (!nodes || !nodes.length) return;
            nodes.forEach(function(node) {
              const li = node.closest && node.closest('li[data-item]');
              if (!li) return;
              // if (li.getAttribute('data-category') !== 'Temporary') return; // Relaxed check
              const itemId = li.getAttribute('data-item') || li.getAttribute('data-itemid');
              const equipBtn = li.querySelector('[data-action="equip"], [data-action="unequip"], button[name="equip"], button[name="unequip"]');
              const fromBtn = equipBtn ? (equipBtn.dataset.id || equipBtn.getAttribute('data-id') || equipBtn.dataset.armoryid || equipBtn.getAttribute('data-armoryid')) : null;
              const fromLi = li.dataset.armoryid || li.getAttribute('data-armoryid') || li.dataset.id || li.getAttribute('data-id');
              const resolved = fromLi || fromBtn;
              if (itemId && resolved) {
                setTempCache(String(itemId), String(resolved));
              }
            });
          } catch (_) {}
        }

        // Initial scan
        cacheFromDom(document);

        const observer = new MutationObserver(function(mutations) {
          mutations.forEach(function(mutation) {
            if (mutation.addedNodes && mutation.addedNodes.length) {
              mutation.addedNodes.forEach(function(node) {
                if (node && node.nodeType === 1) {
                  cacheFromDom(node);
                }
              });
            }
          });
        });
        observer.observe(document.body || document.documentElement, { childList: true, subtree: true });
        window._pdaTempDomObserver = observer;
        logTemp('DOM Observer: Installed');
      } catch (_) {}
    }

    // Client-side UI update after equip/unequip action
    // Parses the response to detect equip/unequip via data-equip attribute, then:
    // 1. Calls Torn's loadEquippedItems() to refresh the loadout panel
    // 2. Updates item list classes as best-effort fallback
    function updateEquippedUI(response) {
      try {
        var respStr = '';
        if (typeof response === 'string') {
          respStr = response;
        } else if (response && response.text) {
          respStr = response.text;
        } else if (response) {
          try { respStr = JSON.stringify(response); } catch(_) {}
        }
        if (!respStr) return;

        // Detect equip/unequip via data-equip attribute
        var isUnequipped = /data-equip="unequipped/i.test(respStr);
        var isEquipped = !isUnequipped && /data-equip="equipped/i.test(respStr);
        if (!isEquipped && !isUnequipped) return;

        // Refresh Torn's loadout panel
        setTimeout(function() {
          try {
            if (typeof window.loadEquippedItems === 'function') {
              window.loadEquippedItems();
            }
          } catch(e) {}
        }, 200);

      } catch(e) {}
    }

    var _tempDebugLogging = $kDebugMode; // Use Flutter's kDebugMode

    // Helper for debug logging with timestamp
    // Usage: Called throughout the lifecycle to trace ID resolution (Strategies 0-3)
    function logTemp(msg, obj) {
      if (!_tempDebugLogging) return;
      try {
        if (typeof console !== 'undefined') {
          // var time = new Date().toISOString().split('T')[1].replace('Z', '');
          // console.log('[PDA][TempID][' + time + '] ' + msg, obj || '');
        }
      } catch (_) {}
    }

    // Dictionary of ItemID -> EquipID valid for this session
    // Usage: Accessed by all strategies to share found IDs during the session
    function getTempCache() {
      // Memory-only cache for current session
      if (!window._pdaTempEquipCache) {
          window._pdaTempEquipCache = {};
      }
      return window._pdaTempEquipCache;
    }

    // Saves a valid ID pair to memory and persists it to Flutter (Level 1)
    // Usage: Called whenever a strategy (Interceptor, Observer, Search, Scroll) finds a valid ID
    function setTempCache(itemId, equipId) {
      if (!itemId || !equipId) return;
      const cache = getTempCache();
      if (cache[itemId] === equipId) return;
      
      // 1. Memory Storage (Session)
      cache[itemId] = equipId;
      
      // 2. Persistent Storage (via Flutter)
      try {
          if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
              window.flutter_inappwebview.callHandler('updateQuickItemInstanceId', itemId, equipId);
          }
      } catch(e) {}
    }

    // Removes an invalid ID from the cache
    // Usage: Called during Error Recovery when the server returns "Wrong itemID" to force a fresh lookup
    function clearTempCache(itemId) {
      try {
        const cache = getTempCache();
        if (cache[itemId]) {
          delete cache[itemId];
          logTemp('Cache: Cleared ID for item', itemId);
        }
      } catch (_) {}
    }

    // Helps identify the main scrolling area
    // Usage: Called by Level 3 (Scroll Strategy) to determine where to scroll
    // [Used by Level 3]
    function findScrollContainer() {
      const candidates = [
        document.querySelector('div.items-wrap'),
        document.querySelector('div.items-wrap ul'),
        document.querySelector('.items-wrap'),
        document.querySelector('.items-cont'),
        document.querySelector('#items')
      ].filter(Boolean);

      for (let i = 0; i < candidates.length; i++) {
        const el = candidates[i];
        if (!el) continue;
        if (el.scrollHeight > el.clientHeight) return el;
      }

      const scrollingEl = document.scrollingElement || document.documentElement || document.body;
      return scrollingEl;
    }



    // ========================================================================
    // LEVEL 3: SCROLL FALLBACK
    // ========================================================================
    // Scans the DOM by scrolling if API strategies fail
    // Usage: Level 3 Fallback. Called only if Level 1 and Level 2 both fail
    // [Level 3: Scroll Strategy]
    function doScrollForTemporary(callback) {
      logTemp('Level 3: Starting Scroll (Fast Mode)');
      
      // Show toast
      try {
        window.flutter_inappwebview.callHandler('showToast', {
          text: 'Fetching...',
          seconds: 2,
          bgColor: { a: 255, r: 100, g: 100, b: 100 }
        });
      } catch(e) {}
      
      // Helper to scan DOM
      function scanForItem() {
        const cache = getTempCache();
        
        // 1. Check Cache
        if (cache[itemId]) {
            return cache[itemId];
        }

        // 2. Check DOM (Strategy 1)
        const selectors = [
          'li[data-item="' + itemId + '"]',
          'li[data-itemid="' + itemId + '"]',
          'li[data-id="' + itemId + '"]',
          'li[data-armory-item-id="' + itemId + '"]'
        ];
        
        for (let i = 0; i < selectors.length; i++) {
          const list = document.querySelectorAll(selectors[i]);
          for (let j = 0; j < list.length; j++) {
            const li = list[j];
            if (!li) continue;

            const equipBtn = li.querySelector('[data-action="equip"]') || 
                             li.querySelector('[data-action="unequip"]') || 
                             li.querySelector('button[name="equip"]') || 
                             li.querySelector('button[name="unequip"]');
            
            const fromBtn = equipBtn ? (equipBtn.dataset.id || equipBtn.dataset.armoryid || equipBtn.getAttribute('data-id')) : null;
            const fromLi = li.dataset.armoryid || li.dataset.id || li.getAttribute('data-id');
            const found = fromLi || fromBtn;

            if (found && found !== '0') {
              logTemp('Level 3: Found in DOM via selector', found);
              setTempCache(itemId, found);
              return found;
            }
          }
        }
        
        return null;
      }
      
      try {
        const scrollEl = findScrollContainer();
        const origY = scrollEl.scrollTop;
        
        // Initial setup
        logTemp('Scroll container found.');
        
        function finish(foundId) {
          // Remove custom overlay if exists
          const ov = document.getElementById('pda-loading-overlay');
          if (ov) ov.remove();
          
          scrollEl.scrollTop = origY;
          callback(foundId);
        }
        
        // 1. Initial Scan
        let found = scanForItem();
        if (found) {
          logTemp('Level 3: Found immediately in initial scan');
          finish(found);
          return;
        }

        // SHOW OVERLAY
        // We are about to scroll like crazy, so hide it from user
        if (!document.getElementById('pda-loading-overlay')) {
            const ov = document.createElement('div');
            ov.id = 'pda-loading-overlay';
            ov.style.cssText = 'position:fixed;top:0;left:0;width:100%;height:100%;z-index:999999;display:flex;flex-direction:column;align-items:center;justify-content:center;background-color:#333;color:#fff;font-family:Arial,sans-serif;font-weight:bold;font-size:16px;opacity:0.95;';
            
            // Check theme
            const isDark = document.body.classList.contains('dark-mode') || document.querySelector('body[class*="dark"]');
            if (!isDark) {
                ov.style.backgroundColor = '#fff';
                ov.style.color = '#333';
            }
            
            // Use provided itemName if available, else item ID
            const displayName = (typeof itemName !== 'undefined' && itemName && itemName !== 'null') ? itemName : itemId;
            
            ov.innerHTML = '<div style="margin-bottom:10px;">Scanning Inventory...</div><div style="font-size:12px;opacity:0.8;">Please wait, locating ' + displayName + '</div>';
            document.body.appendChild(ov);
        }

        // 2. Smart Scroll Sweep (Dynamic)
        // Keep scrolling until height stops increasing
        
        let attempts = 0;
        let lastHeight = 0;
        let sameHeightCount = 0;
        const MAX_SAME_HEIGHT = 15;
        
        function checkLoop() {
          const currentHeight = scrollEl.scrollHeight;
          if (currentHeight > lastHeight) {
             lastHeight = currentHeight;
             sameHeightCount = 0;
             // Page grew
          } else {
             sameHeightCount++;
          }
        
          found = scanForItem();
          if (found) {
            finish(found);
            return;
          }
          
          attempts++;
          const maxScroll = Math.max(scrollEl.scrollHeight - scrollEl.clientHeight, 0);

          // Phase 1: Aggressive Scroll Down (until height stabilizes)
          if (sameHeightCount < MAX_SAME_HEIGHT && attempts < 150) { // Increased: Max 15 seconds
             scrollEl.scrollTop = maxScroll;
             // Force window scroll too, sometimes needed for body attached events
             try { window.scrollTo(0, document.body.scrollHeight); } catch(e) {}
             
             setTimeout(checkLoop, 100);
          }
          // Phase 2: Once stabilized, do a middle sweep
          // We might have skipped over items while fast-scrolling
          else if (attempts < 170) {
             if (attempts % 5 === 0) {
                 // Check top, middle, bottom
                 const phase = Math.floor((attempts - 150) / 5);
                 const targets = [maxScroll * 0.66, maxScroll * 0.33, 0];
                 if (phase < 3) {
                    scrollEl.scrollTop = targets[phase];
                 }
             }
             setTimeout(checkLoop, 100);
          }
          else {
             logTemp('Level 3: Failed after sweep');
             finish(null);
          }
        }
        checkLoop();
        
      } catch(err) {
        logTemp('Scroll error', err);
        callback(null);
      }
    }

    // Strategy 0: Quick lookup in Cache or current visible DOM
    // Usage: Called at startup and immediately before action execution to prefer fresh DOM data
    // [Strategy 0: Immediate DOM Check]
    function resolveTemporaryEquipId(itemId) {
      try {
        const cache = getTempCache();
        if (cache[itemId]) {
          logTemp('Cache Hit: Resolved ID', cache[itemId]);
          return cache[itemId];
        }
      // logTemp('Resolving temporary equip id for item', itemId);
      const selectors = [
          'li[data-item="' + itemId + '"]',
          'li[data-itemid="' + itemId + '"]',
          'li[data-id="' + itemId + '"]',
          'li[data-armory-item-id="' + itemId + '"]'
        ];
        const nodes = document.querySelectorAll(selectors.join(','));
      // logTemp('Temporary DOM nodes found', nodes.length);
      for (let i = 0; i < nodes.length; i++) {
          const li = nodes[i];
          if (!li) continue;
          const equipBtn = li.querySelector('[data-action="equip"], [data-action="unequip"], button[name="equip"], button[name="unequip"]');
          const fromBtn = equipBtn ? (equipBtn.dataset.id || equipBtn.getAttribute('data-id') || equipBtn.dataset.armoryid || equipBtn.getAttribute('data-armoryid')) : null;
          const fromLi = li.dataset.armoryid || li.getAttribute('data-armoryid') || li.dataset.id || li.getAttribute('data-id');
          const resolved = fromLi || fromBtn;
          if (resolved) {
            setTempCache(itemId, resolved);
            logTemp('DOM Scan: Resolved ID', resolved);
          }
          if (resolved) return resolved;
        }
      } catch (e) {}
      // logTemp('DOM Scan: No ID found');
      return null;
    }

    // Use jQuery AJAX if available
    // Usage: Called by executeAction() to perform the actual Equip/Use request
    // [Action Execution - All Levels]
    function useItemWithJQuery(itemId, isEquipAction, equipId, callback) {
      if (typeof \$ !== 'undefined' && \$.ajax) {
        var ajaxUrl = "item.php?rfcv=" + getRFC();
        var ajaxData;
        
        if (isEquipAction) {
          ajaxData = { step: "actionForm", confirm: 1, action: "equip", id: equipId };
        } else {
          ajaxData = { step: "useItem", itemID: itemId, item: itemId };
        }
        
        \$.ajax({
          url: ajaxUrl,
          type: "POST",
          data: ajaxData,
          success: function(response) {
            callback(response, null);
            // Refresh Torn's loadout panel for equip actions only
            if (isEquipAction) {
              updateEquippedUI(response);
            }
          },
          error: function(xhr, status, error) {
            callback(null, error);
          }
        });
        return true;
      }
      return false;
    }
    
    var url = "";
    if (!$eRefill && !$nRefill) {
      url = "https://www.torn.com/" + addRFC("item.php");
    } else {
      url = "https://www.torn.com/" + addRFC("factions.php");
    }

    // ========================================================================
    // LEVEL 1: PERSISTENCE & INITIALIZATION
    // ========================================================================
    var resolvedId = "$instanceId";
    var abortEquip = false;
    var itemId = "$item";
    var itemName = "$itemName";
    var isTemporaryItem = $isTemporary;
    var tempRetryAttempted = false;

    if (isTemporaryItem) {
      // Capture items from future XHR/Fetch requests and DOM changes
      installTempInterceptor();
      startTempDomCacheObserver();
      
      // Quick DOM scan (This is "Strategy 0" - Pre-check)
      // If the item is already visible on screen, we don't need any Strategies.
      const domId = resolveTemporaryEquipId(itemId);
      if (domId) {
        resolvedId = domId;
        logTemp('Strategy 0 (Current View): SUCCESS - Using ID from DOM', resolvedId);
      } else {
        // If DOM failed, we rely on Flutter ID if it exists
        if (resolvedId !== "" && resolvedId !== "null") {
             logTemp('Level 1 (Persistence): SUCCESS - Using cached ID', resolvedId);
        } else {
             // If Flutter ID is empty, we will proceed to Level 2 (API) or Level 3 (Scroll) in runAction()
             logTemp('Level 1 (Persistence): EMPTY - Will attempt Level 2 & 3 on action');
        }
      }
    }

    if ($isEquip && (!$faction) && !$eRefill && !$nRefill) {
      if (!isTemporaryItem) {
        // Non-temporary items: use stored instanceId
        if (resolvedId === "" || resolvedId === "null") {
          abortEquip = true;
        }
      }
      // For temporary items: DON'T abort - let it try and handle error
    }

    // ========================================================================
    // LEVEL 2: SEARCH API
    // ========================================================================
    // Fetches item ID using Torn's search functionality (item.php).
    // Usage: Level 2 Strategy via API. Called if Level 1 (Persistence) fails.
    // [Level 2: Search API Strategy]
    function fetchItemViaSearch(name, done) {
      if (!name || name === 'null' || name.length < 2) {
         logTemp('Search skipped: invalid name', name);
         done(null);
         return;
      }
      
      try {
         logTemp('Level 2: Starting Search API for', name);
         var searchUrl = "item.php?rfcv=" + getRFC();
         var formData = "step=getSearchList&q=" + encodeURIComponent(name) + "&start=0&test=true";
         
         // Helper to parse search response
         function parseSearchResponse(respProp) {
              try {
                  var data = typeof respProp === 'string' ? JSON.parse(respProp) : respProp;
                  if (!data || !data.html) return null;
                  
                  // Parse returned HTML
                  var parser = new DOMParser();
                  var doc = parser.parseFromString(data.html, 'text/html');
                  var items = doc.querySelectorAll('li[data-item="' + itemId + '"]');
                  
                  // console.log("DEBUG: items found via Search API: " + items.length);

                  for (var i = 0; i < items.length; i++) {
                       var li = items[i];
                       
                       var dQty = li.getAttribute('data-qty');
                       var dRowKey = li.getAttribute('data-rowkey');
                       // console.log("DEBUG: Item index " + i + " | Qty: " + dQty + " | RowKey: " + dRowKey);

                       // Look for equip ID
                       var equipBtn = li.querySelector('[data-action="equip"], [data-action="unequip"]');
                       var id = equipBtn ? (equipBtn.dataset.id || equipBtn.getAttribute('data-id')) : null;
                       if (!id) id = li.dataset.id || li.getAttribute('data-id');
                       // Sometimes data-id on the li itself is correct for temporary items
                       
                       // Double check if equip_id is essentially same as item_id (which means not an instance)
                       // But for many temp items they might be the same or different. 
                       // The important part is finding a valid ID that works for action=equip&id=...
                       
                       if (id) {
                           logTemp('Level 2: ID Found via API', id);
                           setTempCache(itemId, id);
                           return id;
                       }
                  }
              } catch(e) {
                  logTemp('Error parsing search response', e);
              }
              return null;
         }

         if (typeof \$ !== 'undefined' && \$.ajax) {
             \$.ajax({
                 url: searchUrl,
                 type: "POST",
                 data: formData,
                 success: function(resp) {
                     done(parseSearchResponse(resp));
                 },
                 error: function() { done(null); }
             });
         } else {
             // Fallback: If jQuery is missing (rare)
             logTemp('Search API ignored: jQuery not found');
             done(null);
         }
      } catch(e) {
         logTemp('Search API exception', e);
         done(null);
      }
    }

    function runAction() {
      if (abortEquip) return;
      
      // For temporary items without ID...
      if (isTemporaryItem && $isEquip && (resolvedId === "" || resolvedId === "null")) {
        
        // ========================================================================
        // TEMPORARY ITEMS STRATEGY CHAIN
        // ========================================================================
        //
        // Level 1: Persistence (Flutter Storage) - PRE-CHECKED
        // - At start, we checked if 'resolvedId' was injected by Flutter
        // - If we are here, Level 1 failed (it was empty or null)
        //
        // Level 2: Search API (Network) - PRIMARY FALLBACK
        // - We call item.php?step=getSearchList to find the item ID in the background
        // - This is fast and invisible to the user
        //
        // Level 3: Scroll (DOM) - FINAL RESORT
        // - If Level 2 fails (API change/network error), we physically scroll the page 
        //   looking for the item in the DOM
        // ========================================================================
        
        logTemp('Level 1 failed (No Flutter ID). Trying Level 2: Search API...');
        
        // Show toast indicating "Searching..." instead of "Fetching..."
        try {
            window.flutter_inappwebview.callHandler('showToast', {
              text: 'Searching details...',
              seconds: 2,
              bgColor: { a: 255, r: 100, g: 100, b: 100 }
            });
        } catch(e) {}

        fetchItemViaSearch(itemName, function(searchId) {
             if (searchId) {
                 resolvedId = searchId;
                 logTemp('Level 2: Success! Proceeding with action', resolvedId);
                 executeAction();
             } else {
                 logTemp('Level 2 failed. Proceeding to Level 3: Scroll');
                 doScrollForTemporary(function(foundId) {
                      if (foundId) {
                        resolvedId = foundId;
                        logTemp('Level 3: Success! Proceeding with action', resolvedId);
                        executeAction();
                      } else {
                        logTemp('Level 3: Failed. Could not find ID.');
                        try {
                          window.flutter_inappwebview.callHandler('showToast', {
                            text: 'Item ' + itemId + ' not found',
                            seconds: 3,
                            bgColor: { a: 255, r: 255, g: 87, b: 34 }
                          });
                        } catch(e) {}
                      }
                 });
             }
        });
        return;
      }
      
      executeAction();
    }
    
    // Performs the final Equip/Use action via API
    // Usage: Called by runAction() once a valid ID is secured from any strategy
    // [Action Execution - All Levels]
    function executeAction() {
      // 1. Setup Flags
      var isFaction = $faction;
      var isRefill = $eRefill || $nRefill;
      var isStandard = !isFaction && !isRefill;
      var validId = resolvedId !== "" && resolvedId !== "null";
      var isEquip = $isEquip;
      
      var canEquip = isStandard && isEquip && validId;

      if (canEquip && isTemporaryItem) {
        var tempIdPre = resolveTemporaryEquipId(itemId);
        if (tempIdPre && tempIdPre !== resolvedId) {
          resolvedId = tempIdPre;
          logTemp('Pre-request update: ID changed to', resolvedId);
        }
      }

      // 2. Execution Use jQuery AJAX (Standard Actions)
      if (isStandard) {
        function handleJQueryResponse(response, error) {
          if (error) return;

          // A. Normalize Response
          // Ensure we have both an Object (if possible) and a String representation for safe checking
          var respObj = null;
          var respStr = "";

          if (typeof response === 'string') {
            respStr = response;
            try { respObj = JSON.parse(response); } catch (e) {}
          } else if (typeof response === 'object') {
            respObj = response;
            try { respStr = JSON.stringify(response); } catch (e) {}
          }

          // B. Error Verification
          // Check for "Wrong itemID" in the string representation
          if (respStr && respStr.includes('Wrong itemID')) {
            // ERROR RECOVERY:
            // If the ID we used (from Persistence or API) was stale, Torn returns "Wrong itemID"
            // We clear the cache and immediately trigger Level 2 (Search API) again to get a fresh ID
            if (isTemporaryItem && !tempRetryAttempted) {
              tempRetryAttempted = true;
              clearTempCache(itemId);
              logTemp('Wrong itemID - clearing cache and attempting Level 2 (Search API)');
              
              fetchItemViaSearch(itemName, function(searchId) {
                  if (searchId && searchId !== resolvedId) {
                       resolvedId = searchId;
                       logTemp('Level 2 (Retry): Success, retrying action', resolvedId);
                       useItemWithJQuery(itemId, true, resolvedId, handleJQueryResponse);
                  } else {
                       logTemp('Level 2 (Retry): Failed, trying Level 3');
                       doScrollForTemporary(function(newTempId) {
                            if (newTempId && newTempId !== resolvedId) {
                              resolvedId = newTempId;
                              logTemp('Level 3 (Retry): Success, retrying action', resolvedId);
                              useItemWithJQuery(itemId, true, resolvedId, handleJQueryResponse);
                            } else {
                              try {
                                window.flutter_inappwebview.callHandler('showToast', {
                                  text: 'Could not find valid item ID - item may have been used',
                                  seconds: 4,
                                  bgColor: { a: 255, r: 255, g: 87, b: 34 }
                                });
                              } catch(e) {}
                            }
                       });
                  }
              });
              return;
            }
            try {
              window.flutter_inappwebview.callHandler('showToast', {
                text: 'Wrong item ID - please update your quick items!',
                seconds: 4,
                bgColor: { a: 255, r: 255, g: 87, b: 34 }
              });
            } catch(e) {}
            return;
          }

          // C. Success Display
          var topBox = document.querySelector('.content-title');
          if (topBox) {
            document.querySelectorAll('.resultBox').forEach(function(box) { box.remove(); });
            topBox.insertAdjacentHTML('afterend', '<div class="resultBox"></div>');
            var resultBox = document.querySelector('.resultBox');
            resultBox.style.display = "block";

            // try { console.log('[PDA][QuickItems] raw response:', response); } catch (_) {}
            // try { console.log('[PDA][QuickItems] raw respStr:', respStr); } catch (_) {}

            // Prefer using the properly parsed 'text' field
            let resultHtml = '';
            if (respObj && respObj.text) {
              resultHtml = respObj.text;
            } else if (respObj && respObj.message) {
              resultHtml = respObj.message;
            } else if (respStr && (respStr.trim().startsWith('<') || respStr.includes('<a') || respStr.includes('<div'))) {
              resultHtml = respStr;
            } else if (respStr && respStr.trim().startsWith('{')) {
              try {
                const parsed = JSON.parse(respStr);
                resultHtml = parsed.text || parsed.message || '';
              } catch (_) {}
            }

            resultHtml = decodeHtmlEntities(resultHtml);
            var linksHtml = '';
            if (respObj && respObj.links) {
              linksHtml = buildLinksHtml(respObj.links);
            } else if (respStr && respStr.trim().startsWith('{')) {
              try {
                const parsed = JSON.parse(respStr);
                linksHtml = buildLinksHtml(parsed.links);
              } catch (_) {}
            }
            if (linksHtml) {
              resultHtml = (resultHtml ? resultHtml + '<br>' : '') + linksHtml;
            }
            if (resultHtml) {
              let fixResult = fixTime(resultHtml);
              resultBox.innerHTML = fixResult || resultHtml;
            } else {
              resultBox.innerHTML = respStr || (respObj ? JSON.stringify(respObj) : "Error parsing response");
            }

            // Make links actionable
            if (!resultBox.getAttribute('data-pda-links')) {
              resultBox.setAttribute('data-pda-links', '1');
              resultBox.addEventListener('click', function(e) {
                try {
                  var link = e.target && e.target.closest ? e.target.closest('a') : null;
                  if (!link) return;
                  var isQuickLink = link.classList.contains('next-act') || link.classList.contains('decrement-amount') || link.getAttribute('data-item');
                  if (!isQuickLink) return;
                  e.preventDefault();
                  useItemWithJQuery(itemId, canEquip, resolvedId, handleJQueryResponse);
                } catch (_) {}
              });
            }
          }
        }
        useItemWithJQuery(itemId, canEquip, resolvedId, handleJQueryResponse);
      } else {
        // 3. Fallback for Faction/Refills (Vanilla JS)
        if (canEquip) {
          ajaxWrapper({
            url: url,
            type: 'POST',
            data: 'step=actionForm&confirm=1&action=equip&id=' + resolvedId,
            oncomplete: function(resp) {
              var response = resp.responseText;
              
              // Check for "Wrong itemID" error
              if (response && response.includes('Wrong itemID')) {
                try {
                  window.flutter_inappwebview.callHandler('showToast', {
                    text: 'Wrong item ID - please update your quick items!',
                    seconds: 4,
                    bgColor: { a: 255, r: 255, g: 87, b: 34 }
                  });
                } catch(e) {}
                return;
              }
              
              var topBox = document.querySelector('.content-title');
              document.querySelectorAll('.resultBox').forEach(function(box) { box.remove(); });
              topBox.insertAdjacentHTML('afterend', '<div class="resultBox">2</div>');
              resultBox = document.querySelector('.resultBox');
              resultBox.style.display = "block";
              resultBox.innerHTML = response;
              // Refresh Torn's loadout panel
              updateEquippedUI(response);
            },
            onerror: function(e) {}
          });
        } else {
            if (!$eRefill && !$nRefill) {
              ajaxWrapper({
                url: url,
                type: 'POST',
                data: 'step=useItem&itemID=$item&fac=1',
                oncomplete: function(resp) {
                  var response = JSON.parse(resp.responseText);
                  var topBox = document.querySelector('.content-title');
                  document.querySelectorAll('.resultBox').forEach(function(box) { box.remove(); });
                  topBox.insertAdjacentHTML('afterend', '<div class="resultBox">2</div>');
                  resultBox = document.querySelector('.resultBox');
                  resultBox.style.display = "block";
                  response.text = response.text.replace("This item has already been used", "Not available");
                  
                  let fixResult = fixTime(response.text);
                  if (fixResult === "") {
                    resultBox.innerHTML = response.text;
                  } else {
                    resultBox.innerHTML = fixResult;
                  }
                },
                onerror: function(e) {}
              });
            } else {
              let step = $eRefill ? "step=armouryRefillEnergy" : "step=armouryRefillNerve";

              ajaxWrapper({
                url: url,
                type: 'POST',
                data: step,
                oncomplete: function(resp) {
                  var response = JSON.parse(resp.responseText);
                  var topBox = document.querySelector('.content-title');
                  document.querySelectorAll('.resultBox').forEach(function(box) { box.remove(); });
                  topBox.insertAdjacentHTML('afterend', '<div class="resultBox">2</div>');
                  resultBox = document.querySelector('.resultBox');
                  resultBox.style.display = "block";
                  if (response.success === false) {
                    resultBox.innerHTML = response.message;
                  } else {
                    resultBox.innerHTML = response.message;
                  }
                },
                onerror: function(e) {}
              });
            }
        }
      }
    }

    // Execute the action - runAction() handles temporary items that need scrolling
    runAction();

    // DEBUG: ALWAYS FORCE A SEARCH TO SEE THE LOGS
    // console.log("DEBUG: Forcing background search for " + itemName);
    // fetchItemViaSearch(itemName, function(sId) {
    //   console.log("DEBUG: Background search finished. Result ID: " + sId);
    // });
    
    // Get rid of the resultBox on close
    document.addEventListener("click", (event) => {
      if (event.target.classList.contains("close-act") && event.target.parentElement.parentElement.parentElement.parentElement.classList.contains("resultBox")) {
        document.querySelector(".resultBox").style.display = "none";
      }
    });
    
    // Helper function to pause execution
    function sleep(ms) {
      return new Promise(resolve => setTimeout(resolve, ms));
    }

    // To prevent several boxes appearing if users spam click, we will 
    // wait a few seconds and then remove all except for the very first (most recent item)
    // Usage: Called at the end of the script to keep UI clean
    async function removeRemaining() {
      await sleep(3000);
      var remaining = document.querySelectorAll('.resultBox');
      for (i = 1; i < remaining.length; i++) {
        remaining[i].remove();
      }
    }

    removeRemaining();

    // Return to avoid iOS WKErrorDomain
    123;
  ''';
}

String quickItemPickerJS({required bool enable}) {
  final enabled = enable ? 'true' : 'false';
  return '''
  (function() {
    try {
      // Check if in grid/thumbnails mode (not supported)
      if ($enabled) {
        const thumbnailsIcon = document.querySelector('.link-icon-svg.thumbnails-icon.active, .link-icon-svg.thumbnails.active');
        if (thumbnailsIcon) {
          return 'grid-mode';
        }
      }

      // Config
      const BTN_CLASS = 'pda-item-picker-btn';
      const WRAP_CLASS = 'pda-item-picker-wrap';
      const OBSERVER_KEY = '_pdaPickerObserver';
      const ACTIVE_KEY = '_pdaPickerActive';
      const CLEANUP_FLAG = '_pdaPickerCleanupAdded';
      const QUICK_ITEM_CATEGORIES = ['Medical', 'Drug', 'Energy Drink', 'Alcohol', 'Candy', 'Booster', 'Supply Pack', 'Special'];
      const QUICK_EQUIP_CATEGORIES = ['Primary', 'Secondary', 'Melee', 'Defensive', 'Temporary'];
      const EXCEPTION_ITEMS = ['403', '283'];
      const HIGHLIGHT_CLASS = 'pda-picker-eligible';
      const NARROW_WIDTH_PX = 785; // fallback only

      function getFirstActionsWrap() {
        return document.querySelector('li[data-item] ul.actions-wrap, li[data-item] ul.actions, li[data-item] .actions-wrap ul, li[data-item] .actions ul, li[data-item] .action-wrap ul, li[data-item] .item-actions ul, li[data-item] .actions-wrap, li[data-item] .actions, li[data-item] .action-wrap, li[data-item] .item-actions');
      }

      function isNarrow() {
        // Width detection
        const actionsWrap = getFirstActionsWrap();
        if (actionsWrap) {
          const style = window.getComputedStyle(actionsWrap);
          const isFlex = style.display === 'flex';
          const isColumn = style.flexDirection === 'column';
          if (isFlex && isColumn) return true;
          if (isFlex && style.flexDirection === 'row') return false;

          const firstChild = actionsWrap.querySelector('li');
          if (firstChild) {
            const childStyle = window.getComputedStyle(firstChild);
            const inlineLike = childStyle.display === 'inline' || childStyle.display === 'inline-block';
            if (inlineLike) return false;
            const blockLike = childStyle.display === 'block' && childStyle.width === '100%';
            if (blockLike) return true;
          }
        }
        // Fallback
        return window.innerWidth <= NARROW_WIDTH_PX;
      }

      function clearHighlights() {
        // Remove visual markers from all items
        document.querySelectorAll('.' + HIGHLIGHT_CLASS).forEach(el => el.classList.remove(HIGHLIGHT_CLASS));
      }

      function removeAll() {
        // Remove injected buttons and highlights
        document.querySelectorAll('.' + WRAP_CLASS).forEach(el => el.remove());
        clearHighlights();

        // Restore native action lists where we swapped HTML
        document.querySelectorAll('ul.actions-wrap, ul.actions, .actions-wrap ul, .actions ul, .action-wrap ul, .item-actions ul, .actions-wrap, .actions, .action-wrap, .item-actions').forEach(function(actionsWrap) {
          const original = actionsWrap.getAttribute('data-pda-actions-html');
          if (original !== null) {
            actionsWrap.innerHTML = original;
            actionsWrap.removeAttribute('data-pda-actions-html');
          }
          actionsWrap.classList.remove('pda-picker-actions');
          actionsWrap.style.display = '';
          actionsWrap.style.flexDirection = '';
          actionsWrap.style.alignItems = '';
          actionsWrap.style.justifyContent = '';
          actionsWrap.style.textAlign = '';
          actionsWrap.style.minHeight = '';
          actionsWrap.style.padding = '';
          actionsWrap.style.position = '';
        });

        if (window[OBSERVER_KEY]) {
          window[OBSERVER_KEY].disconnect();
          window[OBSERVER_KEY] = null;
        }
        window.removeEventListener('scroll', addButtons);
        window.removeEventListener('resize', addButtons);
        window[ACTIVE_KEY] = false;
        window[CLEANUP_FLAG] = false;

        try {
          if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
            window.flutter_inappwebview.callHandler('quickItemPickerCleanup', 'disabled');
          }
        } catch (_) {}
      }

      function addButtons() {
        // Update highlights, insert buttons when eligible
        if (!window[ACTIVE_KEY]) {
          return; // If picker was deactivated, ignore stray observer/resize callbacks
        }
        const narrow = isNarrow();
        let addedCount = 0;
        document.querySelectorAll('li[data-item]').forEach(function(li) {
          const itemNum = li.dataset.item;
          if (!itemNum) return;
          // Use getAttribute as fallback for dataset issues
          const rowKey = li.dataset.rowkey || li.getAttribute('data-rowkey');
          const hasWrap = !!li.querySelector('.' + WRAP_CLASS);

          const category = li.dataset.category || null;
          const isQuickItemCategory = category && QUICK_ITEM_CATEGORIES.includes(category);
          const isQuickEquipCategory = category && QUICK_EQUIP_CATEGORIES.includes(category);
          const isExceptionItem = EXCEPTION_ITEMS.includes(itemNum);
          const isTemporary = category === 'Temporary';

          // Skip items outside allowed categories/exceptions
          if (!isQuickItemCategory && !isQuickEquipCategory && !isExceptionItem) {
            li.classList.remove(HIGHLIGHT_CLASS);
            return; // Only add buttons for allowed categories or explicit exceptions
          }

          const isSpecialOrOther = category === 'Special' || category === 'Other';
          if (isSpecialOrOther && !isExceptionItem) {
            li.classList.remove(HIGHLIGHT_CLASS);
            return; // Do not inject into Special/Other unless explicitly allowed
          }

          // In narrow mode, visually mark eligible items
          if (narrow) {
            li.classList.add(HIGHLIGHT_CLASS);
          } else {
            li.classList.remove(HIGHLIGHT_CLASS);
          }

          if (hasWrap) return; // Already added button, so keep highlight state in sync above

          const actionsWrap = li.querySelector('ul.actions-wrap') ||
            li.querySelector('ul.actions') ||
            li.querySelector('.actions-wrap ul') ||
            li.querySelector('.actions ul') ||
            li.querySelector('.action-wrap ul') ||
            li.querySelector('.item-actions ul') ||
            li.querySelector('.actions-wrap') ||
            li.querySelector('.actions') ||
            li.querySelector('.action-wrap') ||
            li.querySelector('.item-actions');

          if (!actionsWrap) {
              return; // Skip items that never render an actions container
          }

          const equipBtn = li.querySelector('[data-action="equip"]') || li.querySelector('button[name="equip"]');
          let id = li.dataset.id || li.getAttribute('data-id') || li.dataset.armoryid || li.getAttribute('data-armoryid') || li.getAttribute('data-armory-id') ||
            (equipBtn ? (equipBtn.dataset.id || equipBtn.getAttribute('data-id') || equipBtn.dataset.armoryid || equipBtn.getAttribute('data-armoryid')) : null);
          
          // For non-equip items, fall back to item number so button still appears
          if (!id && itemNum) {
            id = itemNum;
          }
          if (!id) {
            li.setAttribute('data-pda-picker-noid', '1');
            return;
          }

          const name = (li.dataset.sort || (li.querySelector('.name') ? li.querySelector('.name').textContent.trim() : ''));
          const qtyRaw = li.dataset.qty || li.getAttribute('data-qty');
          const qty = parseInt(qtyRaw, 10);

          let damage = null, accuracy = null, defense = null;
          const bonusLis = li.querySelectorAll('.bonuses-wrap li');
          bonusLis.forEach(function(bonusLi) {
            const span = bonusLi.querySelector('span');
            const valText = span && span.textContent ? span.textContent.trim() : null;
            const valNum = valText ? parseFloat(valText) : null;
            const cls = bonusLi.querySelector('i');
            const className = cls && cls.className ? cls.className : '';
            if (className.indexOf('damage') !== -1 && valNum !== null && !isNaN(valNum)) damage = valNum;
            if (className.indexOf('accuracy') !== -1 && valNum !== null && !isNaN(valNum)) accuracy = valNum;
            if (className.indexOf('defence') !== -1 && valNum !== null && !isNaN(valNum)) defense = valNum;
          });

          const wrap = document.createElement('li');
          wrap.className = WRAP_CLASS + ' re_add_qitem';
          wrap.style.width = '100%';
          wrap.style.position = 'relative';
          wrap.style.display = 'flex';
          wrap.style.justifyContent = 'center';
          wrap.style.alignItems = 'center';
          wrap.style.padding = '0';

          const btn = document.createElement('button');
          btn.className = BTN_CLASS + ' pda-picker-main-btn';
          btn.setAttribute('aria-label', 'Add ' + name + ' to quick items');
          btn.title = 'Add to quick items';
          btn.innerHTML = '<span class="pda-picker-label">ADD QUICK</span>';
          btn.addEventListener('click', function(ev) {
            ev.stopPropagation();
            ev.preventDefault();

            // SIMPLIFIED & ROBUST: Use the closure 'li' variable. 
            // It refers to the specific list item this button belongs to.
            var rKey = "";
            try {
              rKey = li.getAttribute('data-rowkey');
              if (!rKey && li.dataset) rKey = li.dataset.rowkey;
            } catch (e) {}
            if (!rKey) rKey = "";
            
            if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
              window.flutter_inappwebview.callHandler('quickItemPicker', {
                item: itemNum,
                rowKey: rKey,
                instanceId: isTemporary ? '' : id,
                name: name,
                category: category,
                qty: isNaN(qty) ? null : qty,
                damage: damage,
                accuracy: accuracy,
                defense: defense,
                armoryId: isTemporary ? null : (li.dataset.armoryid || (equipBtn ? equipBtn.dataset.armoryid : null) || null),
                equipped: li.dataset.equipped === 'true'
              });
            }
          });

          wrap.appendChild(btn);

          // Replace action list with our button; cache original for restoration
          if (!actionsWrap.hasAttribute('data-pda-actions-html')) {
            actionsWrap.setAttribute('data-pda-actions-html', actionsWrap.innerHTML);
          }
          while (actionsWrap.firstChild) {
            actionsWrap.removeChild(actionsWrap.firstChild);
          }
          actionsWrap.classList.add('pda-picker-actions');
          actionsWrap.style.display = 'flex';
          actionsWrap.style.flexDirection = 'column';
          actionsWrap.style.textAlign = 'center';
          actionsWrap.style.position = 'relative';
          actionsWrap.style.minHeight = '42px';
          actionsWrap.style.justifyContent = 'center';
          actionsWrap.style.alignItems = 'center';
          actionsWrap.style.padding = '6px 0';
          actionsWrap.appendChild(wrap);
          addedCount++;
        });
        if (typeof console !== 'undefined') {
          //console.debug('[PDA picker] added buttons:', addedCount);
        }
      }

      if ($enabled === false) {
        removeAll();
        return 'picker-disabled';
      }

      if (window[ACTIVE_KEY]) {
        return 'picker-already-active';
      }
      window[ACTIVE_KEY] = true;

      const styleId = 'pda-item-picker-style';
      if (!document.getElementById(styleId)) {
        const style = document.createElement('style');
        style.id = styleId;
        style.textContent = `
          .\${WRAP_CLASS}, .re_add_qitem {
            display: block;
            clear: both;
            width: 100%;
            margin-top: 6px;
            list-style: none;
          }
          ul.actions-wrap .\${WRAP_CLASS}, ul.actions .\${WRAP_CLASS},
          ul.actions-wrap .re_add_qitem, ul.actions .re_add_qitem {
            float: none;
            width: 100%;
            display: block;
            clear: both;
            padding: 6px 0;
          }
          .pda-picker-actions {
            display: flex !important;
            flex-direction: column !important;
            align-items: center !important;
            justify-content: center !important;
            min-height: 28px !important;
            padding: 0 !important;
          }
          .pda-picker-main-btn {
            border: 1px solid #ff8000 !important;
            background: transparent !important;
            color: #ff8000 !important;
            border-radius: 10px !important;
            position: relative !important;
            top: auto !important;
            left: auto !important;
            transform: none !important;
            height: 18px !important;
            min-width: 64px !important;
            padding: 0 6px !important;
            text-align: center !important;
            line-height: 16px !important;
            font-size: 10px !important;
            white-space: nowrap !important;
            cursor: pointer !important;
            z-index: 999 !important;
            font-weight: bold !important;
            box-sizing: border-box !important;
            text-decoration: none !important;
            display: inline-flex !important;
            align-items: center !important;
            justify-content: center !important;
          }
          .\${HIGHLIGHT_CLASS} {
            outline: 1px solid #ff8000 !important;
            outline-offset: -1px !important; /* keep stroke inside to avoid clipping */
            border-radius: 10px !important;
            box-shadow:
              0 0 0 1px rgba(255, 128, 0, 0.16) inset,
              0 0 0 1px rgba(255, 128, 0, 0.10) !important;
            overflow: visible !important;
          }
          .pda-picker-main-btn:hover { filter: brightness(1.05); }
          .pda-picker-main-btn:active { transform: translateY(1px); }
        `;
        document.head.appendChild(style);
      }

      addButtons();

      const observer = new MutationObserver(addButtons);
      observer.observe(document.body, { childList: true, subtree: true });
      window[OBSERVER_KEY] = observer;

      window.addEventListener('scroll', addButtons, { passive: true });
      window.addEventListener('resize', addButtons, { passive: true });

      if (!window[CLEANUP_FLAG]) {
        const cleanup = () => removeAll();
        window.addEventListener('pagehide', cleanup, { once: true });
        window.addEventListener('beforeunload', cleanup, { once: true });
        window.addEventListener('unload', cleanup, { once: true });
        window[CLEANUP_FLAG] = true;
      }
      return 'picker-ready';
    } catch (e) {
      if (typeof console !== 'undefined') {
        console.error('[PDA picker] fatal error', e);
      }
      return 'picker-error';
    }
  })();
''';
}

String quickItemsMassCheckJS(List<String> itemNames) {
  final namesJson = jsonEncode(itemNames);
  return '''
      (function() {
        var items = $namesJson;
        // console.log("PDA Mass Check: Starting for " + items.length + " items");

        function getRFC() {
          var name = "rfc_v=";
          var ca = document.cookie.split(';');
          for(var i = 0; i < ca.length; i++) {
            var c = ca[i];
            while (c.charAt(0) == ' ') c = c.substring(1);
            if (c.indexOf(name) === 0) return c.substring(name.length, c.length);
          }
          return "";
        }

        async function processQueue() {
          // console.log("PDA Mass Check: Starting queue of " + items.length + " items");
          var promises = items.map(function(name) {
            return new Promise((resolve) => {
              var searchUrl = "item.php?rfcv=" + getRFC();
              var formData = "step=getSearchList&q=" + encodeURIComponent(name) + "&start=0&test=true";
              
              // console.log("PDA Mass Check: Requesting " + name);
              
              try {
                 // Use basic XHR or jQuery if available
                 if (typeof \$ !== 'undefined' && \$.ajax) {
                     \$.ajax({
                         url: searchUrl,
                         type: "POST",
                         data: formData,
                         success: function(resp) {
                             // console.log("PDA Mass Check: Success " + name);
                             processResponse(name, resp);
                             resolve();
                         },
                         error: function(xhr, status, error) { 
                             // console.error("PDA Mass Check: Error " + name + " Status: " + status);
                             resolve(); 
                         }
                     });
                 } else {
                     // Fallback XHR
                     var xhr = new XMLHttpRequest();
                     xhr.open("POST", searchUrl, true);
                     xhr.setRequestHeader("Content-Type", "application/x-www-form-urlencoded");
                     xhr.onreadystatechange = function() {
                         if (this.readyState === XMLHttpRequest.DONE) {
                           if (this.status === 200) {
                               // console.log("PDA Mass Check: Success XHR " + name);
                               processResponse(name, this.responseText);
                           } else {
                               // console.error("PDA Mass Check: Error XHR " + name + " Status: " + this.status);
                           }
                           resolve();
                         }
                     }
                     xhr.send(formData);
                 }
              } catch (e) {
                 // console.error("PDA Mass Check: Exception " + name, e);
                 resolve();
              }
            });
          });
          
          await Promise.all(promises);
          // console.log("PDA Mass Check: Queue finished");
        }

        function processResponse(itemName, encodedData) {
           try {
              var data = typeof encodedData === 'string' ? JSON.parse(encodedData) : encodedData;
              if (!data || !data.html) return;
              
              var parser = new DOMParser();
              var doc = parser.parseFromString(data.html, 'text/html');
              // The search usually returns a list.
              var lis = doc.querySelectorAll('li[data-item]');
              
              var results = {}; 

              for (var k = 0; k < lis.length; k++) {
                 var li = lis[k];
                 var dName = li.getAttribute('data-sort') || (li.querySelector('.name') ? li.querySelector('.name').innerText : "");
                 var dRowKey = li.getAttribute('data-rowkey');
                 
                 // Try to get quantity
                 var rawQty = li.getAttribute('data-qty');
                 var dQty = parseInt(rawQty);
                 
                 // If parsing failed, and it is a unique item 'u', assume 1
                 if (isNaN(dQty)) {
                    if (dRowKey && dRowKey.startsWith('u')) {
                       dQty = 1; 
                    } else {
                       // If we can't find quantity and don't know it's a unique item, use default 1?
                       // Or skip? Let's assume 1 to be safe if it's there but empty
                       // But often empty means 0? No, Torn usually hides the item if 0.
                       // Let's safer assume 1 if it's visible.
                       dQty = 1;
                    }
                 }
                 
                 // Clean name
                 if (!dName) continue;
                 dName = dName.trim();
                 if (dName.length === 0) continue;

                 // console.log("PDA Mass Check DEBUG: Found " + dName + ", Qty: " + dQty + ", RowKey: " + dRowKey);

                 if (!results[dName]) {
                    results[dName] = { qty: 0, rowKey: dRowKey };
                 }
                 results[dName].qty += dQty;
                 if (dRowKey && dRowKey.startsWith('g')) {
                     results[dName].rowKey = dRowKey;
                 }
              }
              
              // Now send the aggregated results
                var wanted = (itemName || '').toString().trim().toLowerCase();
                var foundExact = false;
              for (var key in results) {
                 var res = results[key];
                  if (wanted && key.toString().trim().toLowerCase() === wanted) {
                   foundExact = true;
                  }
                 // console.log("PDA Mass Check DEBUG: Sending " + key + " -> Qty: " + res.qty + ", RowKey: " + res.rowKey);
                 if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                    window.flutter_inappwebview.callHandler('quickItemMassUpdate', {
                       originalName: itemName,
                       foundName: key,
                       qty: res.qty,
                       rowKey: res.rowKey
                    });
                 }
              }

                // If no exact match was found, report qty 0 for the requested item
                if (!foundExact) {
                 if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
                  window.flutter_inappwebview.callHandler('quickItemMassUpdate', {
                    originalName: itemName,
                    foundName: itemName,
                    qty: 0,
                    rowKey: null
                  });
                 }
                }
           } catch(e) {
              console.error("PDA Mass Check: Parsing error", e);
           }
        }

        processQueue();
      })();
      ''';
}

String changeLoadOutJS({required String item, required bool attackWebview}) {
  return '''
    var action = 'https://www.torn.com/page.php?sid=itemsLoadouts&step=changeLoadout&setID=$item';
    
    ajaxWrapper({
      url: action,
      type: 'GET',
      oncomplete: function(resp) {
        if ($attackWebview) {
          window.loadoutChangeHandler.postMessage(resp.responseText);
        } else {
          window.flutter_inappwebview.callHandler('loadoutChangeHandler', resp.responseText);
        }
        // Trigger Torn UI refresh after loadout change
        setTimeout(function() {
          try {
            if (typeof window.loadEquippedItems === 'function') {
              window.loadEquippedItems();
            }
          } catch(e) {}
        }, 200);
      },
      onerror: function(e) {
        console.error(e)
      }
    });

    // Return to avoid iOS WKErrorDomain
    123;
  ''';
}
