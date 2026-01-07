String easyCrimesJS({
  required String nerve,
  required String? crime,
  required String doCrime,
}) {
  return '''
    var first_load = true;
    
    if (first_load) {
      var loadingPlaceholderContent = `
        <div class="content-title m-bottom10">
          <h4 class="left">Crimes</h4>
          <hr class="page-head-delimiter">
          <div class="clear"></div>
        </div>`
        
      first_load = false;
    }
    
    loadingPlaceholderContent += `<img class="ajax-placeholder" src="/images/v2/main/ajax-loader.gif"/>`;
    
    window.location.hash = "#";
    \$(".content-wrapper").html(loadingPlaceholderContent);
    
    var action = 'https://www.torn.com/crimes.php?step=docrime$doCrime&timestamp=' + Date.now();
    
    ajaxWrapper({
      url: action,
      type: 'POST',
      data: 'nervetake=$nerve&crime=$crime',
      oncomplete: function(resp) {
        \$(".content-wrapper").html(resp.responseText);
      },
      onerror: function(e) {
        console.error(e)
      }
    });
    
    // Return to avoid iOS WKErrorDomain
    123;
  ''';
}

String hideItemInfoJS() {
  return '''
    var style = document.createElement('style');
    style.type = 'text/css';
    style.innerHTML = `
      body.pda-hide-item-info div.show-item-info {
        display: none !important;
      }
      /* New UI */
      [id\$="-itemInfoWrapper"] {
        display: none !important;
      }
    `;
    document.head.appendChild(style);
    document.body.classList.add('pda-hide-item-info');
  ''';
}

String ensureMinDocumentHeightForKeyboardJS({double minViewportMultiple = 1.5}) {
  final multiplier = minViewportMultiple.toStringAsFixed(2);

  return '''
    (function applyHeightExtension(runLate) {
      const minHeightPx = Math.ceil(window.innerHeight * $multiplier);
      const doc = document.documentElement;
      const body = document.body || doc;
      const scrolling = document.scrollingElement || doc;

      const scrollingHeight = scrolling ? scrolling.scrollHeight || scrolling.clientHeight || 0 : 0;
      const viewportHeight = window.innerHeight;

      // Enforce a minimum height unconditionally; min-height is harmless on tall pages and ensures space on short ones
      const currentHeight = Math.max(scrollingHeight, viewportHeight);

      let spacer = document.getElementById('pda-height-spacer');

      if (true) {
        const targetHeight = minHeightPx;
        if (body) {
          body.style.minHeight = targetHeight + 'px';
        }

        if (doc) {
          doc.style.minHeight = targetHeight + 'px';
        }

        const gap = Math.max(minHeightPx - currentHeight, 0);

        if (!spacer) {
          spacer = document.createElement('div');
          spacer.id = 'pda-height-spacer';
          spacer.style.width = '100%';
          spacer.style.pointerEvents = 'none';
          spacer.style.background = 'transparent';
          (body || document.documentElement).appendChild(spacer);
        }

        spacer.style.height = gap + 'px';
      }

      // Re-evaluate shortly after load to catch late layout changes; silent on the second pass.
      if (!runLate) {
        setTimeout(() => applyHeightExtension(true), 500);
      }
    })(false);
  ''';
}

String buyMaxAbroadJS({bool preventBasketKeyboard = true}) {
  return '''

  var preventBasketKeyboard = $preventBasketKeyboard;

  function parseMoney(text) {
    var clean = text.replace(/\\\$/g, '').trim().toLowerCase();
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
    // If we can't find money, we might be elsewhere else (e.g. Bank)
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
    const verticalCSS = `
            [class*="row___"], [class*="stockHeader___"] {
                gap: 0 !important;
            }
            [class*="row___"] > div, [class*="stockHeader___"] > div {
                padding-left: 2px !important;
                padding-right: 2px !important;
                margin: 0 !important; 
            }
            [class*="stockHeader___"] > div:nth-child(3),
            [class*="row___"] > div:nth-child(3) {
                display: none !important;
            }
            [class*="stockHeader___"] > div:nth-child(4),
            [class*="row___"] > div:nth-child(4),
            [class*="stockHeader___"] > div:nth-child(5),
            [class*="row___"] > div:nth-child(5) {
                flex: 0 0 auto !important;
                width: auto !important;
                min-width: 0 !important;
                max-width: none !important;
            }
            [class*="itemName___"] {
                flex: 1 1 auto !important;
                min-width: 40px !important;
                overflow: hidden !important;
            }
            [class*="itemName___"] button {
                white-space: nowrap !important;
                overflow: hidden !important;
                text-overflow: ellipsis !important;
                max-width: 100% !important;
                display: block !important;
            }
            [class*="buyCell___"] {
                flex: 0 0 auto !important;
                width: auto !important;
                max-width: none !important;
            }
    `;
    
    // HORIZONTAL CSS
    const horizontalCSS = `
            /* Hide Type Column via CSS if possible */
            /* We will also try JS hiding */
            [class*="itemsHeader___"] > div:nth-child(3) {
                display: none !important;
            }
            li > div[class*="row___"] > div:nth-child(3) {
                display: none !important;
            }
            
            /* Ensure buy column has enough space */
            [class*="tabletColE___"] {
                min-width: 100px !important;
                overflow: visible !important;
            }
    `;

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
                        const match = stockText.match(/([\\d,]+)/);
                        if (match) {
                            stock = parseInt(match[1].replace(/,/g, ''));
                        }
                    } else {
                        // Fallback: Look for "Stock" text
                         const all = li.querySelectorAll('*');
                        for (let el of all) {
                            if (el.textContent.toLowerCase().includes('stock')) {
                                const match = el.textContent.match(/([\\d,]+)/);
                                if (match) {
                                    stock = parseInt(match[1].replace(/,/g, ''));
                                    break;
                                }
                            }
                        }
                    }
                }
                
                // 3. Capacity
                const msgEl = document.querySelector('.messageContent___LhCmx');
                if (msgEl) {
                    const match = msgEl.textContent.match(/purchased\\s*(\\d+)\\s*\\/\\s*(\\d+)/);
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
                        const match = inlineStock.textContent.match(/x([\\d,]+)/);
                        if (match) {
                            stock = parseInt(match[1].replace(/,/g, ''));
                        }
                    }
                    
                    if (stock === 0) {
                        const cells = li.querySelectorAll('div[class*="cell___"]');
                        for (const cell of cells) {
                            const txt = cell.textContent.toLowerCase();
                            if (txt.includes('stock')) {
                                const match = cell.textContent.match(/stock\\s*([\\d,]+)/i) || cell.textContent.match(/([\\d,]+)/);
                                if (match) {
                                    stock = parseInt(match[1].replace(/,/g, ''));
                                }
                            }
                        }
                    }
                }
                
                const itemsBar = document.querySelector('[class*="items-"]');
                if (itemsBar) {
                    const capMatch = itemsBar.textContent.match(/(\\d+)\\s*\\/\\s*(\\d+)/);
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
  const observer = new MutationObserver((mutations) => {
    addFillMaxButtons();
  });
  observer.observe(document.body, { childList: true, subtree: true });
  ''';
}

