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
  ''';
}

String buyMaxJS() {
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
            
            buy_btn.parentElement.querySelector("input[name='amount']").value = max;
            buy_btn.parentElement.querySelector("input[name='amount']").dispatchEvent(new Event("blur"));
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
            
            buy_btn.parentElement.parentElement.parentElement.parentElement.querySelector("input[name='amount']").value = max;
            buy_btn.parentElement.parentElement.parentElement.parentElement.querySelector("input[name='amount']").dispatchEvent(new Event("blur"));
          });
        }
      }
    }
    
    addFillMaxButtons();
  
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
    
    highlightItems();
  ''';
}

String addBazaarFillButtonsJS() {
  return '''
    // ADD
    var doc = document;
    var bazaar = doc.querySelectorAll(".clearfix.no-mods");
    
    var needToAdd = true;
    for(let item of bazaar){
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
            
        qtyBox.value = inventoryQuantity;
        qtyBox.dispatchEvent(new Event("input", { bubbles: true }));	
        });
      }
    }
  ''';
}

String removeBazaarFillButtonsJS() {
  return '''
    var doc = document;
    var bazaar = doc.querySelectorAll(".clearfix.no-mods");

    for(let item of bazaar){
      let fill = item.querySelector(".torn-btn");
      if (fill != null) {
        fill.remove();
      }
    }
  ''';
}

String removeChatOnLoadStartJS() {
  return '''
    var style = document.createElement('style');
    style.type = 'text/css';
    style.innerHTML = '.chat-box-wrap_20_R_ { height: 39px; position: fixed; right: 0; bottom: 0; color: #fff; z-index: 999999; display: none }';
    document.getElementsByTagName('head')[0].appendChild(style);
  ''';
}

String removeChatJS() {
  return '''
    var doc = document;
    var chatBox = document.getElementsByClassName("chat-box-wrap_20_R_");
    chatBox[0].style.display = 'none';
  ''';
}

String restoreChatJS() {
  return '''
    var doc = document;
    var chatBox = document.getElementsByClassName("chat-box-wrap_20_R_");
    chatBox[0].style.display = 'block';
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
        
    addStyle(`
      .resultBox {
        border: 2px dotted black;
        margin-top: 20px;
        margin-bottom: 20px;
        padding:5px;
        background-color: #fff;
      }
    `);
    
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

  ''';
}

String chatHighlightJS({@required String highlightMap}) {
  return '''
    // Credit: Torn Tools
    
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
    
    
      if (document.querySelector(".chat-box-content_2C5UJ .overview_1MoPG .message_oP8oM")) {
        manipulateChat();
      }
    
      function manipulateChat() {
        for (let chat of document.querySelectorAll(".chat-box-content_2C5UJ")) {
          for (let message of chat.querySelectorAll(".message_oP8oM")) {
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
          
          if (addedNode.classList && addedNode.classList.contains("chat-box-content_2C5UJ")) {
          manipulateChat();
          }
    
          if (addedNode.classList && addedNode.classList.contains("message_oP8oM")) {
          applyChatHighlights(addedNode);
          }
        }
        }
      }).observe(document.querySelector("#chatRoot"), { childList: true, subtree: true });  
    
    });
    
    function chatsLoaded() {
      return new Promise((resolve) => {
        let checker = setInterval(() => {
          if (document.querySelector(".overview_1MoPG")) {
            setInterval(() => {
              resolve(true);
            }, 300);
            return clearInterval(checker);
          }
        });
      });
    } 
  ''';
}