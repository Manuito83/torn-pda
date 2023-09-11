// Project imports:
import 'package:torn_pda/models/userscript_model.dart';

class ScriptsExamples {
  static List<UserScriptModel> getScriptsExamples() {
    final exampleList = <UserScriptModel>[];
    exampleList.add(_bazaarExample());
    exampleList.add(_racingPresetsExample());
    exampleList.add(_specialGymRatios());
    exampleList.add(_companyStocksOrderExample());
    exampleList.add(_companyActivity());
    exampleList.add(_hospitalFilters());
    return exampleList;
  }

  static List<String?> getUrls(String source) {
    final urls = <String?>[];
    final regex = RegExp(r'(@match+\s+)(.*)');
    final matches = regex.allMatches(source);
    if (matches.isNotEmpty) {
      for (final Match match in matches) {
        try {
          urls.add(match.group(2));
        } catch (e) {
          //
        }
      }
    }
    return urls;
  }

  static UserScriptModel _bazaarExample() {
    const source = r"""
// ==UserScript==
// @name         Bazaar Auto Price
// @namespace    tos
// @version      0.8 (updated by Manuito)
// @description  Auto set bazaar prices on money input field click.
// @author       tos, Lugburz
// @match        https://www.torn.com/bazaar.php
// @connect      api.torn.com
// ==/UserScript==

let apikey = '###PDA-APIKEY###';

let torn_api = async (args) => {
  const a = args.split('.')
  if (a.length!==3) throw(`Bad argument in torn_api(args, key): ${args}`)
  return new Promise((resolve, reject) => {
    let streamURL = `https://api.torn.com/${a[0]}/${a[1]}?selections=${a[2]}&key=${apikey}`;
    // Reject if key isn't set.
    $.getJSON(streamURL)
      .done((result) => {
        if (result.error != undefined){
          reject(result.error);
        } else {
          resolve(result);
        }
      })
      .fail(function( jqxhr, textStatus, error ) {
        var err = textStatus + ', ' + error;
        reject(err);
      });
  });
}

var event = new Event('keyup');
var APIERROR = false;

async function lmp(itemID) {
  if(APIERROR === true) return 'API key error'
  const prices = await torn_api(`market.${itemID}.bazaar`)
  if (prices.error) {APIERROR = true; return 'API key error'}
  const lowest_market_price = prices['bazaar'][0].cost
  return lowest_market_price - 5
}

// HACK to simulate input value change
// https://github.com/facebook/react/issues/11488#issuecomment-347775628
function reactInputHack(inputjq, value) {
  // get js object from jquery
  const input = $(inputjq).get(0);

  let lastValue = 0;
  input.value = value;
  let event = new Event('input', { bubbles: true });
  // hack React15
  event.simulated = true;
  // hack React16
  let tracker = input._valueTracker;
  if (tracker) {
    tracker.setValue(lastValue);
  }
  input.dispatchEvent(event);
}

function addOneFocusHandler(elem, itemID) {
  $(elem).on('focus', function(e) {
    this.value = '';
    if (this.value === '') {
      lmp(itemID).then((price) => {
        //this.value = price;
        reactInputHack(this, price);
        this.dispatchEvent(event);
        if(price) $(elem).off('focus');
      });
    }
  });
}

let bazaarObserver = new MutationObserver((mutations) => {
  for (const mutation of mutations) {
  for (const node of mutation.addedNodes) {
    if (typeof node.classList !== 'undefined' && node.classList) {
      let input = $(node).find('[class^=priceInput]');
      if ($(input).size() > 0) {
        // Manage items
        $(input).each(function() {
          const img = $(this).parent().parent().find('img');
          const itemID = $(img).attr('src').split('items/')[1].split('/medium')[0];
          addOneFocusHandler($(this), itemID);
        });
      } else {
        // Add items
        input = node.querySelector('.input-money[type=text]');
        const img = node.querySelector('img');
        if (input && img) {
          const itemID = img.src.split('items/')[1].split('/medium')[0].split('/large.png')[0];
          addOneFocusHandler($(input), itemID);

          // input amount
          const input_amount = $(node).find('div.amount').find('.clear-all[type=text]');
          const inv_amount = $(node).find('div.name-wrap').find('span.t-hide').text();
          const amount = inv_amount == '' ? 1 : inv_amount.replace('x', '').trim();
          $(input_amount).on('focus', function() {
            reactInputHack(input_amount, amount);
          });
        }
      }
    }
  }
  }
});

// Sleep and wait for elements to load
async function sleep(ms) {
  return new Promise(resolve => setTimeout(resolve, ms));
}

var waitForElementsAndRun = setInterval(() => {
  if(document.querySelector("#bazaarRoot") !== null) {
    clearInterval(waitForElementsAndRun);
    // Main logic    
    var wrapper = document.querySelector('#bazaarRoot');
    try {
      bazaarObserver.observe(wrapper, { subtree: true, childList: true });
    } catch (e) {
      // wrapper not found
    }
  }
}, 300);
""";

    return UserScriptModel(
      // IMPORTANT: increment version by 1
      version: 3,

      enabled: true,
      urls: getUrls(source),
      name: "Bazaar Auto Price",
      exampleCode: 1,
      edited: false,
      time: UserScriptTime.start,
      source: source,
    );
  }