String travelRemovePlaneJS() {
  return '''
    var style = document.createElement('style');
    style.type = 'text/css';
    style.innerHTML = `
        .travel-agency-travelling .stage, 
        .travel-agency-travelling .popup-info, 
        [class^="airspaceScene___"][class*="outboundFlight___"], 
        [class^="airspaceScene___"][class*="returnFlight___"], 
        [class^="randomFact___"], 
        [class^="randomFactWrapper___"],
        [class^="delimiter-"] { 
            display: none !important; 
        }
    `;
    document.head.appendChild(style);
            
    // Return to avoid iOS WKErrorDomain
    123;
  ''';
}

String travelReturnHomeJS() {
  return '''
    function goHome() {
      const doc = document;
      let travelHome = doc.querySelector('.travel-home-header-button');
      
      if (travelHome) {
          travelHome.click();
          setTimeout(function() {
              let confirmBtn = doc.querySelector('#travel-home-panel button.torn-btn');
              if (confirmBtn) {
                  confirmBtn.click();
              }
          }, 1000);
      }
    }

    goHome();
    
    // Return to avoid iOS WKErrorDomain
    123;
  ''';
}

String highlightCityItemsJS() {
  return '''
    function addStyle(styleString) {
        const style = document.createElement('style');
        style.textContent = styleString;
        document.head.append(style);
    }
      
    addStyle(`
      .pdaCityItem {
        box-sizing: border-box;
        box-shadow: rgb(195 20 20 / 0%) 0px 0px 20px 10px;
        display: block !important;
        width: 40px !important;
        height: 40px !important;
        left: -20px !important;
        top: -20px !important;
        z-index: 999 !important;
        padding: 10px 0px;
        border-width: medium;
        border-style: dashed;
        border-color: rgb(1 7 255);
        border-image: initial;
        border-radius: 100%;
        background: rgb(206 202 184 / 77%);
        transition: width 50ms cubic-bezier(0.65, 0.05, 0.36, 1), height 50ms cubic-bezier(0.65, 0.05, 0.36, 1), left 50ms cubic-bezier(0.65, 0.05, 0.36, 1), top 50ms cubic-bezier(0.65, 0.05, 0.36, 1), padding 50ms cubic-bezier(0.65, 0.05, 0.36, 1), background 50ms 0ms;
        animation: svelte-1dz9z41-fade-in 500ms ease-out backwards;
      }
    `);
      
    function highlightItems() {
      // Find items
      for(let el of document.querySelectorAll("#map .leaflet-marker-pane *")){
        let src = el.getAttribute("src");
        if(src.indexOf("/images/items/") > -1){
          el.classList.add("pdaCityItem");
        }
      }
    }
    
    itemsLoaded().then(() => {
      highlightItems();
    });
    
    function itemsLoaded() {
      return new Promise((resolve) => {
        let checker = setInterval(() => {
          if (document.querySelector("#map .leaflet-marker-pane *")) {
          setInterval(() => {
            resolve(true);
          }, 300);
          return clearInterval(checker);
          }
        });
      });
    } 
    
    // Return to avoid iOS WKErrorDomain
    123;
  ''';
}

String addOwnBazaarFillButtonsJS() {
  return '''
    // ADD
    var doc = document;
    var bazaar = doc.querySelectorAll(".clearfix.no-mods");
    
    function dispatchClick(element, newValue) {
      let input = element; 
      let lastValue = input.value;
      input.value = newValue;
      let event = new Event('input', { bubbles: true });
      // hack React15 (Torn seems to be using React 16)
      event.simulated = true;
      // hack React16 (This is what Torn uses)
      let tracker = input._valueTracker;
      if (tracker) {
        tracker.setValue(lastValue);
      }
      input.dispatchEvent(event);
    }
    
    var needToAdd = true;
    for(let item of bazaar) {
      let fill = item.querySelector(".torn-btn");
      
      // Are the buttons already active?
      if (fill != null) {
        needToAdd = false;
      }	
    } 
    
    if (needToAdd) {
      for(let item of bazaar){
        let qtyBox = item.querySelector(".amount .clear-all");
        
        let fillButton = doc.createElement('a');
        fillButton.innerHTML = '<button class="torn-btn">FILL</button>';
        qtyBox.parentElement.appendChild(fillButton);
  
        fillButton.addEventListener("click", function(event){
          event.stopPropagation();
          
          var inventoryQuantity;
          var tryFindItemNumber = fillButton.parentElement.parentElement.parentElement.parentElement.querySelector(".t-show");
          if (tryFindItemNumber != null) {
            inventoryQuantity = tryFindItemNumber.innerText.replace(/,/g, "").replace("x", "");
          } else {
            inventoryQuantity = 1;
          }
          
          dispatchClick(qtyBox, inventoryQuantity); 
        });
      }
    }
    
    // Return to avoid iOS WKErrorDomain
    123;
  ''';
}

