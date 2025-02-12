// ==UserScript==
// @name         Torn Custom Race Presets
// @namespace    dev.kwack.torn.custom-race-presets
// @version      1.0.0
// @description  Custom race presets
// @author       Kwack [2190604]
// @match        https://www.torn.com/page.php?sid=racing*
// @match        https://www.torn.com/loader.php?sid=racing*
// ==/UserScript==

// @ts-check
class Constants {
	static TRACKS = {
		Uptown: 6,
		Withdrawal: 7,
		Underdog: 8,
		Parkland: 9,
		Docks: 10,
		Commerce: 11,
		Two_Islands: 12,
		Industrial: 15,
		Vector: 16,
		Mudpit: 17,
		Hammerhead: 18,
		Sewage: 19,
		Meltdown: 20,
		Speedway: 21,
		Stone_Park: 23,
		Convict: 24,
	};

	static CARS_CLASSES = {
		Any_Class: 5,
		E_Class_only: 0,
		D_Class_only: 1,
		C_Class_only: 2,
		B_Class_only: 3,
		A_Class_only: 4,
		Zaibatsu_GT_R: 524,
		Mercia_SLR: 523,
		Veloria_LFA: 522,
		Lambrini_Torobravo: 521,
		Lolo_458: 520,
		Stormatti_Casteon: 519,
		Echo_R8: 518,
		Weston_Marlin_177: 517,
		Wington_GGU_: 516,
		Yotsuhada_EVX: 513,
		Colina_Tanprice: 511,
		Nano_Cavalier: 510,
		Echo_S3: 507,
		Bedford_Nova: 505,
		Stålhög_860: 501,
		Zaibatsu_Macro: 497,
		Vita_Bravo: 496,
		Limoen_Saxon: 494,
		Oceania_SS: 95,
		Trident: 94,
		Chevalier_CVR: 92,
		Verpestung_Insecta: 91,
		Edomondo_Localé: 90,
		Edomondo_ACD: 89,
		Edomondo_IR: 88,
		Echo_S4: 87,
		Invader_H3: 86,
		Volt_GT: 85,
		Knight_Firebrand: 84,
		Dart_Rampager: 83,
		Bavaria_Z8: 81,
		Bavaria_M5: 80,
		Edomondo_NSX: 78,
		Tabata_RM2: 77,
		Çagoutte_10_6: 498,
		Bedford_Racer: 500,
		Nano_Pioneer: 495,
		Papani_Colé: 499,
		Verpestung_Sport: 506,
		Alpha_Milano_156: 502,
		Coche_Basurero: 504,
		Bavaria_X5: 503,
		Volt_MNG: 93,
		Cosmos_EX: 512,
		Edomondo_S2: 509,
		Tsubasa_Impressor: 515,
		Volt_RS: 508,
		Chevalier_CZ06: 82,
		Echo_Quadrato: 79,
		Sturmfahrt_111: 514,
	};
}

class Utils {
	/** @returns {string} */
	static get rfcv() {
		const regex = /rfc_v=([\d\w]+);/;
		const rfcv = regex.exec(document.cookie)?.[1];
		if (!rfcv) throw new Error("Could not find RFCV");
		return rfcv;
	}

	static get currentTime() {
		return Math.ceil(Date.now() / 1000);
	}

	/**
	 * Shorthand for creating a new FormData object
	 * @param {Record<string, string>} data - Key/value pairs of formdata
	 * @returns {FormData}
	 */
	static createForm(data) {
		const form = new FormData();
		for (const key in data) {
			form.set(key, data[key]);
		}
		return form;
	}

	/**
	 * Creates a HTML Dialog element and appends it to the body
	 * @param {string} id
	 * @param {JQuery<HTMLElement>[]} children
	 * @returns {JQuery<HTMLDialogElement>}
	 */
	static createModal(id, ...children) {
		/** @type {JQuery<HTMLDialogElement>} */
		const dialog = $("<dialog>");
		dialog
			.attr("id", id.replaceAll(" ", "-"))
			.css({ padding: 0, border: 0, maxWidth: "100%" });

		const content = $("<div>").addClass("modal-content").appendTo(dialog);
		content.css({
			padding: "2rem",
			border: "2px solid black",
			width: "100%",
			minHeight: "100%",
			height: "fit-content",
			boxSizing: "border-box",
			background: "var(--autocomplete-background-color)",
		});

		const closeBtn = $("<button>")
			.css("scale", 2)
			.text("X")
			.on("click", () => dialog[0].close());
		closeBtn.css({
			position: "absolute",
			top: "0",
			right: "0",
			cursor: "pointer",
		});

		dialog.append(closeBtn, content.append(...children));
		dialog.on("click", (e) => {
			if (e.target === dialog[0]) dialog[0].close();
		});
		dialog.appendTo(document.body);
		return dialog;
	}

