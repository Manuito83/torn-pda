// ==UserScript==
// @name         Torn company stock order
// @version      0.2.11
// @description  Automatically calculate stock percent based on sale and enter the order amount to order up to max capacity.
// @author       Nemithrell - Torn PDA adaptation v1 [Manuito]
// @match        companies.php
// ==/UserScript==

var apiKey = '###PDA-APIKEY###';

function run () {
	var urlStock = `https://api.torn.com/company/?selections=stock&key=${apiKey}`;
	var urlStorage = `https://api.torn.com/company/?selections=detailed&key=${apiKey}`;
	var storage

	fetch(urlStorage)
		.then(function(response) {
		if(response.ok) {
			return response.json();
		}
		throw new Error('Network response was not ok.');
	})
		.then(function(myJson) {
		if (myJson.error){
			throw new Error(myJson.error.error);
		}
		storage = myJson.company_detailed.upgrades.storage_space;
	});

	fetch(urlStock)
		.then(function(response) {
		if(response.ok) {
			return response.json();
		}
		throw new Error('Network response was not ok.');
	})
		.then(function(myJson) {
		if (myJson.error){
			throw new Error(myJson.error.error);
		}

		var totalSold = 0;
		var totalStock = 0;
		var availableStock = 0;
		var totalNeededStock = 0;
		var maxStock = 0;
		for (var key1 in myJson.company_stock) {
			totalSold += myJson.company_stock[key1].sold_amount;
			totalStock += myJson.company_stock[key1].in_stock;
			totalStock += myJson.company_stock[key1].on_order;
		}

		availableStock = storage - totalStock;

		for (var key2 in myJson.company_stock) {
			maxStock = 0;
			maxStock = storage * (myJson.company_stock[key2].sold_amount/totalSold);
			totalNeededStock += maxStock - (myJson.company_stock[key2].on_order + myJson.company_stock[key2].in_stock) > 0 ?  maxStock - (myJson.company_stock[key2].on_order + myJson.company_stock[key2].in_stock) : 0;
		}

		$( ".stock-list-title.bold.t-hide" ).find(".name")[0].firstChild.after(" (MaxStock)");
		$( ".stock-list-title.bold.t-hide" ).find(".stock")[0].firstChild.after(" (+order)");

		for (var key in myJson.company_stock) {
			if (myJson.company_stock.hasOwnProperty(key)) {
				var orderPercent = myJson.company_stock[key].sold_amount/totalSold
				var orderAmount = 0;
				maxStock = 0;
				maxStock = storage * (myJson.company_stock[key].sold_amount/totalSold);
				var neededStock = maxStock - (myJson.company_stock[key].on_order + myJson.company_stock[key].in_stock)
				var neededPercent = neededStock > 0 ? neededStock/totalNeededStock : 0;

				orderAmount = Math.floor(availableStock * neededPercent);
				console.log(availableStock);
				console.log(neededPercent);
				console.log("**");

				$( ".stock-list.fm-list.t-blue-cont.h" ).find("div:contains("+key+")").append(" (" + new Intl.NumberFormat('en-US').format(Math.floor(maxStock)) + ")");
				$( ".stock-list.fm-list.t-blue-cont.h" ).find("div:contains("+key+")").parent().find(".stock").append(" (" + new Intl.NumberFormat('en-US').format(1 + myJson.company_stock[key].in_stock) + ")");
				
				if(orderAmount != 0)
				{
					$( ".stock-list.fm-list.t-blue-cont.h" ).find("div:contains("+key+")").parent().find(".quantity").find("input").val(orderAmount);
				}
				$( ".stock-list.fm-list.t-blue-cont.h" ).find("div:contains("+key+")").parent().find(".quantity").find("input").trigger('keyup');
			}
		}
	}).catch(function(error) {
		console.log('There has been a problem with your fetch operation: ', error.message);
	});
}

function stocksLoaded() {
  return new Promise((resolve) => {
	let checker = setInterval(() => {
	  if (document.querySelector(".stock-list-wrap")) {
		setInterval(() => {
		  resolve(true);
		}, 300);
		return clearInterval(checker);
	  }
	});
  });
} 

if (document.querySelector(".stock-list-wrap")) {
	run();
} else {
	stocksLoaded().then(() => {
		run();
	});
}