String removeOwnBazaarFillButtonsJS() {
  return '''
    var doc = document;
    var bazaar = doc.querySelectorAll(".clearfix.no-mods");

    for(let item of bazaar){
      let fill = item.querySelector(".torn-btn");
      if (fill != null) {
        fill.remove();
      }
    }
    
    // Return to avoid iOS WKErrorDomain
    123;
  ''';
}

String addOthersBazaarFillButtonsJS() {
  return r'''
    (async function() {  
        if (window.bazaarMaxScriptActive) return;
        window.bazaarMaxScriptActive = true;

        var doc = document;
        if (!window.location.href.includes('bazaar.php')) return;

        // Absolute positioning
        const style = doc.createElement('style');
        style.textContent = `
            .max-buy {
                border: 1px solid #ff8000 !important;
                background: transparent !important;
                color: #ff8000 !important;
                border-radius: 10px !important;
                position: absolute !important;
                height: 15px;
                width: 32px;
                text-align: center;
                line-height: 13px;
                bottom: 3px; 
                left: 50%;
                transform: translateX(-50%);
                font-size: 9px;
                cursor: pointer;
                z-index: 999;
                font-weight: bold;
                box-sizing: border-box;
                text-decoration: none !important;
            }
            /* Ensure the container has space and relative positioning */
            button[class*="buy___"], button[class*="activate-buy-button"] {
                padding-bottom: 20px !important;
                position: relative !important;
            }
            /* Wide popups container */
            div[class*="field___"] {
                position: relative !important;
                overflow: visible !important;
            }
        `;
        doc.head.append(style);

        function dispatchClick(input, newValue) {
            let lastValue = input.value;
            input.value = newValue;
            let event = new Event('input', { bubbles: true });
            let tracker = input._valueTracker;
            if (tracker) tracker.setValue(lastValue);
            input.dispatchEvent(event);
        }

        function handleMaxClick(item_box) {
            let amountEl = item_box.querySelector("[class*='amountValue_'], [class*='amount___']");
            let priceEl = item_box.querySelector("[class*='price___']");
            let moneyEl = doc.querySelector("#user-money");
            
            if (!amountEl || !priceEl || !moneyEl) return;

            let max = parseInt(amountEl.innerText.replace(/\D/g, ""));
            let price = parseInt(priceEl.innerText.replace(/[,$]/g, ""));
            let user_money = parseInt(moneyEl.getAttribute("data-money") || moneyEl.innerText.replace(/\D/g, ""));
            
            let affordable = Math.floor(user_money / price);
            if (affordable < max) max = affordable;
            if (max > 10000) max = 10000;

            let input = item_box.querySelector("input[class*='buyAmountInput_']");
            if (input) {
                dispatchClick(input, max);
            } else {
                // If input is not present (wide mode), click shopping cart first
                let buyBtn = item_box.querySelector("button[aria-label*='Buy'], [class*='activate-buy-button']");
                if (buyBtn) {
                    buyBtn.click();
                    setTimeout(() => {
                        let retry = item_box.querySelector("input[class*='buyAmountInput_']");
                        if (retry) dispatchClick(retry, max);
                    }, 50);
                }
            }
        }

        // Injection
        function fastInject(node) {
            if (!node || node.nodeType !== 1) return;

            // Search for both button types (narrow and wide)
            let buyButtons = node.querySelectorAll("button[class*='buy___'], button[class*='activate-buy-button']");
            
            buyButtons.forEach(buyBtn => {
                if (!buyBtn.parentElement.querySelector(".max-buy")) {
                    let maxBtn = doc.createElement('a');
                    maxBtn.className = 'max-buy';
                    maxBtn.innerText = 'MAX';
                    
                    buyBtn.parentElement.style.position = "relative";
                    buyBtn.parentElement.appendChild(maxBtn);

                    maxBtn.addEventListener("click", (e) => {
                        e.stopPropagation();
                        e.preventDefault();
                        let itemContainer = buyBtn.closest("[class*='item___'], [class*='rowItems_']");
                        handleMaxClick(itemContainer);
                    });
                }
            });
        }

        // Observer to re-scan added fragments
        const observer = new MutationObserver((mutations) => {
            for (let i = 0; i < mutations.length; i++) {
                mutations[i].addedNodes.forEach(node => {
                    if (node.nodeType === 1) {
                        fastInject(node);
                        // Also scan sub-elements of the added node
                        if (node.children && node.children.length > 0) {
                            fastInject(node);
                        }
                    }
                });
            }
        });

        observer.observe(doc.body, { childList: true, subtree: true });

        const urlHeartbeat = setInterval(() => {
            if (!window.location.href.includes('bazaar.php?userId=')) {
                observer.disconnect();
                clearInterval(urlHeartbeat);
                window.bazaarMaxScriptActive = false;
                doc.querySelectorAll(".max-buy").forEach(el => el.remove());
            }
        }, 1000);

        // Init
        fastInject(doc.body);
        
        123;
    })();
  ''';
}