	/**
	 * Waits for the element to be present, and then returns it
	 * @param {string} selector
	 * @returns {Promise<JQuery<HTMLElement>>}
	 */
	static waitForElement(selector) {
		return new Promise((resolve) => {
			if ($(selector).length) return resolve($(selector));

			const observer = new MutationObserver(() => {
				if ($(selector).length) {
					observer.disconnect();
					resolve($(selector));
				}
			});

			observer.observe(document.body, { childList: true, subtree: true });
		});
	}

	/**
	 *
	 * @param {string} key
	 * @returns {any} - Either the parsed JSON object or null
	 */
	static getFromStorage(key) {
		try {
			const value = localStorage.getItem(key);
			if (!value) return null;
			return JSON.parse(value);
		} catch (error) {
			console.error(error);
			return null;
		}
	}

	/**
	 *
	 * @param {string} key
	 * @param {*} value
	 * @returns {void}
	 */
	static setToStorage(key, value) {
		localStorage.setItem(key, JSON.stringify(value));
	}
}

/** @type {number} */
const a = 1;
/** @type {string} */
const b = /** @type {string} */ (/** @type {unknown} */ (a));

class RacePreset {
	/** @type {string} */
	name;
	/** @type {number} */
	requiredDrivers;
	/** @type {number} */
	maxDrivers;
	/** @type {number} */
	laps;
	/** @type {keyof Constants.CARS_CLASSES} */
	allowedCars;
	/** @type {boolean} */
	upgradesAllowed;
	/** @type {number} */
	betAmount;
	/** @type {number} */
	startTime;
	/** @type {string | null} */
	password;
	/** @type {keyof Constants.TRACKS} */
	trackName;

	/**
	 * @param {Object} details
	 * @param {string} details.name
	 * @param {number} [details.requiredDrivers=2]
	 * @param {number} [details.maxDrivers=100]
	 * @param {number} details.laps
	 * @param {keyof Constants.CARS_CLASSES} [details.allowedCars="Any Class"]
	 * @param {boolean} [details.upgradesAllowed=true]
	 * @param {number} [details.betAmount=0]
	 * @param {number} [details.startTime=Utils.currentTime]
	 * @param {string | null} [details.password=null]
	 * @param {keyof Constants.TRACKS} details.trackName
	 */
	constructor(details) {
		this.name = details.name;
		this.requiredDrivers = details.requiredDrivers ?? 2;
		this.maxDrivers = details.maxDrivers ?? 100;
		this.laps = details.laps;
		this.allowedCars = details.allowedCars || "Any_Class";
		this.upgradesAllowed = details.upgradesAllowed ?? true;
		this.betAmount = details.betAmount ?? 0;
		this.startTime = details.startTime ?? Utils.currentTime;
		this.password = details.password || null;
		this.trackName = details.trackName;
	}

	get waitTime() {
		if (this.startTime < 9_999_999) {
			// Assume the start time is minutes to wait from now (legacy)
			return Utils.currentTime + this.startTime * 60;
		}
		// Else assume it's an epoch timestamp (in s), and does not need modification
		return this.startTime;
	}

	/** @returns {Request} */
	toCarSelectorRequest() {
		const url = `https://www.torn.com/loader.php?sid=racing&rfcv=${Utils.rfcv}`;
		const form = Utils.createForm({
			section: "createCustomRace",
			tab: "customrace",
			step: "create",
			rfcv: Utils.rfcv,
			title: this.name,
			minDrivers: this.requiredDrivers.toString(),
			maxDrivers: this.maxDrivers.toString(),
			trackID: Constants.TRACKS[this.trackName].toString(),
			laps: this.laps.toString(),
			carsAllowed: Constants.CARS_CLASSES[this.allowedCars].toString(),
			carsTypeAllowed: this.upgradesAllowed ? "1" : "2",
			betAmount: this.betAmount.toString(),
			waitTime: this.waitTime.toString(),
			password: this.password || "",
			createCustomRace: "START & JOIN THIS RACE",
		});
		return new Request(url, {
			// @ts-expect-error This is needed for correct encoding type
			body: new URLSearchParams(form),
			method: "POST",
			headers: { "X-Requested-With": "XMLHttpRequest" },
		});
	}