  static UserScriptModel _racingPresetsExample() {
    const source = r"""
// ==UserScript==
// @name         Torn Custom Race Presets
// @namespace    https://greasyfork.org/en/scripts/393632-torn-custom-race-presets
// @version      0.2.1 - Torn PDA adaptation v2 [Manuito]
// @description  Make it easier and faster to make custom races - Extended from Xiphias's
// @author       Cryosis7 [926640]
// @match        www.torn.com/loader.php?sid=racing
// ==/UserScript==

/**
 * Modify the presets as you see fit, you can add and remove presets,
 * or remove individual fields within the preset to only use the fields you care about.
 * 
 * TEMPLATE
 * {
		name: "Appears as the button name and the public name of the race",
		maxDrivers: 6,
		trackName: "Industrial",
		numberOfLaps: 1,
		upgradesAllowed: true,
		betAmount: 0,
		waitTime: 1,
		password: "",
	},
 * 
 */

var presets = [{
		name: "Quick Industrial",
		maxDrivers: 2,
		trackName: "Industrial",
		numberOfLaps: 1,
		upgradesAllowed: true,
		betAmount: 0,
		waitTime: 1,
		password: "",
	},
	{
		name: "1hr Start - Docks",
		maxDrivers: 100,
		trackName: "Docks",
		numberOfLaps: 100,
		waitTime: 60,
		password: "",
	},
];

(function() {
	'use strict';
	scrubPresets();
	$('body').ajaxComplete(function(e, xhr, settings) {
		var createCustomRaceSection = "section=createCustomRace";
		var url = settings.url;
		if (url.indexOf(createCustomRaceSection) >= 0) {
			scrubPresets();
			drawPresetBar();
		}
	});
})();

function fillPreset(index) {
	let race = presets[index];

	if ("name" in race) $('.race-wrap div.input-wrap input').attr('value', race.name);
	if ("maxDrivers" in race) $('.drivers-max-wrap div.input-wrap input').attr('value', race.maxDrivers);
	if ("numberOfLaps" in race) $('.laps-wrap > .input-wrap > input').attr('value', race.numberOfLaps);
	if ("betAmount" in race) $('.bet-wrap > .input-wrap > input').attr('value', race.betAmount);
	if ("waitTime" in race) $('.time-wrap > .input-wrap > input').attr('value', race.waitTime);
	if ("password" in race) $('.password-wrap > .input-wrap > input').attr('value', race.password);

	if ("trackName" in race) {
		$('#select-racing-track').selectmenu();
		$('#select-racing-track-menu > li:contains(' + race.trackName + ')').mouseup();
	}
	if ("upgradesAllowed" in race) {
		$('#select-allow-upgrades').selectmenu();
		$('#select-allow-upgrades-menu > li:contains(' + race.upgradesAllowedString + ')').mouseup();
	}
}

function scrubPresets() {
	presets.forEach(x => {
		if ("name" in x && x.name.length > 25) x.name = x.name.substring(0, 26);
		if ("maxDrivers" in x) x.maxDrivers = (x.maxDrivers > 100) ? 100 : (x.maxDrivers < 2) ? 2 : x.maxDrivers;
		if ("trackName" in x) x.trackName.toLowerCase().split(' ').map(x => x.charAt(0).toUpperCase() + x.substring(1)).join(' ');
		if ("numberOfLaps" in x) x.numberOfLaps = (x.numberOfLaps > 100) ? 100 : (x.numberOfLaps < 1) ? 1 : x.numberOfLaps;
		if ("upgradesAllowed" in x) x.upgradesAllowedString = x.upgradesAllowed ? "Allow upgrades" : "Stock cars only";
		if ("betAmount" in x) x.betAmount = (x.betAmount > 10000000) ? 10000000 : (x.betAmount < 0) ? 0 : x.betAmount;
		if ("waitTime" in x) x.waitTime = (x.waitTime > 2880) ? 2880 : (x.waitTime < 1) ? 1 : x.waitTime;
		if ("password" in x && x.password.length > 25) x.password = x.password.substring(0, 26);
	})
}

function drawPresetBar() {
	// Get rid of box before re-adding, which is an issue for iOS
	for (let box of document.querySelectorAll('.filter-container.m-top10')) {
		box.remove();
	}
	
	let filterBar = $(`
  <div class="filter-container m-top10">
	<div class="title-gray top-round">Race Presets</div>

	<div class="cont-gray p10 bottom-round">
		${presets.map((element, index) => `<button class="torn-btn preset-btn" style="margin:0 10px 10px 0">${("name" in element) ? element.name : "Preset " + (+index + 1)}</button>`)}
	</div>
  </div>`);

	$('#racingAdditionalContainer > .form-custom-wrap').before(filterBar);
	$('.preset-btn').each((index, element) => element.onclick = function() {fillPreset(index)});
}""";

    return UserScriptModel(
      // IMPORTANT: increment version by 1
      version: 3,

      enabled: true,
      urls: getUrls(source),
      name: "Custom Race Presets",
      exampleCode: 3,
      edited: false,
      source: source,
    );
  }