String addHeightForPullToRefresh() {
  return '''
    (function() {
      // Get the height of the viewport
      var viewportHeight = Math.max(document.documentElement.clientHeight || 0, window.innerHeight || 0);

      // Check if the website content overflows the viewport
      if (document.documentElement.clientHeight >= document.documentElement.scrollHeight) {
        // If not, add 10px to the body height
        //console.log("Adding extra height for pull-to-refresh");
        document.body.style.height = `\${viewportHeight + 20}px`;
      }
    })();
  ''';
}

String removeChatJS() {
  return '''
    try {
      function hideElement(el) {
        el.style.setProperty("display", "none", "important");
      }
      
      // Select all chat elements (both the old one and the new one... just in case)
      var chatBoxes = document.querySelectorAll("[class*='chat-app-container_'], #chatRoot");
      chatBoxes.forEach(function(el) {
        hideElement(el);
      });
    } catch (e) {
      //console.error("Error hiding chat elements: ", e);
    }
    
    // Return a value to avoid iOS WKErrorDomain errors
    123;
  ''';
}

String restoreChatJS() {
  return '''
    try {
      // Select all chat elements (both the old one and the new one)
      var chatBoxes = document.querySelectorAll("[class*='chat-app-container_'], #chatRoot");
      chatBoxes.forEach(function(el) {
        el.style.removeProperty("display");
      });
    } catch (e) {
      //console.error("Error restoring chat elements: ", e);
    }
    
    // Return a value to avoid iOS WKErrorDomain errors
    123;
  ''';
}

String quickItemsJS({required String item, bool faction = false, bool? eRefill = false, bool? nRefill = false}) {
  const String timeRegex =
      r'/<span class="counter-wrap[\s=\-"a-zA-Z0-9]*data-time="[0-9]+"[\s=\-"a-zA-Z0-9]*>[0-9:]*<\/span>/g';

  return '''
    // Credit Torn Tools
    
    // Fixed time string for faction armoury replies
    function fixTime(str) {
      let regexp = $timeRegex
      let matches = str.match(regexp);

      if (matches == null || Object.keys(matches).length === 0) {
        //console.log("null");
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
        //console.log("M: " + m);
        let regTime = /data-time="([0-9:]+)"/
        let timeMatch = m.match(regTime);
        final = final.replace(m, secondsToHms(timeMatch[1]));
      }
      return final;
    }

    // Add style for result box
    function addStyle(styleString) {
      const style = document.createElement('style');
      style.textContent = styleString;
      document.head.append(style);
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
      `);
    }
    
    // If there any boxes remaining (from previous calls, remove them)
    for (let box of document.querySelectorAll('.resultBox')) {
      box.remove();
    }
 
    // From TornTools by Mephiles
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
    
    var url = "";
    if (!$eRefill && !$nRefill) {
      url = "https://www.torn.com/" + addRFC("item.php");
    } else {
      url = "https://www.torn.com/" + addRFC("factions.php");
    }
    

    if (!$faction) {
      ajaxWrapper({
        url: url,
        type: 'POST',
        data: 'step=actionForm&id=$item&action=use',
        oncomplete: function(resp) {
          var response = resp.responseText;
          var topBox = document.querySelector('.content-title');
          topBox.insertAdjacentHTML('afterend', '<div class="resultBox">2</div>');
          resultBox = document.querySelector('.resultBox');
          resultBox.style.display = "block";
          resultBox.innerHTML = response;
          resultBox.querySelector(`a[data-item='$item`).click();
        },
        onerror: function(e) {
          console.error(e)
        }
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
          onerror: function(e) {
            console.error(e)
          }
        });
      } else {
        let step = $eRefill ? "step=armouryRefillEnergy" : "step=armouryRefillNerve";

        ajaxWrapper({
          url: url,
          type: 'POST',
          data: step,
          oncomplete: function(resp) {
            //console.log(resp.responseText);
            
            var response = JSON.parse(resp.responseText);
            var topBox = document.querySelector('.content-title');
            topBox.insertAdjacentHTML('afterend', '<div class="resultBox">2</div>');
            resultBox = document.querySelector('.resultBox');
            resultBox.style.display = "block";
            if (response.success === false) {
              resultBox.innerHTML = response.message;
            } else {
              resultBox.innerHTML = response.message;
            }
          },
          onerror: function(e) {
            console.error(e)
          }
        });
      }
    }
    
    
    // Get rid of the resultBox on close
    document.addEventListener("click", (event) => {
      if (event.target.classList.contains("close-act") && event.target.parentElement.parentElement.parentElement.parentElement.classList.contains("resultBox")) {
        document.querySelector(".resultBox").style.display = "none";
      }
    });
    
    // To prevent several boxes appearing if users spam click, we will 
    // wait a few seconds and then remove all except for the very first (most 
    // recent item)
    function sleep(ms) {
      return new Promise(resolve => setTimeout(resolve, ms));
    }
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
      },
      onerror: function(e) {
        console.error(e)
      }
    });

    // Return to avoid iOS WKErrorDomain
    123;
  ''';
}