	/** @returns {Request} */
	toFinalRequest() {
		const queryParams = new URLSearchParams({
			sid: "racing",
			tab: "customrace",
			section: "getInRace",
			step: "getInRace",
			id: "",
			carID: "TODO", // TODO: Get car ID
			password: this.password || "",
			createRace: "true",
			title: this.name,
			minDrivers: this.requiredDrivers.toString(),
			maxDrivers: this.maxDrivers.toString(),
			trackID: Constants.TRACKS[this.trackName].toString(),
			laps: this.laps.toString(),
			minClass: "0", // TODO: what is this?
			carsTypeAllowed: this.upgradesAllowed ? "1" : "2",
			carsAllowed: Constants.CARS_CLASSES[this.allowedCars].toString(),
			betAmount: this.betAmount.toString(),
			waitTime: this.waitTime.toString(),
			rfcv: Utils.rfcv,
		});
		const url = `https://www.torn.com/loader.php?${queryParams.toString()}`;
		return new Request(url, {
			method: "GET",
			headers: { "X-Requested-With": "XMLHttpRequest" },
		});
	}

	/** @returns {JQuery<HTMLTableElement>} */
	toTable() {
		/** @type {JQuery<HTMLTableElement>} */
		const table = $("<table>");
		table
			.addClass("kw-preset-table")
			.append(
				$("<thead>").append(
					$("<tr>").append(
						$("<th>").text("Name"),
						$("<th>").text("Required Drivers"),
						$("<th>").text("Max Drivers"),
						$("<th>").text("Laps"),
						$("<th>").text("Allowed Cars"),
						$("<th>").text("Upgrades Allowed"),
						$("<th>").text("Bet Amount"),
						$("<th>").text("Start Time"),
						$("<th>").text("Password"),
						$("<th>").text("Track Name")
					)
				),
				$("<tbody>").append(
					$("<tr>").append(
						$("<td>").text(this.name),
						$("<td>").text(this.requiredDrivers),
						$("<td>").text(this.maxDrivers),
						$("<td>").text(this.laps),
						$("<td>").text(this.allowedCars),
						$("<td>").text(this.upgradesAllowed),
						$("<td>").text(this.betAmount),
						$("<td>").text(this.startTime),
						$("<td>").text(this.password || ""),
						$("<td>").text(this.trackName)
					)
				)
			);
		const style = $("<style>").text(`
			.kw-preset-table {
				border-collapse: collapse;
				width: 100%;
			}

			.kw-preset-table th, .kw-preset-table td {
				border: 1px solid black !important;
				padding: 0.25rem !important;
				text-align: center;
				font-family: monospace;
				color: var(--autocomplete-color) !important;
			}
			`);
		table.prepend(style);
		return table;
	}

	/** @type {RacePreset[]} */
	static DEFAULTS = [
		new RacePreset({
			name: "Quick Industrial",
			laps: 1,
			trackName: "Industrial",
		}),
		new RacePreset({
			name: "1hr Start - Docks",
			maxDrivers: 100,
			trackName: "Docks",
			laps: 100,
			startTime: 60,
		}),
	];

	/** @returns {RacePreset[]} */
	static loadAll() {
		const presets = Utils.getFromStorage("kw.customRacePresets.presets");
		if (!presets) {
			Utils.setToStorage(
				"kw.customRacePresets.presets",
				RacePreset.DEFAULTS
			);
			return RacePreset.DEFAULTS;
		} else if (!Array.isArray(presets)) {
			const shouldClear = confirm(
				"Custom Race Presets is corrupted. Restore it to default?"
			);
			if (shouldClear)
				Utils.setToStorage(
					"kw.customRacePresets.presets",
					RacePreset.DEFAULTS
				);
			return RacePreset.DEFAULTS;
		} else {
			return presets.map((preset) => new RacePreset(preset));
		}
	}

	/**
	 *
	 * @param {JQuery<HTMLFormElement>} $form
	 */
	static fromForm($form) {
		const form = $form[0];
		// Yes, I know this is a mess, but it's the only way to get the correct types
		const name = /** @type {HTMLInputElement} */ (
			/** @type {unknown} */ (form.title)
		).value;
		const requiredDrivers = form.minDrivers.value;
		const maxDrivers = form.maxDrivers.value;
		const laps = form.laps.value;
		const allowedCars = /** @type {(keyof Constants.CARS_CLASSES)[]} */ (
			Object.keys(Constants.CARS_CLASSES)
		).find(
			(key) =>
				Constants.CARS_CLASSES[key] === Number(form.carsAllowed.value)
		);
		const upgradesAllowed = form.carsTypeAllowed.value === "1";
		const betAmount = form.betAmount.value;
		const startTime = form.waitTime.value;
		const password = form.passcode_temp.value;
		const trackName = /** @type {(keyof Constants.TRACKS)[]} */ (
			Object.keys(Constants.TRACKS)
		).find((key) => Constants.TRACKS[key] === Number(form.trackID.value));
		if (!trackName) throw new Error("Could not find track name");
		return new RacePreset({
			name,
			requiredDrivers,
			maxDrivers,
			laps,
			allowedCars,
			upgradesAllowed,
			betAmount,
			startTime,
			password,
			trackName,
		});
	}

