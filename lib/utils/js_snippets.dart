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