String chatHighlightJS({required String highlights}) {
  return '''
// Modified from TornTools' Highlight Chat feature
(() => {
  "use strict";
	const highlights = $highlights;
	async function waitForChat() {
		let count = 0;
		return new Promise((res, rej) => {
			const id = setInterval(() => {
				const chat = document.querySelector("#chatRoot");
				if (chat?.querySelector("[class*='chat-list-button__']")) {
					clearInterval(id);
					res(chat);
				} else if (count > 20) {
					clearInterval(id);
					rej();
				} else count++;
			}, 500)
		});
	}

	function removeHighlights() {
		[...document.querySelectorAll(".pda-chat-highlight, .pda-chat-outline")].forEach((el) => el.classList.remove("pda-chat-highlight", "pda-chat-outline"));
	}
	function applyHighlights(el) {
		// Spread content, in case the msg content has a : in it.
		const [sender, ...contentArr] = el.firstElementChild.tagName === "DIV" ? el.lastChild.textContent.split(":") : el.textContent.split(":");
		const content = contentArr.join(":");
		// Make it easy to silent the errors, so if (when...) something breaks it doesn't spam the console.
		if (!sender && !window.pda?.silenceChatErrors) console.error("Missing sender in message element.")
		if (!content && !window.pda?.silenceChatErrors) console.error("Missing content in message element.");
		if (sender && sender.toLowerCase() === highlights[0].toLowerCase()) el.classList.add("pda-chat-outline");
		if (content && highlights.some((highlight) => content.toLowerCase().includes(highlight.toLowerCase()))) el.classList.add("pda-chat-highlight");
	}

	waitForChat().then((chat) => {
		removeHighlights();
	
		[...chat.querySelectorAll("[class*='chat-box-body__'] [class*='chat-box-message__box__']")].forEach(applyHighlights);
		new MutationObserver((muts) => {
			for (const mut of muts) {
				for (const node of mut.addedNodes) {
					if (node instanceof HTMLElement && !node.className && node.parentElement?.className.includes("chat-box-body__")) {
						applyHighlights(node);
					}
				}
			}
		}).observe(chat, { childList: true, subtree: true })
	});
})();
  ''';
}

String chatHighlightCSS({required String background, required String senderColor}) {
  // Yes the css is incredibly hacky, it's the only way to workaround Torn's inconsistent chat elements without
  // using :has() or adding more complex JS. It works, so it works.
  return """
  .pda-chat-highlight [class*=chat-box-message__box_][class*=chat-box-message__box--],
  .pda-chat-highlight[class*=chat-box-message__box_][class*=chat-box-message__box--] {
    background-color: $background;
  }

  .pda-chat-outline [class*=chat-box-message__box_][class*=chat-box-message__box--],
  .pda-chat-outline[class*=chat-box-message__box_][class*=chat-box-message__box--] {
    box-shadow: 0 0 0 1px $senderColor;
  }
  """;
}