	static customRaceRequest() {
		const params = new URLSearchParams({
			sid: "racing",
			tab: "customrace",
			section: "createCustomRace",
			rfcv: Utils.rfcv,
		});
		const url = `https://www.torn.com/loader.php?${params.toString()}`;
		return new Request(url, {
			method: "GET",
			headers: { "X-Requested-With": "XMLHttpRequest" },
		});
	}
}

/**
 * @callback GeneratePresetBtn
 * @param {string} presetName
 * @returns {JQuery<HTMLElement>}
 */

let listening = false;
async function main({ bypass = false } = {}) {
	// const activeTab = $("ul.categories > li.active > a").attr("tab-value");
	const activeTab = await Utils.waitForElement(
		"ul.categories > li.active > a"
	).then((el) => el.attr("tab-value"));
	if (!listening) {
		listening = true;
		$(document.body).on(
			"click",
			"ul.categories > li:has(a[tab-value=customrace])",
			() => main({ bypass: true })
		);
	}
	if (activeTab !== "customrace" && !bypass)
		return console.debug("Not on customrace tab, exiting...");

	const presets = RacePreset.loadAll();
	const tornStartRaceBtn = await Utils.waitForElement(
		"div.start-race > div > div.btn-wrap"
	);
	/** @type {GeneratePresetBtn} */
	const generatePresetBtn = (presetName) => {
		const cloned = tornStartRaceBtn.clone();
		cloned.attr("data-kw-preset", presetName);
		cloned.css("filter", "sepia(1)");
		const link = cloned.find("a");
		link.text(presetName);
		link.removeClass("btn-action-tab");
		link.removeAttr("href");
		tornStartRaceBtn.parent().append(cloned);
		return cloned;
	};
	presets.forEach((preset) => {
		const btn = generatePresetBtn(preset.name);
		const modal = Utils.createModal(
			`kw-modal-${preset.name}`,
			$("<div>")
				.css({ maxWidth: "100%", overflowX: "auto" })
				.append(preset.toTable()),
			$("<div>")
				.css({
					display: "flex",
					justifyContent: "space-around",
					marginTop: "1rem",
				})
				.append(
					$("<button>")
						.text("Car Selection")
						.addClass("btn torn-btn")
						.on("click", async () => {
							const response = await fetch(
								preset.toCarSelectorRequest()
							);
							if (!response.ok)
								return console.error(response.statusText);
							const data = await response.text();
							modal[0].close();
							$(
								"div#racingMainContainer > div.racing-main-wrap > div#racingAdditionalContainer"
							).html(data);
						}),
					$("<button>")
						.text("Auto Join")
						.addClass("btn torn-btn")
						.on("click", async () => {
							const response = await fetch(
								preset.toFinalRequest()
							);
							if (!response.ok)
								return console.error(response.statusText);
							const data = await response.text();
							modal[0].close();
							$(
								"div#racingMainContainer > div.racing-main-wrap > div#racingAdditionalContainer"
							).html(data);
						}),
					$("<button>")
						.text("Remove")
						.addClass("btn torn-btn")
						.css("filter", "sepia(1) hue-rotate(315deg)")
						.on("click", () => {
							const shouldRemove = confirm(
								`Are you sure you want to remove the preset: ${preset.name}?`
							);
							if (shouldRemove) {
								const index = presets.findIndex(
									(p) => p.name === preset.name
								);
								if (index === -1) return;
								presets.splice(index, 1);
								Utils.setToStorage(
									"kw.customRacePresets.presets",
									presets
								);
								modal[0].close();
								window.open(
									"?sid=racing&tab=customrace",
									"_self"
								);
							}
						})
				)
		);
		btn.on("click", (e) => {
			e.preventDefault();
			modal[0].showModal();
		});
	});
	const newPresetButton = generatePresetBtn("Add new preset");
	newPresetButton.css("filter", "sepia(1) hue-rotate(90deg)");
	newPresetButton.on("click", async (e) => {
		e.preventDefault();
		const response = await fetch(RacePreset.customRaceRequest());
		const $html = await response.text().then((html) => $(html));
		const existingSubmit = $html.find(
			"input[type=submit][name=createCustomRace]"
		);
		existingSubmit
			.parent()
			.append(
				$("<button>", {
					text: "Create new preset",
					class: existingSubmit.attr("class"),
					style: "filter: sepia(1) hue-rotate(90deg)",
				})
			)
			.on("click", (e) => {
				e.preventDefault();
				const form = $html.find("form");
				presets.push(RacePreset.fromForm(form));
				Utils.setToStorage("kw.customRacePresets.presets", presets);
				window.open("?sid=racing&tab=customrace", "_self");
			});
		existingSubmit.remove();
		$(
			"div#racingMainContainer > div.racing-main-wrap > div#racingAdditionalContainer"
		).replaceWith($html);
	});
}

main();
