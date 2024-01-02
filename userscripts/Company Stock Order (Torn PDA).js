// ==UserScript==
// @name         auto-stock-fill
// @namespace    dev.kwack.torn.scripts
// @version      1.0.0
// @description  Automatically fill your company's stock order
// @author       Kwack [2190604]
// @match        https://www.torn.com/companies.php*
// @grant        none
// ==/UserScript==

/* https://github.com/Mephiles/torntools_extension/blob/master/extension/scripts/features/auto-stock-fill/ttAutoStockFill.js */

(async () => {
	window.addEventListener("hashchange", (e) => {
		if (getHashParams(new URL(e.newURL).hash).get("option") === "stock") start();
	});
	if (getHashParams(document.location.hash).get("option") === "stock") start();
	async function start() {
		getForm().then(addButton).catch(console.error);
	}
	function getHashParams(hash) {
		return new URLSearchParams(hash.replace(/[#\/]/g, ""));
	}
	function callback(form) {
		const storageCap = Array.from(form.querySelectorAll(".storage-capacity > *")).map((el) =>
			parseInt(el.innerText),
		);
		const usableCap = storageCap[1] - storageCap[0];
		const totalSoldDaily = parseInt(form.querySelector(".stock-list > li.total .sold-daily").textContent);
		Array.from(form.querySelectorAll(".stock-list > li:not(.total):not(.quantity)")).forEach((el) => {
			const soldDaily = parseInt(el.querySelector(".sold-daily").lastChild.textContent);
			const neededStock = Math.max((soldDaily / totalSoldDaily) * usableCap, 0);
			updateInput(el.querySelector("input"), Math.floor(neededStock).toString());
		});
	}
	function addButton(form) {
		if ($("#kw-auto-fill").length > 0) return; // Do not inject button twice
		$("<span/>", { class: "btn-wrap silver" })
			.append(
				$("<span/>", { class: "btn" }).append(
					$("<button/>", { class: "torn-btn", id: "kw-auto-fill" })
						.on("click", () => callback(form))
						.text("Auto-fill"),
				),
			)
			.appendTo(form);
	}
	function getForm() {
		return new Promise((res, rej) => {
			let tick = 0;
			const interval = setInterval(() => {
				const form = document.querySelector("div#stock > form");
				if (form) {
					clearInterval(interval);
					res(form);
				} else {
					tick++;
					if (tick > 100) {
						clearInterval(interval);
						rej(new Error("**KW** FORM NOT FOUND"));
					}
				}
			}, 100);
		});
	}
	function updateInput(input, value) {
		input.value = value;
		input.dispatchEvent(new Event("change", { bubbles: true }));
		input.dispatchEvent(new Event("input", { bubbles: true }));
	}
})();