String jailJS({
  required bool? filtersEnabled,
  required int? levelMin,
  required int? levelMax,
  required int? timeMin,
  required int? timeMax,
  required int? scoreMin,
  required int? scoreMax,
  required bool? bailTicked,
  required bool? bustTicked,
  required bool? excludeSelf,
  required String? excludeName,
}) {
  return '''
    // Credit to TornTools for implementation logic
    var doc = window.document;

    function toSeconds(time) {
      time = time.toLowerCase();
      let seconds = 0;
      if (time.includes("h")) {
        seconds += parseInt(time.split("h")[0].trim()) * 3600;
        time = time.split("h")[1];
      }
      if (time.includes("m")) {
        seconds += parseInt(time.split("m")[0].trim()) * 60;
        time = time.split("m")[1];
      }
      if (time.includes("s")) {
        seconds += parseInt(time.split("s")[0].trim());
      }
      return seconds;
    }

    // Finds parents (credit: Torn Tools)
    function hasParent(element, attributes = {}) {
      if (!element.parentElement) return false;
      if (attributes.class && element.parentElement.classList.contains(attributes.class)) return true;
      if (attributes.id && element.parentElement.id === attributes.id) return true;
      return hasParent(element.parentElement, attributes);
    }

    function modifyJail() {
      // Adjust elements depending on current theme
      var darkModeFound = doc.querySelectorAll('#body.dark-mode');
      var activeFilter = "brightness(0.5)";
      var defaultFilter = "drop-shadow(0 1px 0 #fff)";
      if (darkModeFound.length > 0) {
        activeFilter = "brightness(1)";
        defaultFilter = "drop-shadow(0px 1px 0px transparent)";
      }

      // FILTERS
      for (var player of doc.querySelectorAll(".users-list > li")) {

        
        var shouldHide = false;

        var level = player.querySelector(".level").innerText.replace("Level", "").replace("LEVEL", "").replace(":", "").trim();
        if (level > $levelMax || level < $levelMin) {
          shouldHide = true;
        }

        // Time
        var seconds = toSeconds(player.querySelector(".time").innerText.replace("Time", "").replace("TIME", "").replace(":", "").replace("left:", "").trim());
        var hours = seconds / 3600;
        if (hours > $timeMax || hours < $timeMin) {
          shouldHide = true;
        }

        // Score
        var score = level * seconds / 60
        if (score > $scoreMax || score < $scoreMin) {
          shouldHide = true;
        }
        
        // Exclude own player
        var name = player.querySelector(".user.name").innerText;
        if ($excludeSelf && name.toUpperCase() === "$excludeName" && shouldHide) {
          shouldHide = false;
        }
                
        if (shouldHide && $filtersEnabled) {
          //player.hidden = true; // Not allowed with new user agent on iOS
          player.style.display = "none"; 
        } else if (!shouldHide || !$filtersEnabled) {
          //player.hidden = false; // Not allowed with new user agent on iOS
          player.style.display = ""; 
        }

      }

      // BAIL
      if ($bailTicked) {
        for (var player of doc.querySelectorAll(".users-list > li")) {
          // Find bust fields and turn them green
          const actionWrap = player.querySelector(".buy, .bye");
          actionWrap.style.backgroundColor = "#288a0059";
          // Find bust icons and decrease brightness for better contrast
          const actionIcon = player.querySelector(".bye-icon");
          filterDefault = actionIcon.style.filter;
          actionIcon.style.filter = activeFilter;
          // By adding a "1" to the button link, we perform a quick bust
          let bailLink = actionWrap.getAttribute("href");
          if (bailLink[bailLink.length - 1] !== "1") bailLink += "1";
          actionWrap.setAttribute("href", bailLink);
        }
      }
      else if (!$bailTicked) {
        bailActive = false;
        for (var player of doc.querySelectorAll(".users-list > li")) {
          const actionWrap = player.querySelector(".buy, .bye");
          actionWrap.style.removeProperty("background-color");
          const actionIcon = player.querySelector(".bye-icon");
          actionIcon.style.filter = defaultFilter;
          let bailLink = actionWrap.getAttribute("href");
          if (bailLink[bailLink.length - 1] === "1") {
            bailLink = bailLink.substring(0, bailLink.length - 1);
          }
          actionWrap.setAttribute("href", bailLink);
        }
      }

      // BUST
      if ($bustTicked) {
        bustActive = true;
        for (var player of doc.querySelectorAll(".users-list > li")) {
          // Find bust fields and turn them green
          const actionWrap = player.querySelector(".bust");
          actionWrap.style.backgroundColor = "#288a0059";
          // Find bust icons and decrease brightness for better contrast
          const actionIcon = player.querySelector(".bust-icon");
          filterDefault = actionIcon.style.filter;
          actionIcon.style.filter = activeFilter;
          // By adding a "1" to the button link, we perform a quick bust
          let bustLink = actionWrap.getAttribute("href");
          if (bustLink[bustLink.length - 1] !== "1") bustLink += "1";
          actionWrap.setAttribute("href", bustLink);
        }
      }
      else if (!$bustTicked) {
        bustActive = false;
        for (var player of doc.querySelectorAll(".users-list > li")) {
          const actionWrap = player.querySelector(".bust");
          actionWrap.style.removeProperty("background-color");
          const actionIcon = player.querySelector(".bust-icon");
          actionIcon.style.filter = defaultFilter;
          let bustLink = actionWrap.getAttribute("href");
          if (bustLink[bustLink.length - 1] === "1") {
            bustLink = bustLink.substring(0, bustLink.length - 1);
          }
          actionWrap.setAttribute("href", bustLink);
        }
      }
    }

    // Sleep and wait for elements to load
    async function sleep(ms) {
      return new Promise(resolve => setTimeout(resolve, ms));
    }

    async function waitForElementsAndRun() {
      // CAUTION: returning 1 when still no users loaded
      if (doc.querySelectorAll(".users-list > li").length <= 1) {
        console.log("Waiting for jail (short)");
        await sleep(300);
        if (doc.querySelectorAll(".users-list > li").length <= 1) {
          console.log("Waiting for jail (long)");
          await sleep(1000);
        }
      } 

      modifyJail();
    }
    
    waitForElementsAndRun();


    // Listener for page change
    var intervalRepetitions = 0;
    var listener = function (event) {
      if (event.target.classList && !event.target.classList.contains("gallery-wrapper")
          && hasParent(event.target, { class: "gallery-wrapper" })) {
        return new Promise((resolve) => {
          let checker = setInterval(() => {
            if (doc.querySelector(".users-list > li")) {
              modifyJail();
              return clearInterval(checker);
            }
            if (++intervalRepetitions === 20) {
              return clearInterval(checker);
            }
          }, 300);
        });
      }
    }

    // Save variable in a persistent object so that we only add the listener once
    // event if we fire the script several times (removing the listener won't work)
    var savedFound = doc.querySelector(".pdaListener") !== null;
    if (!savedFound) {
      var save = doc.querySelector(".content-wrapper");
      save.classList.add("pdaListener");
      doc.addEventListener("click", listener, true);
    }

    // Return to avoid iOS WKErrorDomain
    123;
  ''';
}

// Not required any longer with inAppWebView PR #1042
// (otherwise, two tabs will open)
String miniProfiles() {
  return '''
    \$(document).on("click","[class*=profile-mini-_userWrap]", async function(e){
        window.flutter_inappwebview.callHandler('handlerMiniProfiles', e.target.href);
    });

    \$(document).on("click","[class*=profile-mini-_factionWrap]",function(e){
        window.flutter_inappwebview.callHandler('handlerMiniProfiles', e.target.href);
    });

    // Return to avoid iOS WKErrorDomain
    123;
  ''';
}

String bountiesJS({
  required int? levelMax,
  required bool? removeNotAvailable,
}) {
  return '''
    // Credit to TornTools for implementation logic
    var doc = window.document;

    // Finds parents (credit: Torn Tools)
    function hasParent(element, attributes = {}) {
      if (!element.parentElement) return false;
      if (attributes.class && element.parentElement.classList.contains(attributes.class)) return true;
      if (attributes.id && element.parentElement.id === attributes.id) return true;
      return hasParent(element.parentElement, attributes);
    }

    function modifyBounties() {
      // FILTERS
      for (var player of doc.querySelectorAll(".bounties-list > li:not(.clear)")) {
        var shouldHide = false;

        var level = player.querySelector(".level").innerText.replace("Level", "").replace("LEVEL", "").replace(":", "").trim();
        if (level > $levelMax) {
          shouldHide = true;
        }
        
        var foundNotAvail = player.querySelector(".user-red-status, .user-blue-status");
        if ($removeNotAvailable && foundNotAvail) {
          shouldHide = true;
        }
        
        // Hide users
        if (shouldHide) {
          player.hidden = true;
        } else {
          player.hidden = false;
        }
      }
    }

    modifyBounties();

    // Listener for page change
    var intervalRepetitions = 0;
    var listener = function (event) {
      if (event.target.classList && !event.target.classList.contains("gallery-wrapper")
        && hasParent(event.target, { class: "gallery-wrapper" })) {
      return new Promise((resolve) => {
        let checker = setInterval(() => {
        if (doc.querySelector(".bounties-list > li")) {
          modifyBounties();
          return clearInterval(checker);
        }
        if (++intervalRepetitions === 20) {
          return clearInterval(checker);
        }
        }, 300);
      });
      }
    }

    // Save variable in a persistent object so that we only add the listener once
    // event if we fire the script several times (removing the listener won't work)
    var savedFound = doc.querySelector(".pdaListener") !== null;
    if (!savedFound) {
      var save = doc.querySelector(".content-wrapper");
      save.classList.add("pdaListener");
      doc.addEventListener("click", listener, true);
    }

    // Return to avoid iOS WKErrorDomain
    123;
  ''';
}