  static UserScriptModel _specialGymRatios() {
    const source = r"""
// ==UserScript==
// @name         Custom Gym Ratios
// @version      2.4 (updated by Manuito)
// @description  Monitors battle stat ratios and provides warnings if they approach levels that would preclude access to special gyms
// @author       RGiskard [1953860], assistance by Xiphias [187717] - Torn PDA adaptation v1 [Manuito]
// @match      	 torn.com/gym.php
// ==/UserScript==

function loadGym() {
	// Maximum amount below the stat limit another stat can be before we start warning the player.
	var statSafeDistance = localStorage.statSafeDistance;
	if (statSafeDistance === null) {
		statSafeDistance = 1000000;
	}

	var cleanNumber = function(a) {
		return Number(a.replace(/[$,]/g, "").trim());
	};

	/**
	 * Formats a number into an abbreviated string with an appropriate trailing descriptive unit
	 * up to 't' for trillion.
	 * @param {float} number the number to be formatted
	 * @param {int} maxFractionDigits the maximum number of fractional digits to display
	 * @returns a string representing the number, abbreviated if appropriate
	 **/
	var FormatAbbreviatedNumber = function(number, maxFractionDigits) {
		var abbreviations = [];
		abbreviations[0] = '';
		abbreviations[1] = 'k';
		abbreviations[2] = 'm';
		abbreviations[3] = 'b';
		abbreviations[4] = 't';

		var outputNumber = number;
		var abbreviationIndex = 0;
		for (; outputNumber >= 1000 && abbreviationIndex < abbreviations.length; ++abbreviationIndex) {
			outputNumber = outputNumber / 1000;
		}

		return outputNumber.toLocaleString('EN', { maximumFractionDigits : maxFractionDigits }) + abbreviations[abbreviationIndex];
	};

	var getStats = function($doc) {
		var ReplaceStatValueAndReturnCleanNumber = function(elementId) {
			var $statTotalElement = $doc.find('#' + elementId);
			if ($statTotalElement.size() === 0) throw 'No element found with id "' + elementId + '".';
			var numericalValue = cleanNumber($statTotalElement.text());
			return numericalValue;
		};
		$doc = $($doc || document);
		return {
			strength: ReplaceStatValueAndReturnCleanNumber('strength-val'),
			defense: ReplaceStatValueAndReturnCleanNumber('defense-val'),
			speed: ReplaceStatValueAndReturnCleanNumber('speed-val'),
			dexterity: ReplaceStatValueAndReturnCleanNumber('dexterity-val'),
		};
	};

	var noBuildKeyValue = {value: 'none', text: 'No specialty gyms'};
	var defenseDexterityGymKeyValue = {value: 'balboas', text: 'Defense and dexterity specialist',
									   stat1: 'defense', stat2: 'dexterity', secondarystat1: 'strength', secondarystat2: 'speed'};
	var strengthSpeedGymKeyValue = {value: 'frontline', text: 'Strength and speed specialist',
									stat1: 'strength', stat2: 'speed', secondarystat1: 'defense', secondarystat2: 'dexterity'};
	var strengthComboGymKeyValue = {value: 'frontlinegym3000', text: 'Strength combo specialist (Baldr\'s Ratio)', stat: 'strength', combogym: strengthSpeedGymKeyValue};
	var defenseComboGymKeyValue = {value: 'balboasisoyamas', text: 'Defense combo specialist (Baldr\'s Ratio)', stat: 'defense', combogym: defenseDexterityGymKeyValue};
	var speedComboGymKeyValue = {value: 'frontlinetotalrebound', text: 'Speed combo specialist (Baldr\'s Ratio)', stat: 'speed', combogym: strengthSpeedGymKeyValue};
	var dexterityComboGymKeyValue = {value: 'balboaselites', text: 'Dexterity combo specialist (Baldr\'s Ratio)', stat: 'dexterity', combogym: defenseDexterityGymKeyValue};
	var strengthGymKeyValue = {value: 'gym3000', text: 'Strength specialist (Hank\'s Ratio)', stat: 'strength', combogym: defenseDexterityGymKeyValue};
	var defenseGymKeyValue = {value: 'isoyamas', text: 'Defense specialist (Hank\'s Ratio)', stat: 'defense', combogym: strengthSpeedGymKeyValue};
	var speedGymKeyValue = {value: 'totalrebound', text: 'Speed specialist (Hank\'s Ratio)', stat: 'speed', combogym: defenseDexterityGymKeyValue};
	var dexterityGymKeyValue = {value: 'elites', text: 'Dexterity specialist (Hank\'s Ratio)', stat: 'dexterity', combogym: strengthSpeedGymKeyValue};
	
	function GetStoredGymKeyValuePair() {
		if (localStorage.specialistGymType == defenseDexterityGymKeyValue.value) return defenseDexterityGymKeyValue;
		if (localStorage.specialistGymType == strengthSpeedGymKeyValue.value) return strengthSpeedGymKeyValue;
		if (localStorage.specialistGymType == strengthComboGymKeyValue.value) return strengthComboGymKeyValue;
		if (localStorage.specialistGymType == defenseComboGymKeyValue.value) return defenseComboGymKeyValue;
		if (localStorage.specialistGymType == speedComboGymKeyValue.value) return speedComboGymKeyValue;
		if (localStorage.specialistGymType == dexterityComboGymKeyValue.value) return dexterityComboGymKeyValue;
		if (localStorage.specialistGymType == strengthGymKeyValue.value) return strengthGymKeyValue;
		if (localStorage.specialistGymType == defenseGymKeyValue.value) return defenseGymKeyValue;
		if (localStorage.specialistGymType == speedGymKeyValue.value) return speedGymKeyValue;
		if (localStorage.specialistGymType == dexterityGymKeyValue.value) return dexterityGymKeyValue;
		return noBuildKeyValue;
	}

	// Get rid of box before re-adding, which is an issue for iOS
	for (let box of document.querySelectorAll('.hank-box')) {
		box.remove();
	}

	var $hanksRatioDiv = $('<div></div>', {'class': 'hank-box'});
	var $titleDiv = $('<div>', {'class': 'title-black top-round', 'aria-level': '5', 'text': 'Special Gym Ratios'}).css('margin-top', '10px');
	$hanksRatioDiv.append($titleDiv);
	var $bottomDiv = $('<div class="bottom-round gym-box cont-gray p10"></div>');
	$bottomDiv.append($('<p class="sub-title">Select desired specialist build:</p>'));
	var $specialistGymBuild = $('<select>', {'class': 'vinkuun-enemeyDifficulty'}).css('margin-top', '10px').on('change', function() {
		localStorage.specialistGymType = $specialistGymBuild.val();
	});
	
	$specialistGymBuild.append($('<option>', noBuildKeyValue));
	$specialistGymBuild.append($('<option>', defenseDexterityGymKeyValue));
	$specialistGymBuild.append($('<option>', strengthSpeedGymKeyValue));
	$specialistGymBuild.append($('<option>', strengthComboGymKeyValue));
	$specialistGymBuild.append($('<option>', defenseComboGymKeyValue));
	$specialistGymBuild.append($('<option>', speedComboGymKeyValue));
	$specialistGymBuild.append($('<option>', dexterityComboGymKeyValue));
	$specialistGymBuild.append($('<option>', strengthGymKeyValue));
	$specialistGymBuild.append($('<option>', defenseGymKeyValue));
	$specialistGymBuild.append($('<option>', speedGymKeyValue));
	$specialistGymBuild.append($('<option>', dexterityGymKeyValue));
	localStorage.specialistGymType = GetStoredGymKeyValuePair().value;  // In case there is bad data, replace it.
	$specialistGymBuild.val(GetStoredGymKeyValuePair().value);
	$bottomDiv.append($specialistGymBuild);
	$hanksRatioDiv.append($bottomDiv);
	$('#gymroot').append($hanksRatioDiv);

	var oldTotal = 0;
	var oldBuild = '';
	setInterval(function() {
		var stats = getStats();
		var total = 0;
		var highestSecondaryStat = 0;
		for (var stat in stats) {
			total += stats[stat];
			if (GetStoredGymKeyValuePair().stat && GetStoredGymKeyValuePair().stat != stat && stats[stat] > highestSecondaryStat) {
				highestSecondaryStat = stats[stat];
			}
		}
		var currentBuild = $specialistGymBuild.val();
		
		if (oldTotal == total && oldBuild == currentBuild && $('.gymstatus').size() != 0) {
			return;
		}
		
		var $statContainers = $('[class^="gymContent__"], [class*=" gymContent__"]').find('li');

		if (currentBuild == noBuildKeyValue.value) {
			// Clear the training info in case it exists.
			$statContainers.each(function(index, element) {
				var $statInfoDiv = $(element).find('[class^="description__"], [class*=" description__"]');
				var $insertedElement = $statInfoDiv.find('.gymstatus');
				$insertedElement.remove();
			});
			return;
		}
		
		var isComboGymOnlyRatio = (
			localStorage.specialistGymType == defenseDexterityGymKeyValue.value ||
			localStorage.specialistGymType == strengthSpeedGymKeyValue.value);
		var isComboGymCombinedRatio = (
			localStorage.specialistGymType == strengthComboGymKeyValue.value ||
			localStorage.specialistGymType == defenseComboGymKeyValue.value ||
			localStorage.specialistGymType == speedComboGymKeyValue.value ||
			localStorage.specialistGymType == dexterityComboGymKeyValue.value);
		var isSingleGymRatio = (
			localStorage.specialistGymType == strengthGymKeyValue.value ||
			localStorage.specialistGymType == defenseGymKeyValue.value ||
			localStorage.specialistGymType == speedGymKeyValue.value ||
			localStorage.specialistGymType == dexterityGymKeyValue.value);

		// The combined total of the primary stats must be 25% higher than the total of the secondary stats.
		var minPrimaryComboSum = 0;    // The minimum amount the combined primary stats must be to unlock the gym based on the secondary stat sum.
		var maxSecondaryComboSum = 0;  // The maximum amount the combined secondary stats must be to unlock the gym based on the primary stat sum.
		// The primary stat needs to be 25% higher than the second highest stat.
		var minPrimaryStat = 0;
		var maxSecondaryStat = 0;
		var comboGymKeyValuePair = noBuildKeyValue;
		var primaryGymKeyValuePair = noBuildKeyValue;
		if (isComboGymOnlyRatio) {
			comboGymKeyValuePair = GetStoredGymKeyValuePair();
		} else if (isComboGymCombinedRatio || isSingleGymRatio) {
			primaryGymKeyValuePair = GetStoredGymKeyValuePair();
			comboGymKeyValuePair = primaryGymKeyValuePair.combogym;
			minPrimaryStat = highestSecondaryStat * 1.25;
			maxSecondaryStat = stats[primaryGymKeyValuePair.stat] / 1.25;
		} else {
			console.debug('Somehow attempted to calculate stat requirements for invalid gym: ' + GetStoredGymKeyValuePair());
			return;
		}
		minPrimaryComboSum = (stats[comboGymKeyValuePair.secondarystat1] + stats[comboGymKeyValuePair.secondarystat2]) * 1.25;
		maxSecondaryComboSum = (stats[comboGymKeyValuePair.stat1] + stats[comboGymKeyValuePair.stat2]) / 1.25;
		
		var distanceFromComboGymMin = minPrimaryComboSum - stats[comboGymKeyValuePair.stat1] - stats[comboGymKeyValuePair.stat2];
		var distanceToComboGymMax = maxSecondaryComboSum - stats[comboGymKeyValuePair.secondarystat1] - stats[comboGymKeyValuePair.secondarystat2];

		$statContainers.each(function(index, element) {
			var $element = $(element);
			var title = $element.find('[class^="title__"], [class*=" title__"]');
			var stat = $element.attr('zStat');
			
			if (!stat) {
				stat = title.text().toLowerCase();

				// Change stat for mobile stat names (Torn PDA)
				if (stat == "str") stat = "strength";
				if (stat == "dex") stat = "dexterity";
				if (stat == "spd") stat = "speed";
				if (stat == "def") stat = "defense";
				
				$element.attr('zStat', stat);
			}
			if (stats[stat]) {
				var gymStatus;
				var statIdentifierString;
				if (isComboGymOnlyRatio) {
					if (stat == comboGymKeyValuePair.stat1 || stat == comboGymKeyValuePair.stat2) {
						statIdentifierString = GetStatAbbreviation(comboGymKeyValuePair.stat1).capitalizeFirstLetter() +
							' + ' + GetStatAbbreviation(comboGymKeyValuePair.stat2);
						if (distanceFromComboGymMin > 0) {
							gymStatus = '<span class="gymstatus t-red bold">' + statIdentifierString + ' is ' + FormatAbbreviatedNumber(distanceFromComboGymMin, 1) + ' too low!</span>';
						} else if (distanceFromComboGymMin < statSafeDistance) {
							gymStatus = '<span class="gymstatus t-red bold">' + statIdentifierString + ' is ' + FormatAbbreviatedNumber(-distanceFromComboGymMin, 1) + ' above the limit.</span>';
						} else {
							gymStatus = '<span class="gymstatus t-green">' + statIdentifierString + ' is ' + FormatAbbreviatedNumber(-distanceFromComboGymMin, 1) + ' above the limit.</span>';
						}
					} else {
						statIdentifierString = GetStatAbbreviation(comboGymKeyValuePair.secondarystat1).capitalizeFirstLetter() +
							' + ' + GetStatAbbreviation(comboGymKeyValuePair.secondarystat2);
						if (distanceToComboGymMax < 0) {
							gymStatus = '<span class="gymstatus t-red bold">' + statIdentifierString + ' is ' + FormatAbbreviatedNumber(-distanceToComboGymMax, 1) + ' too high!</span>';
						} else if (distanceToComboGymMax < statSafeDistance) {
							gymStatus = '<span class="gymstatus t-red bold">' + statIdentifierString + ' is ' + FormatAbbreviatedNumber(distanceToComboGymMax, 1) + ' below the limit.</span>';
						} else {
							gymStatus = '<span class="gymstatus t-green">' + statIdentifierString + ' is ' + FormatAbbreviatedNumber(distanceToComboGymMax, 1) + ' below the limit.</span>';
						}
					}
				} else {
					var distanceFromSpecialistGymMin = minPrimaryStat - stats[stat];
					var distanceToSpecialistGymMax = maxSecondaryStat - stats[stat];
					
					var distanceToMax = 0;
					statIdentifierString = stat.capitalizeFirstLetter();
					if (stat == primaryGymKeyValuePair.stat) {
						if (distanceFromSpecialistGymMin <= 0) {
							if (isSingleGymRatio) {
								// Specialist stat for Hank's Gym Ratio is never one of the primary combo stats.
								// Only set the identifier if we don't already know this stat is too low to unlock its own specific gym.
								distanceToMax = distanceToComboGymMax;
								if (distanceToMax < 0) {
									statIdentifierString = GetStatAbbreviation(comboGymKeyValuePair.secondarystat1).capitalizeFirstLetter() +
										' + ' + GetStatAbbreviation(comboGymKeyValuePair.secondarystat2);
								}
							} else {
								// Specialist stat IS the combo stat; we only care to show how it's doing in relation to the specialist gym.
								distanceToMax = distanceFromSpecialistGymMin;
							}
						}
					} else if (stat == comboGymKeyValuePair.stat1 || stat == comboGymKeyValuePair.stat2) {
						// We don't have to worry about this stat going too high for the combo gym.
						distanceToMax = distanceToSpecialistGymMax;
					} else {
						// This stat is neither the primary stat nor a combo gym stat, so it's limited by both.
						distanceToMax = Math.min(distanceToSpecialistGymMax, distanceToComboGymMax);
						if (distanceToComboGymMax < distanceToSpecialistGymMax && distanceToMax < 0) {
							statIdentifierString = GetStatAbbreviation(comboGymKeyValuePair.secondarystat1).capitalizeFirstLetter() +
								' + ' + GetStatAbbreviation(comboGymKeyValuePair.secondarystat2);
						}
					}
					
					if (stat == primaryGymKeyValuePair.stat) {
						console.debug(stat + ' distanceFromSpecialistGymMin: ' + distanceFromSpecialistGymMin);
						console.debug(stat + ' distanceToComboGymMax: ' + distanceToComboGymMax);
					} else if (stat == comboGymKeyValuePair.stat1 || stat == comboGymKeyValuePair.stat2) {
						console.debug(stat + ' distanceToSpecialistGymMax: ' + distanceToSpecialistGymMax);
						console.debug(stat + ' distanceFromComboGymMin: ' + distanceFromComboGymMin);
					} else {
						console.debug(stat + ' distanceToSpecialistGymMax: ' + distanceToSpecialistGymMax);
						console.debug(stat + ' distanceToComboGymMax: ' + distanceToComboGymMax);
					}
					console.debug(stat + ' distanceToMax: ' + distanceToMax);
					
					if (stat == primaryGymKeyValuePair.stat && distanceFromSpecialistGymMin > 0) {
						gymStatus = '<span class="gymstatus t-red bold">' + statIdentifierString + ' is ' + FormatAbbreviatedNumber(distanceFromSpecialistGymMin, 1) + ' too low!</span>';
					} else if (distanceToMax < 0) {
						if (stat == primaryGymKeyValuePair.stat && isComboGymCombinedRatio) {
							gymStatus = '<span class="gymstatus t-green">' + statIdentifierString + ' is ' + FormatAbbreviatedNumber(-distanceToMax, 1) + ' above the limit.</span>';
						} else {
							gymStatus = '<span class="gymstatus t-red bold">' + statIdentifierString + ' is ' + FormatAbbreviatedNumber(-distanceToMax, 1) + ' too high!</span>';
						}
					} else if (distanceToMax < statSafeDistance) {
						gymStatus = '<span class="gymstatus t-red bold">' + statIdentifierString + ' is ' + FormatAbbreviatedNumber(distanceToMax, 1) + ' below the limit.</span>';
					} else {
						gymStatus = '<span class="gymstatus t-green">' + statIdentifierString + ' is ' + FormatAbbreviatedNumber(distanceToMax, 1) + ' below the limit.</span>';
					}
				}

				var $statInfoDiv = $element.find('[class^="description__"], [class*=" description__"]');
				var $insertedElement = $statInfoDiv.find('.gymstatus');
				$insertedElement.remove();
				$statInfoDiv.append(gymStatus);
			}
		});
		oldTotal = total;
		oldBuild = currentBuild;
		console.debug("Stat spread updated!");
	}, 400);

	String.prototype.capitalizeFirstLetter = function() {
		return this.charAt(0).toUpperCase() + this.slice(1);
	};

	function GetStatAbbreviation(statString) {
		if (statString == 'strength') {
			return 'str';
		} else if (statString == 'defense') {
			return 'def';
		} else if (statString == 'speed') {
			return 'spd';
		} else if (statString == 'dexterity') {
			return 'dex';
		}
		return statString;
	}
}


let waitForElementsAndRun = setInterval(() => {
  if (document.querySelector("#gymroot")) {
    loadGym();
    return clearInterval(waitForElementsAndRun);
  }
}, 300);

 """;

    return UserScriptModel(
      // IMPORTANT: increment version by 1
      version: 2,

      enabled: true,
      urls: getUrls(source),
      name: "Custom Gym Ratios",
      exampleCode: 4,
      edited: false,
      time: UserScriptTime.start,
      source: source,
    );
  }

