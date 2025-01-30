// ==UserScript==
// @name         Item Market Auto Price
// @namespace    dev.kwack.torn.imarket-auto-price
// @version      1.0.1
// @description  Automatically set the price of items relative to the current market
// @author       Kwack [2190604]
// @match        https://www.torn.com/page.php?sid=ItemMarket
// @connect      api.torn.com
// ==/UserScript==

// @ts-check

/**
 * @type {number}
 * @readonly
 * The price to undercut the current lowest item on the market by.
 * If you wish to match the lowest price, set this to 0.
 * If you wish to be $1 higher than the current price, set this to -1.
 * Please note that the script will not set a price lower than 1.
 */
/* **EDIT NUMBER BELOW** */
const diff = 5;
/* **EDIT NUMBER ABOVE** */

/**
 * @type {string}
 * @readonly
 * The current PDA API key. Do not modify this unless you're not using PDA.
 */
const key = "###PDA-APIKEY###";

/**
 * Calls the API and returns the lowest priced item currently on the market.
 * @param {string} itemId - the item ID to check
 * @returns {Promise<number>} the lowest price for the item
 */
function getLowestPrice(itemId) {
	const baseURL = "https://api.torn.com/v2/market";
	const searchParams = new URLSearchParams({
		selections: "itemmarket",
		key,
		id: itemId,
		offset: "0",
	});
	const url = new URL(`?${searchParams.toString()}`, baseURL);
	return fetch(url)
		.then((res) => res.json())
		.then((data) => {
			if ("error" in data) throw new Error(data.error.error);
			const price = data?.itemmarket?.listings?.[0]?.price;
			if (typeof price === "number" && price >= 1) return price;
			throw new Error(`Invalid price: ${price}`);
		});
}

/**
 * Updates the input field directly and then emits the event to trick React into updating its state. Pinched from TornTools.
 * @param {HTMLInputElement} input
 * @param {string | number} value
 * @returns {void}
 * @see https://github.com/Mephiles/torntools_extension/blob/54db1d1dbe2dc84e3267d56815e0dedce36e4bf1/extension/scripts/global/functions/torn.js#L1573
 */
function updateInput(input, value) {
	input.value = `${value}`;
	// Needed to trigger React to update its state
	input.dispatchEvent(new Event("input", { bubbles: true }));
}

/**
 * Takes an input and sets the price to the current lowest price minus the diff
 * @param {HTMLInputElement} input
 */
async function addPrice(input) {
	if (!(input instanceof HTMLInputElement)) throw new Error("Input is not an HTMLInputElement");
	const row = input.closest("div[class*=itemRowWrapper]");
	const image = row?.querySelector("img");
	if (!image) throw new Error("Could not find image element");
	if (image.parentElement?.matches("[class*='glow-']")) throw new Warning("Skipping a glowing RW item");
	const itemId = image.src?.match(/\/images\/items\/([\d]+)\//)?.[1];
	if (!itemId) throw new Error("Could not find item ID");
	const currentLowestPrice = await getLowestPrice(itemId);
	if (!currentLowestPrice) throw new Error("Could not get lowest price");
	// Sets price to either 1 or the current lowest price minus 5, whichever is higher. This prevents negative prices
	const priceToSet = Math.max(1, currentLowestPrice - diff);
	updateInput(input, priceToSet);
	input.classList.add("kw--price-set");
}

function main() {
	$(document).on(
		"click",
		"div[class*=itemRowWrapper] div[class*=priceInputWrapper] > div.input-money-group > input.input-money:not([type=hidden]):not(.kw--price-set)",
		(e) => {
			const input = e.target;
			addPrice(input).catch((e) => {
				if (e instanceof Warning) {
					console.warn(e);
					input.style.outline = "2px solid yellow";
				} else {
					console.error(e);
					input.style.outline = "2px solid red";
				}
			});
		}
	);
}

main();

// Custom error class, used to display a warning outline (yellow) instead of an error outline (red)
class Warning extends Error {}