String ocNNB({required String members, required int playerID}) {
  return '''
((members, playerID) => {
		const waitForOCs = (maxCount = 100) =>
			new Promise((resolve, reject) => {
				const intID = setInterval(() => {
					const ocRows = \$("ul.crimes-list > li");
					if (ocRows.length) {
						clearInterval(intID);
						resolve(ocRows);
					} else {
						if (maxCount-- <= 0) {
							clearInterval(intID);
							reject(new Error("Could not find member rows"));
						}
					}
				}, 100);
			});

		const handleOCRows = (ocRows) => {
			ocRows.each((_, row) => {
				const table = \$(row).find(
					".details-wrap:not(.pda-modified), .plans-wrap:not(.pda-modified)"
				);
				if (!table.length) return; // No new table to update
				if (row.closest(".organize-wrap")) {
					const shouldHighlightRow = handleOCTable(table);
					if (shouldHighlightRow)
						\$(row).find("> ul.item").addClass("pda-highlight-row");
				} else {
					handleOCPlanningTable(table);
				}
			});
		};

		const handleOCTable = (table) => {
			// add .stat to the new Li element to match the status styling at the end of the row
			let shouldHighlightRow = false;
			table.addClass("pda-modified");
			table.find("> ul > li > ul:not(.pda-table-row)").each((i, row) => {
				\$(row).addClass("pda-table-row");
				if (i === 0)
					return \$("<li/>", { text: "NNB", class: "stat" }).insertBefore(
						\$(row).find("li.stat")
					);
				const id = \$(row)
					.find("a[href*='profiles.php?XID=']")
					.attr("href")
					?.match(/XID=(\\d+)/)?.[1];
				if (!id) return console.error("Missing ID for row", row);
				if (id === playerID.toString()) shouldHighlightRow = true;

				\$("<li/>", {
					text: members[id] || "unk",
					class: "stat",
				}).insertBefore(\$(row).find("li.stat"));
			});
			return shouldHighlightRow;
		};

		const handleOCPlanningTable = (table) => {
			table.addClass("pda-modified");
			table.find("div.plans-list > ul, ul.plans-list > li").each((i, row) => {
				\$(row).addClass("pda-table-row-planning");
				if (i === 0)
					return \$("<li/>", { text: "NNB", class: "pda-nnb-planning" }).insertBefore(
						\$(row).find("li.act")
					);
				const id = \$(row)
					.find("a[href*='profiles.php?XID=']")
					.attr("href")
					?.match(/XID=(\\d+)/)?.[1];
				if (!id) return console.error("Missing ID for row", row);
				\$("<li/>", {
					text: members[id] || "unk",
					class: "pda-nnb-planning",
				}).insertBefore(\$(row).find("li.act"));
			});
		};

		const addStyles = () => {
			const styles = `
								.pda-highlight-row {
					background-color: #F0F7 !important;
				}    		
				/* Absolute values are modified from Torn's css, don't blame me */
				.pda-table-row > li.level {
					width: 208px !important;
				}
				.pda-table-row-planning .member {
					width: 230px !important;
				}
				.pda-table-row-planning .pda-nnb-planning {
					width: 30px !important;
				}
				
				@media screen and (max-width: 784px) {
					.pda-table-row > li.member {
						width: 157px !important;
					}
					.pda-table-row > li.level {
						width: 42px !important;
					}
					.pda-table-row-planning .member {
						width: 99px !important;
					}
					.pda-table-row-planning .offences, .pda-table-row-planning .offenses {
						width: 96px !important;
					}
				}
				
				@media screen and (max-width: 386px) {
					.pda-table-row > li.member {
						width: 91px !important;
					}
					.pda-table-row-planning .pda-nnb-planning {
						display: none !important; /* Hide NNB column, screen is too thin */
					}
					.pda-table-row-planning .member {
						width: 119px !important; /* reset */
					}
					.pda-table-row-planning .offences, .pda-table-row-planning .offenses {
						width: 60px !important; /* reset */
					}
				}
				`;
			\$("<style/>", { text: styles }).appendTo("head");
		};
		addStyles();
		waitForOCs().then(handleOCRows).catch(console.trace);
	})($members, $playerID);
  ''';
}