  static UserScriptModel _companyStocksOrderExample() {
    const source = r"""
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
}""";

    return UserScriptModel(
      // IMPORTANT: increment version by 1
      version: 2,

      enabled: false,
      urls: getUrls(source),
      name: "Company Stocks Order",
      exampleCode: 5,
      edited: false,
      source: source,
    );
  }

  static UserScriptModel _companyActivity() {
    const source = r"""
// ==UserScript==
// @name         Company Activity for Torn PDA
// @namespace    TornExtensions
// @version      1.2 (updated by Manuito)
// @description  Shows the activity of employees.
// @author       Twenu [XID 2659526]
// @match        https://www.torn.com/companies.php*
// @grant        none
// ==/UserScript==
  
(function() {
    //'use strict';
    let APIKey = '###PDA-APIKEY###';
    let targetNode = document.getElementById('employees');
    let config = { childList: true };
    
	function removeElementsByClass(className){
		const elements = document.getElementsByClassName(className);
		while(elements.length > 0){
			elements[0].parentNode.removeChild(elements[0]);
		}
	}
		
	function checkEmployees () {
        // Make sure to remove previous 'Active' lines (needed for iOS)
		removeElementsByClass('activeEmployee');
		
		$("a.user.name").each(function() {
		
			if($(this).closest("li").attr("data-user").length > 0 && $(this).next("img")) {
                
				let uID = $(this).closest("li").attr("data-user");
                let API = `https://api.torn.com/user/${uID}?selections=profile&key=${APIKey}`;
                fetch(API)
                  .then((res) => res.json())
                  .then((res) => {            

					$($($(this).parent().parent().parent()).find(".acc-body")).find(".stats").append('<span tabindex="0" class="span-cont t-first activeEmployee" aria-label="Active: "' + res.last_action.relative + '"><span class="bold t-show">Active:</span> ' + res.last_action.relative + '</span><span class="t-hide">/</span>');
                    $($($(this).parent().parent().parent()).find(".acc-body")).find(".stats").append('<span tabindex="0" class="span-cont t-first activeEmployee" aria-label=" "><span class="bold t-show"></span></span> <span class="t-hide">/</span>');
                    let days = res.last_action.relative.split(" ");
                    
					if(days[1].includes("day"))
                        if(parseInt(days[0]) == 1)
                            $(this).parent().css("background-color", "orange");
                        else if(parseInt(days[0]) >= 2)
                            $(this).parent().css("background-color", "red");
                  });
            }
        });
    }
	
	var waitForElementsAndRun = setInterval(function () {
	  if(document.querySelector(".employee-effectiveness") !== null) {
		clearInterval(waitForElementsAndRun);
		// Main logic    
		var savedFound = document.querySelector(".pdaListener") !== null;
		if (!savedFound) {
			var save = document.querySelector(".content-wrapper");
			save.classList.add("pdaListener");
			checkEmployees();
		}
	  }
	}, 300);
})();
""";

    return UserScriptModel(
      // IMPORTANT: increment version by 1
      version: 4,

      enabled: false,
      urls: getUrls(source),
      name: "Company Activity",
      exampleCode: 6,
      edited: false,
      time: UserScriptTime.start,
      source: source,
    );
  }

  static UserScriptModel _hospitalFilters() {
    const source = r"""
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
  if (attributes.class && element.parentElement.classList.contains(attributes.class)) return true;
  if (attributes.id && element.parentElement.id === attributes.id) return true;
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
    if (document.getElementById("enable") === null && document.getElementById("disable") === null) {
	  window.infobox = document.createElement("div");
	  window.container = document.getElementsByClassName("content-wrapper")[0];
      var pager = document.getElementsByClassName("pagination-wrap")[0]
	  container.insertBefore(infobox, pager)
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
  if(document.querySelector(".user") !== null) {
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
  if (event.target.classList && !event.target.classList.contains("gallery-wrapper")
	    && hasParent(event.target, { class: "gallery-wrapper" })) {
	
    let checker = setInterval(() => {
      if (document.querySelector(".user")) {
        var savedFound = document.querySelector(".hospitalScriptEnabled") !== null;
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
}


""";

    return UserScriptModel(
      // IMPORTANT: increment version by 1
      version: 2,

      enabled: true,
      urls: getUrls(source),
      name: "Hospital Filters",
      exampleCode: 7,
      edited: false,
      time: UserScriptTime.start,
      source: source,
    );
  }
}
