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
            width: 62px;
            text-align: center;
            border-left: 2px solid #ccc;
            height: 15px;
            line-height: 15px;
            bottom: -17px;
            right: 0px;
            font-size: 9px;
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
            
            max = max > limit ? limit:max;
            max = Math.floor(user_money/price) < max ? Math.floor(user_money/price) : max;

            if (max_span.innerHTML == '<a class="max-buy">FILL</a>') {
              dispatchClick(buy_btn.parentElement.querySelector("input[name='amount']"), max);
              max_span.innerHTML = '<a class="max-buy">+3</a>';
            } else if (max_span.innerHTML == '<a class="max-buy">+3</a>') {
              dispatchClick(buy_btn.parentElement.querySelector("input[name='amount']"), max + 3);
              max_span.innerHTML = '<a class="max-buy">+5</a>';
            } else if (max_span.innerHTML == '<a class="max-buy">+5</a>') {
              dispatchClick(buy_btn.parentElement.querySelector("input[name='amount']"), max + 5);
              max_span.innerHTML = '<a class="max-buy">+10</a>';
            } else if (max_span.innerHTML == '<a class="max-buy">+10</a>') {
              dispatchClick(buy_btn.parentElement.querySelector("input[name='amount']"), max + 10);
              max_span.innerHTML = '<a class="max-buy">FILL</a>';
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
            
            max = max > limit ? limit:max;
            max = Math.floor(user_money/price) < max ? Math.floor(user_money/price) : max;
            
            if (max_span.innerHTML == '<button class="torn-btn">MAX</button>') {
              dispatchClick(buy_btn.parentElement.parentElement.parentElement.parentElement.querySelector("input[name='amount']"), max);
              max_span.innerHTML = '<button class="torn-btn">+3</button>';
            } else if (max_span.innerHTML == '<button class="torn-btn">+3</button>') {
              dispatchClick(buy_btn.parentElement.parentElement.parentElement.parentElement.querySelector("input[name='amount']"), max + 3);
              max_span.innerHTML = '<button class="torn-btn">+5</button>';
            } else if (max_span.innerHTML == '<button class="torn-btn">+5</button>') {
              dispatchClick(buy_btn.parentElement.parentElement.parentElement.parentElement.querySelector("input[name='amount']"), max + 5);
              max_span.innerHTML = '<button class="torn-btn">+10</button>';
            } else if (max_span.innerHTML == '<button class="torn-btn">+10</button>') {
              dispatchClick(buy_btn.parentElement.parentElement.parentElement.parentElement.querySelector("input[name='amount']"), max + 10);
              max_span.innerHTML = '<button class="torn-btn">MAX</button>';
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
    
    var doc = document;
    
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
        font-size: 10.5px;
        }
      `);
      
      // Brings existing buy button a little up
      addStyle(`
        .buy___1OagD {
        padding-bottom: 20px !important;
        font-size: 12px !important;
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

String quickItemsJS({@required String item}) {
  return '''
    // Credit Torn Tools
    
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
    
    var url = "https://www.torn.com/" + addRFC("item.php");
      
    ajaxWrapper({
      url: url,
      type: 'POST',
      data: 'step=actionForm&id=${item}&action=use',
      oncomplete: function(resp) {
      var response = resp.responseText;
      var topBox = document.querySelector('.content-title');
      topBox.insertAdjacentHTML('afterend', '<div class="resultBox">2</div>');
      resultBox = document.querySelector('.resultBox');
      resultBox.style.display = "block";
      resultBox.innerHTML = response;
      resultBox.querySelector(`a[data-item='${item}`).click();
      },
      onerror: function(e) {
      console.error(e)
      }
    });
    
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

String jailJS() {
  return '''
    var doc = window.document;
    for (var player of doc.querySelectorAll(".users-list > li")) {
      const actionWrap = player.querySelector(".bust");
      actionWrap.style.backgroundColor = "#288a0059";
    
      const actionIcon = player.querySelector(".bust-icon");
      actionIcon.style.filter = "brightness(0.5)";
      
      let bustLink = actionWrap.getAttribute("href");
      if (bustLink[bustLink.length - 1] !== "1") bustLink += "1";
      actionWrap.setAttribute("href", bustLink);
    }
  ''';
}