/// As of iOS 18...
/// iOS does not handle 'dblclick' events reliably, so we implement a custom double-click detection
String barsDoubleClickRedirect({bool isIOS = false}) {
  return '''
    (function() {
      function addBarsListener() {
        function onEnergyClick() {
          window.location.href = "https://www.torn.com/gym.php";
        }

        function onNerveClick() {
          window.location.href = "https://www.torn.com/crimes.php";
        }

        var savedFound = document.querySelector(".pdaListenerBarsDoubleClick") !== null;

        // Get all bar elements
        let barElements = Array.from(document.querySelectorAll('[class^="bar___"]'));

        // Find the energy bar element
        let energyBar = barElements.find(el =>
          el.className.includes('energy___') && el.className.includes('bar-')
        );

        // Find the nerve bar element
        let nerveBar = barElements.find(el =>
          el.className.includes('nerve___') && el.className.includes('bar-')
        );

        if (!savedFound && energyBar !== null && nerveBar !== null) {
          var save = document.querySelector(".content-wrapper");
          save.classList.add("pdaListenerBarsDoubleClick");

          if ($isIOS) {
            let energyClickCount = 0;
            let nerveClickCount = 0;

            // Set time interval in milliseconds for detecting double click
            const doubleClickInterval = 1500;

            energyBar.addEventListener('click', () => {
              energyClickCount++;

              if (energyClickCount === 1) {
                setTimeout(() => {
                  if (energyClickCount >= 2) {
                    onEnergyClick();
                  }
                  energyClickCount = 0; // Reset click count
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
                  nerveClickCount = 0; // Reset click count
                }, doubleClickInterval);
              }
            });
          } else {
            energyBar.addEventListener('dblclick', onEnergyClick);
            nerveBar.addEventListener('dblclick', onNerveClick);
          }
        }
      }

      let pass = 0;
      let waitForBarsAndRun = setInterval(() => {
        if (document.querySelector('[class^="bar___"]')) {
          addBarsListener();
          return clearInterval(waitForBarsAndRun);
        } else {
          pass++;
        }

        // End the interval after a few unsuccessful seconds
        if (pass > 20) {
          return clearInterval(waitForBarsAndRun);
        }

      }, 300);
    })();
  ''';
}

/// Exit fullscreen on double click on header banner
String exitFullScreenOnHeaderDoubleClick({bool isIOS = false}) {
  return '''
    (function() {
      // Use a more robust check to prevent multiple executions
      if (window.pdaHeaderListenerAdded) {
        return;
      }
      
      function addHeaderListener() {
        function onHeaderDoubleClick() {
          if (window.flutter_inappwebview && window.flutter_inappwebview.callHandler) {
            window.flutter_inappwebview.callHandler('tornPDAExitFullScreen', 'exit');
          }
        }
        
        // Get the header banner element
        let headerElement = document.querySelector('#topHeaderBanner > div.header-wrapper-top');

        if (headerElement !== null) {
          // Mark that we've added the listener
          window.pdaHeaderListenerAdded = true;

          if ($isIOS) {
            let headerClickCount = 0;
            let headerClickTimeout = null;

            // Set time interval in milliseconds for detecting double click
            const doubleClickInterval = 1500;

            headerElement.addEventListener('click', () => {
              headerClickCount++;

              if (headerClickCount === 1) {
                headerClickTimeout = setTimeout(() => {
                  headerClickCount = 0; // Reset click count after timeout
                }, doubleClickInterval);
              } else if (headerClickCount >= 2) {
                // Clear the timeout since we got the second click
                if (headerClickTimeout) {
                  clearTimeout(headerClickTimeout);
                  headerClickTimeout = null;
                }
                headerClickCount = 0; // Reset immediately
                onHeaderDoubleClick();
              }
            });
          } else {
            headerElement.addEventListener('dblclick', () => {
              onHeaderDoubleClick();
            });
          }
        }
      }

      let pass = 0;
      let waitForHeaderAndRun = setInterval(() => {
        if (document.querySelector('#topHeaderBanner > div.header-wrapper-top')) {
          addHeaderListener();
          return clearInterval(waitForHeaderAndRun);
        } else {
          pass++;
        }

        // End the interval after a few unsuccessful seconds
        if (pass > 20) {
          return clearInterval(waitForHeaderAndRun);
        }

      }, 300);
    })();
  ''';
}

String greasyForkMockVM(String scripts) {
  // Imitate ViolentMonkey on GreasyFork for identifying version numbers and removing the install warning
  return """
    ((PDA_script_list) => {
      window.external = {
        Violentmonkey: {
          getVersion: async () => null,
          isInstalled: async (name, _) => PDA_script_list.find(s => s.name === name)?.version,
        }
      };
    })($scripts);
  """;
}

String ageToWordsOnProfile() {
  return r"""
    (() => {
    	const waitForContainer = (maxCount = 100) =>
    		new Promise((resolve) => {
    			const intID = setInterval(() => {
    				const container = $("div.age");
    				if (container.length) {
    					clearInterval(intID);
    					resolve(container);
    				} else if (maxCount-- <= 0) {
    					clearInterval(intID);
    					resolve(null);
    				}
    			}, 100);
    		});
    
    	const modifyTextToAge = (container) => {
    		const ageString = generateAgeString(container);
    		container
    			.find("div.box-name")
    			.text(ageString)
    			.css("margin", "8px 0 0 0")
    			.appendTo(container);
    	};
    
    	const generateAgeString = (container) => {
    		const el = container.find("ul.box-value");
    		const age = parseInt(el.text());
    
    		const current = new Date();
    		const signup = new Date(current - age * 24 * 60 * 60 * 1000);
    		const diffDate = new Date(current - signup);
    		const years = diffDate.getUTCFullYear() - 1970,
    			months = diffDate.getUTCMonth(),
    			days = diffDate.getUTCDate() - 1;
    
    		// yes this is dirty, but not incorrect....
    		let ageString = `${days} days`;
    		if (months) ageString = `${months} months, ${ageString}`;
    		if (years) ageString = `${years} years, ${ageString}`;
    		return ageString;
    	};
    
    	waitForContainer().then(modifyTextToAge);
    })();
  """;
}
