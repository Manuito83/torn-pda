// ==UserScript==
// @name         Hospital filters
// @namespace    https://www.torn.com/profiles.php?XID=2190604
// @version      0.2 (updated by Manuito)
// @description  An attempt to filter people who have revives disabled.
// @author       Kwack_Kwack [2190604]
// @match        *://www.torn.com/hospitalview.php*
// @require     https://ajax.googleapis.com/ajax/libs/jquery/3.4.1/jquery.min.js
// ==/UserScript==

//Thanks to Manuito for the following function to use GM_addStyle in PDA.
let GM_addStyle = function (s) {
	let style = document.createElement("style");
	style.type = "text/css";
	style.innerHTML = s;
	document.head.appendChild(style);
};

var styles = `
.filtered-row {
    display: none !important
}
`;

// Finds parents (credit: Torn Tools)
function hasParent(element, attributes = {}) {
	if (!element.parentElement) return false;
	if (
		attributes.class &&
		element.parentElement.classList.contains(attributes.class)
	)
		return true;
	if (attributes.id && element.parentElement.id === attributes.id)
		return true;
	return hasParent(element.parentElement, attributes);
}

function enableFilters() {
	infobox.innerHTML =
		'<div class="info-msg-cont green border-round m-top10"><div class="info-msg border-round"><i class="info-icon"></i><div class="delimiter"><div class="msg right-round" tabindex="0"><p><button id="disable" type="button" class="torn-btn">Disable revive filter</button></p></div></div></div></div>';
	console.log("enabling filters");
	document
		.getElementById("disable")
		.addEventListener("click", disableFilters);
	var revivesDisabledRows = [];
	for (
		var i = 0;
		i < document.getElementsByClassName("reviveNotAvailable").length;
		i++
	) {
		revivesDisabledRows[i] =
			document.getElementsByClassName("reviveNotAvailable")[
				i
			].parentElement;
	}
	try {
		Array.from(revivesDisabledRows).forEach((i) =>
			i.classList.add("filtered-row")
		);
	} catch (error) {
		console.log(
			error + "\n This error was thrown when adding filtered-row class"
		);
	}

	var wrap = document.querySelector(".content-wrapper");
	wrap.classList.add("hospitalScriptEnabled");
	wrap.classList.remove("hospitalScriptDisabled");
}

function disableFilters() {
	if (
		document.getElementById("enable") === null &&
		document.getElementById("disable") === null
	) {
		window.infobox = document.createElement("div");
		window.container =
			document.getElementsByClassName("content-wrapper")[0];
		var pager = document.getElementsByClassName("pagination-wrap")[0];
		container.insertBefore(infobox, pager);
	}

	infobox.innerHTML =
		'<div class="info-msg-cont red border-round m-top10"><div class="info-msg border-round"><i class="info-icon"></i><div class="delimiter"><div class="msg right-round" tabindex="0"><p><button id="enable" type="button" class="torn-btn">Enable revive filter</button></p></div></div></div></div>';
	console.log("disabling filters");
	document.getElementById("enable").addEventListener("click", enableFilters);
	try {
		Array.from(document.getElementsByClassName("filtered-row")).forEach(
			(i) => i.classList.remove("filtered-row")
		);
	} catch (error) {
		console.log(
			error + "\n This error was thrown when removing filtered-row class"
		);
	}

	var wrap = document.querySelector(".content-wrapper");
	wrap.classList.add("hospitalScriptDisabled");
	wrap.classList.remove("hospitalScriptEnabled");
}

async function addPdaVariable() {
	// Save variable in a persistent object so that we only add the listener once
	// event if we fire the script several times (removing the listener won't work)
	var savedFound = document.querySelector(".pdaListener") !== null;
	if (!savedFound) {
		var save = document.querySelector(".content-wrapper");
		save.classList.add("pdaListener");
		document.addEventListener("click", listener, true);
	}
}

var waitForElementsAndRun = setInterval(function () {
	if (document.querySelector(".user") !== null) {
		clearInterval(waitForElementsAndRun);
		// Main logic
		GM_addStyle(styles);
		disableFilters();
		addPdaVariable();
	}
}, 300);

// Listener for page change
var intervalRepetitions = 0;
var listener = function (event) {
	if (
		event.target.classList &&
		!event.target.classList.contains("gallery-wrapper") &&
		hasParent(event.target, { class: "gallery-wrapper" })
	) {
		let checker = setInterval(() => {
			if (document.querySelector(".user")) {
				var savedFound =
					document.querySelector(".hospitalScriptEnabled") !== null;
				if (savedFound) {
					enableFilters();
				} else {
					disableFilters();
				}
				return clearInterval(checker);
			}
			if (++intervalRepetitions === 50) {
				return clearInterval(checker);
			}
		}, 300);
	}
};
