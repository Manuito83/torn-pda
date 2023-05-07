// Flutter imports:
import 'package:flutter/material.dart';

String easyCrimesJS({
  @required String nerve,
  @required String crime,
  @required String doCrime,
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

String buyMaxAbroadJS() {
  return '''
    function addFillMaxButtons(){

      const doc = document;
      let market = doc.querySelector(".travel-agency-market");

      if(!market){
        return;
      }

      // Assess whether buy buttons are visible when page loads, in which
      // case screen is wide and perhaps we are on a tablet. Then, just
      // load the FILL button TornTools style (below the buy button).
      if(\$('.buy').is(":visible")){
        function addStyle(styleString) {
          const style = document.createElement('style');
          style.textContent = styleString;
          document.head.append(style);
        }

        addStyle(`
          .deal {
            position: relative;
          }
        `);

        addStyle(`
          .deal .buy {
            margin-top: -14px !important;
            line-height: 20px !important;
          }
        `);
        
        addStyle(`
          .max-buy {
            position: absolute;
            width: 36px;
            text-align: center;
            border-left: 2px solid #ccc;
            height: 14px;
            line-height: 13px;
            bottom: -15px;
            right: -1px;
            font-size: 10px;
          }
        `);
        
        for(let buy_btn of market.querySelectorAll(".buy")){
          let max_span = doc.createElement('span');
          max_span.innerHTML = '<a class="max-buy">FILL</a>';
          buy_btn.parentElement.appendChild(max_span);
          
          max_span.addEventListener("click", function(event){
          event.stopPropagation();
            let max = parseInt(buy_btn.parentElement.parentElement.querySelector(".stck-amount").innerText.replace(/,/g, ""));
            let price = parseInt(buy_btn.parentElement.parentElement.querySelector(".c-price").innerText.replace(/,/g, "").replace("\$",""));
            let user_money = doc.querySelector(".user-info .msg .bold:nth-of-type(2)").innerText.replace(/,/g, "").replace("\$","");
            let bought = parseInt(doc.querySelector(".user-info .msg .bold:nth-of-type(3)").innerText);
            let limit = parseInt(doc.querySelector(".user-info .msg .bold:nth-of-type(4)").innerText) - bought;
            
            let max_can_buy = Math.round(user_money / price);

            let current = max_span.innerHTML;
            if (current.includes('class="max-buy"')) {
              dispatchClick(buy_btn.parentElement.querySelector("input[name='amount']"), max_can_buy);
            }
        });
      }
      
      // If screen is narrow, load a MAX button in the expandable box
      } else {
        for(let buy_btn of market.querySelectorAll(".torn-btn")){
          let max_span = doc.createElement('a');
          max_span.innerHTML = '<button class="torn-btn">MAX</button>';
          buy_btn.parentElement.appendChild(max_span);
        
          max_span.addEventListener("click", function(event){
            event.stopPropagation();

            let max = parseInt(buy_btn.parentElement.parentElement.parentElement.parentElement.parentElement.parentElement.querySelector(".stck-amount").innerText.replace(/,/g, ""));
            let price = parseInt(buy_btn.parentElement.parentElement.parentElement.parentElement.parentElement.parentElement.querySelector(".c-price").innerText.replace(/,/g, "").replace("\$",""));
            let user_money = doc.querySelector(".user-info .msg .bold:nth-of-type(2)").innerText.replace(/,/g, "").replace("\$","");
            let bought = parseInt(doc.querySelector(".user-info .msg .bold:nth-of-type(3)").innerText);
            let limit = parseInt(doc.querySelector(".user-info .msg .bold:nth-of-type(4)").innerText) - bought;
            
			let max_can_buy = Math.round(user_money / price);
            
            let current = max_span.innerHTML;
            if (current.includes('class="torn-btn"') && current.includes('MAX')) {
              dispatchClick(buy_btn.parentElement.parentElement.parentElement.parentElement.querySelector("input[name='amount']"), max_can_buy);
            } 
          });
        }
      }
    }

    function dispatchClick(element, newValue) {
      let input = element; 
      let lastValue = input.value;
      input.value = newValue;
      // "input" is not working for foreign stock wide, instead use "blur"
      let event = new Event('blur', { bubbles: true });
      // hack React15 (Torn seems to be using React 16)
      event.simulated = true;
      // hack React16 (This is what Torn uses)
      let tracker = input._valueTracker;
      if (tracker) {
        tracker.setValue(lastValue);
      }
      input.dispatchEvent(event);
    }

    addFillMaxButtons();

    // Return to avoid iOS WKErrorDomain
    123;
  ''';
}

String travelRemovePlaneJS() {
  return '''
    var style = document.createElement('style');
    style.type = 'text/css';
    style.innerHTML = '.travel-agency-travelling .stage, .travel-agency-travelling .popup-info { display: none !important; }';
    document.getElementsByTagName('head')[0].appendChild(style);
        
    // Return to avoid iOS WKErrorDomain
    123;
  ''';
}

String travelReturnHomeJS() {
  return '''
    function goHome() {
      const doc = document;
      let travelHome1 = doc.querySelector('[class*="travel-home t-clear"]');
      
      if(!travelHome1){
          return;
      }
      
      function sleep(ms) {
			  return new Promise(resolve => setTimeout(resolve, ms));
			}
      
      async function initReturn() {
          travelHome1.click();
          await sleep(1000);
          var travelHome2 = doc.querySelector('[class="btn c-pointer"]');
          travelHome2.click();
      }
      
      initReturn();
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
        if(src.indexOf("https://www.torn.com/images/items/") > -1){
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
    // Credits
    // Implementation logic partially based on TornTools by Mephiles and DKK
    // New React 15/16 dispatch event based on Father's input
        
    (async function() {  
        var doc = document;
        
      function sleep(ms) {
          return new Promise(resolve => setTimeout(resolve, ms));
        }
      
      var documentLoaded = doc.querySelectorAll("[class*='rowItems_").length;
      if (documentLoaded === 0) {
        console.log("waiting for bazaar");
        await sleep(2000);
      }
      
        var narrow_screen = false; 
        if (doc.querySelector("[class*='searchBar_'] [class*='tablet_']") !== null 
          || doc.querySelector("[class*='searchBar_'] [class*='mobile']") !== null) {
          narrow_screen = true;
        }
        
        function addFillMaxButtons(){
        
          function addStyle(styleString) {
            const style = document.createElement('style');
            style.textContent = styleString;
            document.head.append(style);
          }
        
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
          
          // Creates our button
          addStyle(`
            .max-buy {
            border: none !important;
            position: absolute;
            height: 15px;
            line-height: 15px;
            bottom: 0;
            left: 10px;
            font-size: 11px;
            }
          `);
          
          // Brings existing buy button a little up
          addStyle(`
            button[class^="buy___"] {
            padding-bottom: 20px !important;
            font-size: 11px !important;
			      text-transform: uppercase;
            }
          `);
        
          // Narrow screen: load all buttons at once
          if(narrow_screen){
          
            // Plenty of rowItems, one for each item
            let item_boxes = doc.querySelectorAll("[class*='rowItems_");
        
            if(!item_boxes){
              return;
            }
              
            for(let item_box of item_boxes){
              let buy_btn = item_box.querySelector("[class*='buy_']");
              let max_span = doc.createElement('span');
              max_span.innerHTML = '<a class="max-buy">MAX</a>';
              buy_btn.parentElement.appendChild(max_span);
        
              max_span.addEventListener("click", function(event){
                event.stopPropagation();
                let max = parseInt(item_box.querySelector("[class*='amount_']").innerText.replace(/\D/g, ""));
                let price = parseInt(item_box.querySelector("[class*='price_']").innerText.replace(/[,$]/g, ""));
                let user_money = parseInt(document.querySelector("#user-money").dataset.money);
                if (Math.floor(user_money / price) < max) max = Math.floor(user_money / price);
                if (max > 10000) max = 10000;
                amountBox = item_box.querySelector("[class*='buyAmountInput_']");
                dispatchClick(amountBox, max);
              });
            }
            
          // Wide screen: load button in the expandable box only when the cart is pressed
          } else {
            
            doc.addEventListener("click", (event) => {
              
              if (event.target.getAttribute("class").includes("controlPanelButton_") && event.target.getAttribute("aria-label").includes("Buy")) {
                
                // Only one buy menu opened at a time, no need to loop
                let item_box = doc.querySelector("[class*='buyMenu_");
        
                if(!item_box){
                  return;
                }
                        
                var buy_btn = item_box.querySelector("[class*='buy_']");
                let max_span = doc.createElement('span');
                max_span.innerHTML = '<a class="max-buy">MAX</a>';
                buy_btn.parentElement.appendChild(max_span);
        
                max_span.addEventListener("click", function(event){
                  event.stopPropagation();
                  let max = parseInt(item_box.querySelector("[class*='amount_']").innerText.replace(/\D/g, ""));
                  let price = parseInt(item_box.querySelector("[class*='price_']").innerText.replace(/[,$]/g, ""));
                  let user_money = parseInt(document.querySelector("#user-money").dataset.money);
                  if (Math.floor(user_money / price) < max) max = Math.floor(user_money / price);
                  if (max > 10000) max = 10000;
                  amountBox = item_box.querySelector("[class*='buyAmountInput_']");
                  dispatchClick(amountBox, max);
                });
              }
            });
                
          }
        }
        
        // Delete and recreate buttons when scrolling, otherwise they'll appear on top of each other
        // Not needed for wide screen
        if (narrow_screen) {
          let moreItemsObserver = new MutationObserver(renewButtons);
          moreItemsObserver.observe(doc.querySelector(".ReactVirtualized__Grid__innerScrollContainer"), { childList: true });
          function renewButtons() {
            var existing_list = doc.querySelectorAll(".max-buy");
            for(let item of existing_list){
              item.remove();
            }
            addFillMaxButtons();
          }
        }
        
        // Launch main function at the start
        addFillMaxButtons();
        
        // Return to avoid iOS WKErrorDomain
        123;
    })();  
  ''';
}

String removeChatOnLoadStartJS() {
  return '''
    try {
      var style = document.createElement('style');
      style.type = 'text/css';
      style.innerHTML = '[class*="chat-box-wrap_"] { height: 39px; position: fixed; right: 0; bottom: 0; color: #fff; z-index: 999999; display: none }';
      document.getElementsByTagName('head')[0].appendChild(style);
    } catch (e) {
      // Sometimes firing too early and generating error in other scripts
    }
    
    // Return to avoid iOS WKErrorDomain
    123;
  ''';
}

String removeChatJS() {
  return '''
    try {
      var doc = document;
      var chatBox = document.querySelectorAll("[class*='chat-box-wrap_']");
      chatBox[0].style.display = 'none';
    } catch (e) {
      // Sometimes firing too early and generating error in other scripts
    }
    
    // Return to avoid iOS WKErrorDomain
    123;
  ''';
}

String restoreChatJS() {
  return '''
    var doc = document;
    var chatBox = document.querySelectorAll("[class*='chat-box-wrap_']");
    chatBox[0].style.display = 'block';
    
    // Return to avoid iOS WKErrorDomain
    123;
  ''';
}

String quickItemsJS({@required String item, bool faction = false, bool eRefill = false, bool nRefill = false}) {
  String timeRegex =
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
            console.log(resp.responseText);
            
            var response = JSON.parse(resp.responseText);
            var topBox = document.querySelector('.content-title');
            topBox.insertAdjacentHTML('afterend', '<div class="resultBox">2</div>');
            resultBox = document.querySelector('.resultBox');
            resultBox.style.display = "block";
            if (response.success === false) {
              resultBox.innerHTML = response.message;
            } else {
              resultBox.innerHTML = response.text;
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

String changeLoadOutJS({@required String item, @required bool attackWebview}) {
  return '''
    var action = 'https://www.torn.com/page.php?sid=itemsLoadouts&step=changeLoadout&setID=${item}';
    
    ajaxWrapper({
      url: action,
      type: 'GET',
      oncomplete: function(resp) {
        if (${attackWebview}) {
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

String chatHighlightJS({@required String highlightMap}) {
  return '''
    // Credit: Torn Tools
    
    // Example var highlights = [ { name: "Manuito", highlight: "rgba(124, 169, 0, 0.4)", sender: "rgba(124, 169, 0, 1)" } ];
    var highlights = $highlightMap;
  
    chatsLoaded().then(() => {
      
      String.prototype.replaceAll = function (text, replace) {
        let str = this.toString();
      
        if (typeof text === "string") {
          while (str.includes(text)) {
            str = str.replace(text, replace);
          }
        } else if (typeof text === "object") {
          if (Array.isArray(text)) {
            for (let t of text) {
              str = str.replaceAll(t, replace);
            }
          }
        }
      
        return str;
      };
    
      if (document.querySelector("[class*='chat-box-wrap_']")) {
        manipulateChat();
      }
    
      function manipulateChat() {
        for (let chat of document.querySelectorAll("[class*='chat-box-content_']")) {
          for (let message of chat.querySelectorAll("[class*='message_']")) {
            applyChatHighlights(message);
          }
        }
      }
    
      function applyChatHighlights(message) {
        let sender = message.querySelector("a").innerText.replace(":", "").trim();
        let text = simplify(message.querySelector("span").innerText);
        const words = text.split(" ").map(simplify);
      
        for (let entry of highlights) {
          if (entry["name"] === sender) {
            // Color for name of sender
            message.querySelector("a").style.color = entry["sender"];
          }
        }
      
        for (let entry of highlights) {
          if (!words.includes(entry["name"].toLowerCase())) continue;
          let color = entry["highlight"];
          // Color for messages background
          message.querySelector("span").parentElement.style.backgroundColor = color;
          break;
        }
      
        function simplify(text) {
          return text.toLowerCase().replaceAll([".", "?", ":", "!", '"', "'", ";", "`", ","], "");
        }
      }  
    
      new MutationObserver((mutationsList) => {
        for (let mutation of mutationsList) {
          for (let addedNode of mutation.addedNodes) {
            if (addedNode.classList && addedNode.classList.toString().includes("chat-box-content_")) {
              manipulateChat();
            }
          
            if (addedNode.classList && addedNode.classList.toString().includes("message_")) {
              applyChatHighlights(addedNode);
            }
          }
        }
      }).observe(document.querySelector("#chatRoot"), { childList: true, subtree: true });  
    });
    
    function chatsLoaded() {
      return new Promise((resolve) => {
        let checker = setInterval(() => {
          if (document.querySelector("[class*='chat-box-wrap_']")) {
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

String jailJS({
  @required int levelMin,
  @required int levelMax,
  @required int timeMin,
  @required int timeMax,
  @required int scoreMin,
  @required int scoreMax,
  @required bool bailTicked,
  @required bool bustTicked,
  @required bool excludeSelf,
  @required String excludeName,
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
        if ($excludeSelf && name === "$excludeName" && shouldHide) {
          shouldHide = false;
        }
                
        if (shouldHide) {
          //player.hidden = true; // Not allowed with new user agent on iOS
          player.style.display = "none"; 
        } else {
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
String MiniProfiles() {
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
  @required int levelMax,
  @required bool removeNotAvailable,
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

String ocNNB({@required String members}) {
  return '''
    // Credits: some functions and logic thanks to Torn Tools

    (function() {

      var data = $members;
	
      function loadNNB () {

		    var iw = window.innerWidth;

        // Avoid adding NNB twice
        var savedFound = document.querySelector(".pdaNNBListener") !== null;
        if (!savedFound) {
          var save = document.querySelector(".faction-crimes-wrap");
          save.classList.add("pdaNNBListener");
          console.log("Torn PDA: adding NNB!");
        } else {
          console.log("PDA NNB found, returning");
          return;
        }
	
        // Add style nnb title
        function addStyle(styleString) {
          const style = document.createElement('style');
          style.textContent = styleString;
          document.head.append(style);
        }

        addStyle(
          `.pda-nnb-title {
          text-align: right;
          width: 30px;
          }`
        );

        addStyle(
          `.pda-nnb-value {
          width: 30px;
          }`
        );

        addStyle(
          `.member.pda-modified-top-narrow {
          width: 140px !important;
          }`
        );
		
        addStyle(
              `.member.pda-modified-top-wide {
              width: 200px !important;
              }`
            );
        
        addStyle(
              `.member.pda-modified-bottom-narrow {
              width: 80px !important;
              }`
            );
		
        addStyle(
              `.member.pda-modified-bottom-wide {
              width: 140px !important;
              }`
            );

        addStyle(
          `.level.pda-modified-top-narrow {
          width: 15px !important;
          }`
        );
        
        addStyle(
              `.level.pda-modified-top-wide {
              width: 25px !important;
              }`
            );
		
        addStyle(
            `.level.pda-modified-bottom-narrow {
              width: 15px !important;
              }`
            );
        
        addStyle(
            `.level.pda-modified-bottom-wide {
              width: 25px !important;
              }`
            );

        addStyle(
          `.offences.pda-modified {
          width: 50px !important;
          }`
        );

        addStyle(
          `.act.pda-modified {
          width: 29px !important;
          }`
        );
        
        addStyle(
          `.stat.pda-modified {
          width: 50px !important;
          }`
        );


        function createNerveTitle () {
          var newDiv = document.createElement("li");
          var newContent = document.createTextNode("NNB");
          newDiv.className = "pda-nnb-title";
          newDiv.appendChild(newContent);
          return newDiv;
        }

        function createNerveValue (value) {
          var newDiv = document.createElement("li");
          var newContent = document.createTextNode(value);
          newDiv.className = "pda-nnb-value";
          newDiv.appendChild(newContent);
          return newDiv;
        }
        
        var member = document.querySelectorAll('.member');
        for (var m of member) {
          // Crimes scheduled
          var row = m.closest(".organize-wrap .crimes-list .details-list > li > ul");
          if (row !== null) 
          {
            row.querySelectorAll(`.offences`).forEach((element) => element.classList.add("pda-modified"));
            
            row.querySelectorAll(`.level`).forEach((element) => element.classList.add("pda-modified"));
                  if (iw < 785) {
              row.querySelectorAll(`.level`).forEach((element) => element.classList.add("pda-modified-top-narrow"));
            } else {
              row.querySelectorAll(`.level`).forEach((element) => element.classList.add("pda-modified-top-wide"));
            }
                  
            if (iw < 387) {
              row.querySelectorAll(`.member`).forEach((element) => element.classList.add("pda-modified-top-narrow"));
            } else {
              row.querySelectorAll(`.member`).forEach((element) => element.classList.add("pda-modified-top-wide"));
            }				
                  
            row.querySelectorAll(`.stat`).forEach((element) => element.classList.add("pda-modified"));
            
            let stat = row.querySelector(".stat");
            if (stat === null) continue; 
            
            if (row.classList.contains("title")) {
            stat.parentElement.insertBefore(
              createNerveTitle(),
              stat
            );
            continue;
            }
            
            const id = row.querySelector(".h").getAttribute("href").split("XID=")[1];
            
            var found = false;
            for (const [key, value] of Object.entries(data)) {
            if (id === key) {
              stat.insertAdjacentElement("beforebegin", createNerveValue(value));
              found = true;
              continue;
            } 
            }
            if (!found) {
            stat.insertAdjacentElement("beforebegin", createNerveValue("unk"));
            }
            continue;
          }
          
            
          // Crimes available
          var row = m.closest(".plans-list .item");
          if (row !== null) {
            row.querySelectorAll(`.offences`).forEach((element) => element.classList.add("pda-modified"));
            
            row.querySelectorAll(`.level`).forEach((element) => element.classList.add("pda-modified"));
                  if (iw < 785) {
              row.querySelectorAll(`.level`).forEach((element) => element.classList.add("pda-modified-bottom-narrow"));
            } else {
              row.querySelectorAll(`.level`).forEach((element) => element.classList.add("pda-modified-bottom-wide"));
            }
                  
            if (iw < 387) {
              row.querySelectorAll(`.member`).forEach((element) => element.classList.add("pda-modified-bottom-narrow"));
            } else {
              row.querySelectorAll(`.member`).forEach((element) => element.classList.add("pda-modified-bottom-wide"));
            }	
                  
            row.querySelectorAll(`.act`).forEach((element) => element.classList.add("pda-modified"));
              
            let act = row.querySelector(".act");
            if (act === null) continue; 
            
            if (row.classList.contains("title")) {
            act.parentElement.insertBefore(
              createNerveTitle(),
              act
            );
            continue;
            }
            
            const id = row.querySelector(".h").getAttribute("href").split("XID=")[1];
            
            var found = false;
            for (const [key, value] of Object.entries(data)) {
            if (id === key) {
              act.insertAdjacentElement("beforebegin", createNerveValue(value));
              found = true;
              continue;
            } 
            }
            if (!found) {
            act.insertAdjacentElement("beforebegin", createNerveValue("unk"));
            }
          }	    
        }  
      }

      let waitForOCAndRun = setInterval(() => {
        if (document.querySelector(".faction-crimes-wrap")) {
          loadNNB();
          return clearInterval(waitForOCAndRun);
        }
      }, 300);

    })();
  ''';
}

String barsDoubleClickRedirect() {
  return '''
    (function() {
      
      function addBarsListener() {
        function onEnergyClick(event) {
          window.open("https://www.torn.com/gym.php", "_self");
        }
        
        function onNerveClick(event) {
          window.open("https://www.torn.com/crimes.php", "_self");
        }
          
        var savedFound = document.querySelector(".pdaListenerBarsDoubleClick") !== null;
        var energyBar = document.querySelector(`[id*="barEnergy"]`);
        var nerveBar = document.querySelector(`[id*="barNerve"]`);
        
        if (!savedFound && energyBar !== null && nerveBar !== null) {
          var save = document.querySelector(".content-wrapper");
          save.classList.add("pdaListenerBarsDoubleClick");
          energyBar.addEventListener("dblclick", onEnergyClick);
          nerveBar.addEventListener("dblclick", onNerveClick);
        } 
      }

      let pass = 0;
      let waitForBarsAndRun = setInterval(() => {
        if (document.querySelector(`[id*="barEnergy"]`)) {
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
