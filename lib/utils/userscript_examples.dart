// Project imports:
import 'package:torn_pda/models/userscript_model.dart';

class ScriptsExamples {
  static List<UserScriptModel> getScriptsExamples() {
    var exampleList = <UserScriptModel>[];
    exampleList.add(_bazaarExample());
    exampleList.add(_playerFiltersExample());
    exampleList.add(_racingPresetsExample());
    exampleList.add(_specialGymRatios());
    exampleList.add(_companyStocksOrderExample());
    exampleList.add(_companyActivity());
    return exampleList;
  }

  static List<String> getUrls(String source) {
    var urls = <String>[];
    final regex = RegExp(r'(@match+\s+)(.*)');
    var matches = regex.allMatches(source);
    if (matches.length > 0) {
      for (Match match in matches) {
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
    var source = r"""// ==UserScript==
// @name         Bazaar Auto Price
// @namespace    tos
// @version      0.7.7
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

let wrapper = document.querySelector('#react-root');

try {
  bazaarObserver.observe(wrapper, { subtree: true, childList: true });
} catch (e) {
  // wrapper not found
}""";

    return UserScriptModel(
      // IMPORTANT: increment version by 1
      version: 1,

      enabled: true,
      urls: getUrls(source),
      name: "Bazaar Auto Price",
      exampleCode: 1,
      edited: false,
      source: source,
    );
  }

  static UserScriptModel _playerFiltersExample() {
    var source = r"""// ==UserScript==
// @name         TornCAT Faction Player Filters
// @namespace    torncat
// @version      1.2.3
// @description  This script adds player filters on various pages (see matches below).
// @author       Wingmanjd[2127679]
// @match        https://www.torn.com/factions.php*
// @match        https://www.torn.com/hospitalview.php*
// @match        https://www.torn.com/jailview.php*
// @match        https://www.torn.com/index.php?page=people*
// @match        https://www.torn.com/friendlist.php*
// @match        https://www.torn.com/blacklist.php*

// ==/UserScript==

'use strict';

let apikey = '###PDA-APIKEY###';
let tornPdaMode = false;

// Need to check if script is running within TornPDA app.
if (apikey.slice(-1) != '#') {
    // Script is running in TornPDA mode.
    tornPdaMode = true;
}


// Override the GM_addStyle function so it can be used within TornPDA.
let GM_addStyle = function(s)
{
    let style = document.createElement("style");
    style.type = "text/css";
    style.innerHTML = s;

    document.head.appendChild(style);
};

// Class declarations
/************************************** */
class PlayerIDQueue {
    constructor() {
        this.playerIDs = this.findPlayerIDs();
        this.queries = 0;
        this.start = new Date();
    }
    enqueue(el) {
        this.playerIDs.push(el);
    }
    dequeue() {
        return this.playerIDs.shift();
    }
    findPlayerIDs() {
        let users = $('.user.name');
        let players = users.toArray();
        let playerIDs = [];

        players.forEach(function(el){
            let regex = /(XID=)(\d*)/;
            let found = el.href.match(regex);
            let playerID = Number(found[0].slice(4));

            // Push to new array if not already present.
            if (playerIDs.indexOf(playerID) == -1){
                playerIDs.push(playerID);
            }
        });
        return playerIDs;
    }
    isEmpty() {
        return this.playerIDs.length == 0;
    }
    peek() {
        return !this.isEmpty() ? this.playerIDs[0] : undefined;
    }
    length() {
        return this.playerIDs.length;
    }
    requeue() {
        let element = this.peek();
        this.dequeue();
        this.enqueue(element);
    }
    clear() {
        if( !tornPdaMode && develCheck ) console.debug('API Cache Dump:', apiDataCache);
        this.playerIDs = [];
    }
}

// Global script variables:
/************************************** */

// Development flag.
let develCheck = false;
let localStorageLocation = 'torncat.factionFilters';

// Local cache for api data.
let apiDataCache = {};
var data = data || {};

// Player queue
let queue = new PlayerIDQueue();

// Torn API query limit, to prevent flood protection rejections.
let apiQueryLimit = 60;

// Calculated values of checkboxes;
var reviveCheck = false;
var attackCheck = false;
var offlineCheck = false;


// Main script.
/************************************** */
(function() {
    'use strict';

    console.log('Faction Player Filters (FPF) started');
    // Load localStorage;
    loadData();
    // Save data back to localStorage;
    save();

    // Automatically display widget for pages that load user lists via AJAX.
    $( document ).ajaxComplete(function( event, xhr, settings ) {
        if (hideAjaxUrl(settings.url) == false) {
            renderFilterBar();
            reapplyFilters();
        }
    });

    // Manually display the filter widget if current url matches an item in the manualList array.
    // Following pages don't load the user list via AJAX.
    let manualList = [
        'page=people',
        'step=profile',
        'blacklist.php',
        'friendlist.php',
        'hospitalview.php',
        'jailview.php',
        'factions.php',
    ];

    manualList.forEach(el =>{
        if (window.location.href.match(el)){
            renderFilterBar();
        }
    });

})();


/**
 * Load localStorage data.
 */
function loadData(){
    data = localStorage.getItem(localStorageLocation);

    if(data == null) {
        // Default settings
        data = {
            apiKey : apikey,
            apiQueryDelay : 250,
            hideFactionDescription: false,
            queries: 0,
            start: '0'
        };
    } else {
        data = JSON.parse(data);
        if (data.apiQueryDelay == undefined){
            data.apiQueryDelay = 250;
        }
    }


    // Calculate values of checkboxes.

    // eslint-disable-next-line no-undef
    reviveCheck = $('#tc-filter-revive').prop('checked');
    // eslint-disable-next-line no-undef
    attackCheck = $('#tc-filter-attack').prop('checked');
    // eslint-disable-next-line no-undef
    offlineCheck = $('#tc-filter-offline').prop('checked');
    develCheck = $('#tc-devmode').prop('checked');

}

/**
 * Save localStorage data.
 */
function save(){
    console.log('FPF local data saved');
    localStorage.setItem('torncat.factionFilters', JSON.stringify(data));
}

/**
 * Renders HTML filter elements above the user list.
 */
function renderFilterBar() {
    // Generate HTMl.
    let reviveCheck = '#tc-filter-revive';
    let attackCheck = '#tc-filter-attack';
    let offlineCheck = '#tc-filter-offline';
    let refreshCheck = '#tc-refresh';
    let widgetLocationsSelector = '';

    let widgetHTML = `
        <div class="torncat-player-filter-bar">
            <div class="info-msg-cont border-round m-top10">
                <div class="info-msg border-round">
                    <a class="torncat-icon" title="Open Settings"></a>
                    <div class="torncat-filters">
                        <div class="msg right-round" tabindex="0" role="alert">
                            <label class="torncat-filter">
                                <span class="torncat-label">Revive Mode</span>
                                <input class="torncat-checkbox" id="tc-filter-revive" type="checkbox">
                            </label>
                            <label class="torncat-filter">
                                <span class="torncat-label">Attack Mode</span>
                                <input class="torncat-checkbox" id="tc-filter-attack" type="checkbox">
                            </label>
                            <label class="torncat-filter">
                                <span class="torncat-label">Hide Offline</span>
                                <input class="torncat-checkbox" id="tc-filter-offline" type="checkbox">
                            </label>
                            <label class="torncat-filter">
                                <span class="torncat-label">Auto Refresh (API)</span>
                                <input class="torncat-checkbox" id="tc-refresh" type="checkbox">
                            </label>
                        </div>
                    </div>
                </div>
            </div>
            <hr class="page-head-delimiter m-top10 m-bottom10 ">
        </div>
    `;
    let filterBar = $('.torncat-player-filter-bar');

    // Only insert if there isn't already a filter bar on the page.

    if ($(filterBar).length != 1){

        if (window.location.href.match('factions.php')){
            widgetLocationsSelector = '#faction-info-members';
        } else {
            widgetLocationsSelector = '.users-list-title';
        }

        var widgetLocationsLength = $(widgetLocationsSelector).length;
        $(widgetHTML).insertBefore($(widgetLocationsSelector)[widgetLocationsLength - 1]);

        // Scroll mobile view.
        if ($(window).width() < 1000 && data.hideFactionDescription ) {
            setTimeout(() => {
                document.querySelector('.torncat-player-filter-bar').scrollIntoView({
                    behavior: 'smooth'
                });
            },2000);
        }

        /* Add event listeners. */
        $('.torncat-player-filter-bar a.torncat-icon').click(function () {
            $('.api-key-prompt').toggle();
        });

        // Disable filters on Hospital/ Jail pages.
        if (
            window.location.href.startsWith('https://www.torn.com/hospital') ||
            window.location.href.startsWith('https://www.torn.com/jail')
        ){
            $('#tc-filter-revive').prop('checked', true);
            $('#tc-filter-revive').parent().hide();
            $('#tc-filter-attack').parent().hide();
        }

        // Watch for event changes on the revive mode checkbox.
        $(reviveCheck).change(() => {
            toggleUserRow('revive');
            if ($(attackCheck).prop('checked')){
                $(attackCheck).prop('checked', false);
                toggleUserRow('attack');
            }
        });

        // Watch for event changes on the attack mode checkbox.
        $(attackCheck).change(() =>  {
            loadData();
            toggleUserRow('attack');
            if ($(reviveCheck).prop('checked')){
                $(reviveCheck).prop('checked', false);
                toggleUserRow('revive');
            }
        });

        // Watch for event changes on the Hide Offline mode checkbox.
        $(offlineCheck).change(() => {
            loadData();
            toggleUserRow('offline');
        });

        // Watch for event changes on the Auto-refresh checkbox.
        $('#tc-refresh').change(() => {
            if ($(refreshCheck).prop('checked')) {
                console.log('FPF: Starting auto-refresh');
                let queue = new PlayerIDQueue();
                processRefreshQueue(queue);
            } else {
                console.log('FPF: Stopped processing queue. Queue cleared');
                loadData();
                if( !tornPdaMode && develCheck ) console.debug(data);
                queue.clear();
            }


        });
    }

    if ($('.api-key-prompt').length != 1){
        renderSettings();
    }

}

/**
 * Renders API key and other filter settings.
 */
function renderSettings(forceCheck) {
    // Generate HTMl.
    let saveAPIKeyButton = '<button class="torn-btn" id="JApiKeyBtn">Save</button>';
    let hideFactionDescription = '<br/><input class="torncat-checkbox" id="tc-hideFactionDescription" type="checkbox"> <span class="torncat-label">Hide Faction Description</span><br /><br />';
    let devButton = '<input class="torncat-checkbox" id="tc-devmode" type="checkbox"> <span class="torncat-label">Devel Mode </span><br /><br />';
    let clearAPIKeyButton = '<button class="torn-btn" onclick="localStorage.removeItem(\'torncat.factionFilters\');location.reload();">Clear API Key</button><br /><br />';
    let input = '<input type="text" id="JApiKeyInput" style="';
    input += 'border-radius: 8px 0 0 8px;';
    input += 'margin: 4px 0px;';
    input += 'padding: 5px;';
    input += 'font-size: 16px;height: 20px';
    input += '" placeholder="  API Key"></input><br/><br/>';

    let delayOption = '<label for="tc-delay">Delay time between API calls (ms):</label>';
    delayOption += '<select name="tc-delay" id="tc-delay">';
    switch (data.apiQueryDelay){

    case '100':
        delayOption += '  <option value="100" selected="selected">Short (100)</option>';
        delayOption += '  <option value="250">Medium (250)</option>';
        delayOption += '  <option value="500">Long (500)</option>';
        break;
    case '250':
        delayOption += '  <option value="100">Short (100)</option>';
        delayOption += '  <option value="250" selected="selected">Medium (250)</option>';
        delayOption += '  <option value="500">Long (500)</option>';
        break;
    case '500':
        delayOption += '  <option value="100">Short (100)</option>';
        delayOption += '  <option value="250">Medium (250)</option>';
        delayOption += '  <option value="500" selected="selected">Long (500)</option>';
        break;
    default:
        // If for some reason, data.apiQueryDelay isn't set, this will set a sane value.
        data.apiQueryDelay = 500;
        save();
        delayOption += '  <option value="100">Short (100)</option>';
        delayOption += '  <option value="250">Medium (250)</option>';
        delayOption += '  <option value="500" selected="selected">Long (500)</option>';
    }
    delayOption += '</select><br/>';

    let block = '<div class="api-key-prompt profile-wrapper medals-wrapper m-top10">';
    block += '<div class="menu-header">TornCAT - Player Filters</div>';
    block += '<div class="profile-container"><div class="profile-container-description" style="padding: 10px">';
    block += '<p><strong>Click the black icon in the filter row above to toggle this pane.</strong></p><br />';
    if (!tornPdaMode) {
        block += '<p>Auto Refresh requires a <a href="https://www.torn.com/preferences.php#tab=api">Torn API</a> key.  It will never be transmitted anywhere outside of Torn</p>';
        block += input;
    }
    block += delayOption;
    block += hideFactionDescription;
    if (!tornPdaMode) {
        block += devButton;
        block += saveAPIKeyButton + ' | ';
        block += clearAPIKeyButton;
    }
    block += '</div></div></div>';
    setTimeout(()=>{
        if ($('.api-key-prompt').length != 1){
            $(block).insertAfter('.torncat-player-filter-bar');

            // Re-enter saved data.
            if (data.apiKey != ''){
                $('#JApiKeyInput').val(data.apiKey);
            }

            if (data.hideFactionDescription) {
                $('#tc-hideFactionDescription').prop('checked', true);
                $('.faction-description').hide();
            }

            // Add event listeners.

            $('#JApiKeyBtn').click(function(){
                data.apiKey = $('#JApiKeyInput').val();
                save();
                $('.api-key-prompt').toggle();
            });

            $('#tc-delay').change(()=>{
                data.apiQueryDelay = $('#tc-delay').val();
                save();
                 if( !tornPdaMode && develCheck ) console.debug('Changed apiQueryDelay to ' + data.apiQueryDelay + 'ms');
            });


            $('#tc-devmode').change(() => {
                loadData();
                if (!tornPdaMode){
                    console.debug('FPF Devel mode set to ' + develCheck);
                    console.debug('data:', data);
                    console.debug('apiDataCache', apiDataCache);
                    console.debug('queue', queue);
                }
            });

            $('#tc-hideFactionDescription').change(()=>{
                data.hideFactionDescription = $('#tc-hideFactionDescription').attr('checked') ? true : false;
                save();
                if (data.hideFactionDescription){
                    $('.faction-description').hide();
                } else {
                    $('.faction-description').show();
                }
                document.querySelector('.torncat-player-filter-bar').scrollIntoView({
                    behavior: 'smooth'
                });
            });
        }

        if (forceCheck == true){
            $('.api-key-prompt').show();
        } else {
            $('.api-key-prompt').hide();
        }
    }, 500);

}

/**
 * Re-applies the selected filters if the page data is reloaded via AJAX.
 */
function reapplyFilters(){
    let checked = [
        'revive',
        'attack',
        'offline'
    ];
    checked.forEach((filter)=>{
        let filterName = '#tc-filter-' + filter;
        if ($(filterName).prop('checked')){
            toggleUserRow(filter);
        }
    });
    if ($('#tc-refresh').prop('checked')){
        $('#tc-refresh').prop('checked', false);
        queue.clear();
        console.log('FPF: Restarting auto-refresh');
        queue = new PlayerIDQueue();
        $('#tc-refresh').prop('checked', true);
        processRefreshQueue(queue);
    }
}


/**
 * Async loop for processing next item in player queue.
 *
 * @param {PlayerIDQueue} queue
 */
async function processRefreshQueue(queue) {
    let refreshCheck = '#tc-refresh';
    let limited = false;
    while (!queue.isEmpty()){
        if( !tornPdaMode && develCheck ) console.debug('Current API calls: ' + data.queries);
        loadData();
        let playerID = queue.peek();
        // Call cache, if API queries threshold not hit.
        let now = new Date();

        if  ( now.getMinutes() != data.start ){
            console.log('FPF: Reset API call limit.  Highwater mark: ' + data.queries + ' API calls.');
            data.queries = 0;
            data.start = now.getMinutes();
            queue.start = now;
            save();
        }

        if (data.queries > apiQueryLimit && limited == false){
            let delay = (60 - now.getSeconds());
            console.log('Hit local API query limit of (' + apiQueryLimit + '). Waiting ' + delay + 's');
            limited = true;
            // Disable queue.
            queue.clear();
            $('#tc-refresh').attr('disabled', true);
            setInterval(()=>{
                // Reinitiate queue.
                $('#tc-refresh').prop('checked', false);
                $('#tc-refresh').attr('disabled', false);
                queue.clear();
                console.log('FPF: Restarting auto-refresh');
                queue = new PlayerIDQueue();
                $('#tc-refresh').prop('checked', true);
                processRefreshQueue(queue);
            }, delay * 1000);

            continue;
        } else if (!limited){
            limited = false;
            try{
                let playerData = await callCache(playerID);
                // Find player row in userlist.
                let selector = $('a.user.name[href$="' + playerID + '"]').parent().closest('li');

                updatePlayerContent(selector, playerData);
                // Update player row data.
                if(!queue.isEmpty() && ($('#tc-refresh').prop('checked') == true)) {
                    queue.requeue();
                } else {
                    queue.clear();
                }
            }
            catch(err){
                queue.clear();
                $(refreshCheck).prop('checked', false);
                renderSettings(true);
                console.error(err);
            }
        }
    }
}

/**
 * Returns cached player data, calling Torn API if cache hit is missed.
 *
 * @param {string} playerID
 */
async function callCache(playerID, recurse = false){
    let factionData = {};
    let playerData = {};
    let faction_id = 0;

    if (!(playerID in apiDataCache) || recurse == true){
        if( !tornPdaMode && develCheck ) console.debug('Missed cache for ' + playerID);
        // Call faction API endpoint async, if applicable.
        if (window.location.href.startsWith('https://www.torn.com/factions.php')){
            let searchParams = new URLSearchParams(window.location.search);
            if (searchParams.has('ID')){
                faction_id = (searchParams.get('ID'));
            }
            factionData = await callTornAPI('faction', faction_id, 'basic,timestamp');
            saveCacheData(factionData);
        }

        // Call user API endpoint async
        playerData = await callTornAPI('user', playerID, 'basic,profile,timestamp');
    } else {
        if( !tornPdaMode && develCheck ) console.debug('Cache hit for ' + apiDataCache[playerID].name + ' (' + playerID + ')');
        let now = new Date();
        playerData = apiDataCache[playerID];

        // Check timestamp for old data.
        let delta = (Math.round(now / 1000) - playerData.timestamp);
        if (delta > 30){
            if( !tornPdaMode && develCheck ) console.debug('Cache expired for ' + apiDataCache[playerID].name + ' (' + playerID + ')');
            playerData = await callCache(playerID, true);
        }
    }

    saveCacheData(playerData);

    return new Promise((resolve) => {
        setTimeout(()=>{
            resolve(playerData);
        }, data.apiQueryDelay);
    });
}

/**
 * Calls Torn API Endpoints.
 *
 * @param {string} type
 * @param {string} id
 * @param {string} selections
 */
function callTornAPI(type, id = '', selections=''){
    loadData();
    return new Promise((resolve, reject ) => {
        setTimeout(async () => {
            let baseURL = 'https://api.torn.com/';
            let streamURL = baseURL + type + '/' + id + '?selections=' + selections + '&key=' + data.apiKey + '&comment=TornCat';
             if( !tornPdaMode && develCheck ) console.debug('Making an API call to ' + streamURL);

            // Reject if key isn't set.
            if (data.apiKey == undefined || data.apiKey == '') {
                let error = {
                    code: 1,
                    error: 'Key is empty'
                };
                reject(error);
            }

            $.getJSON(streamURL)
                .done((result) => {
                    if (result.error != undefined){
                        reject(result.error);
                    } else {
                        data.queries++;
                        save();
                        resolve(result);
                    }
                })
                .fail(function( jqxhr, textStatus, error ) {
                    var err = textStatus + ', ' + error;
                    reject(err);
                });

        }, data.apiQueryDelay);
    });
}

/**
 * Saves Torn API data to local cache.
 *
 * @param {Object} data
 */
function saveCacheData(response){
    let playerData = {};
    if ('members' in response){
        // Process faction members' data.
        let keys = Object.keys(response.members);
        keys.forEach(playerID =>{
            playerData = response.members[playerID];
            playerData.timestamp = response.timestamp;
            apiDataCache[playerID] = playerData;
        });
    } else {
        // Process single player data.
        apiDataCache[response.player_id] = response;
    }
}

/**
 * Only returns if the AJAX URL is on the known list.
 * @param {string} url
 */
function hideAjaxUrl(url) {
    // Known AJAX URL's to ignore.
    let hideURLList = [
        'api.torn.com',
        'autocompleteHeaderAjaxAction.php',
        'competition.php',
        'missionChecker.php',
        'onlinestatus.php',
        'revive.php',
        'sidebarAjaxAction.php',
        'tornMobileApp.php',
        'torn-proxy.com',
        'websocket.php'
    ];

    // Known valid AJAX URl's, saved here for my own notes.
    // eslint-disable-next-line no-unused-vars
    let validURLList = [
        'userlist.php',
        'factions.php'
    ];

    for (let el of hideURLList) {
        if (url.match(el)) {
            return true;
        }
    }
    return false;
}

/**
 * Toggles classes on user rows based on toggleType.
 * @param {string} toggleType
 */
function toggleUserRow(toggleType){
    var greenStatusList = $('.status .t-green').toArray();
    var redStatusList = $('.status .t-red').toArray();
    var blueStatusList = $('.status .t-blue').toArray();

    if (toggleType == 'offline') {
        var idleList = $('li [id^=icon62_').toArray();
        var offlineList = $('li [id^=icon2_]').toArray();

        var awayList = idleList.concat(offlineList);
        awayList.forEach(el =>{
            $(el).parent().closest('li').toggleClass('torncat-hide-' + toggleType);
        });
        return;
    }

    blueStatusList.forEach(el => {
        var line = $(el).parent().closest('li');
        $(line).toggleClass('torncat-hide-' + toggleType);
    });


    greenStatusList.forEach(el => {
        var line = $(el).parent().closest('li');
        if(toggleType == 'revive'){
            $(line).toggleClass('torncat-hide-' + toggleType);
        }
    });

    redStatusList.forEach(el => {
        var matches = [
            'Traveling',
            'Fallen',
            'Federal'
        ];

        if (toggleType == 'attack') {
            var line = $(el).parent().closest('li');
            $(line).toggleClass('torncat-hide-' + toggleType);
        } else {
            matches.forEach(match => {
                if ($(el).html().endsWith(match) || $(el).html().endsWith(match + ' ')) {
                    var line = $(el).closest('li');
                    $(line).toggleClass('torncat-hide-' + toggleType);
                }
            });
        }
    });

}

/**
 * Updates a player's row content with API data.
 */
function updatePlayerContent(selector, playerData){
    let statusColor = playerData.status.color;
    let offlineCheck = $('#tc-filter-offline').prop('checked');
    // Apply highlight.
    $(selector).toggleClass('torncat-update');

    // Remove highlight after a delay.
    setTimeout(()=>{
        $(selector).toggleClass('torncat-update');
    }, data.apiQueryDelay * 2);

    // Update row HTML.
    let newHtml = '<span class="d-hide bold">Status:</span><span class="t-' + statusColor + '">' + playerData.status.state + '</span>';
    $(selector).find('div.status').html(newHtml);
    $(selector).find('div.status').css('color', statusColor);

    // Update status icon.
    switch (playerData.last_action.status) {
    case 'Offline':
        $(selector).find('ul#iconTray.singleicon').find('li').first().attr('id','icon2_');
        if (offlineCheck && !($(selector).first().hasClass('torncat-hide-offline'))){
            $(selector).first().addClass('torncat-hide-offline');
             if( !tornPdaMode && develCheck ) console.log('FPF: ' + playerData.name + ' went offline');
        }
        break;
    case 'Online':
        $(selector).find('ul#iconTray.singleicon').find('li').first().attr('id','icon1_');
        if (offlineCheck && ($(selector).first().hasClass('torncat-hide-offline'))){
            $(selector).first().removeClass('torncat-hide-offline');
             if( !tornPdaMode && develCheck ) console.log('FPF: ' + playerData.name + ' came online');
        }
        break;
    case 'Idle':
        $(selector).find('ul#iconTray.singleicon').find('li').first().attr('id','icon62_');
        if (offlineCheck && !($(selector).first().hasClass('torncat-hide-offline'))){
            $(selector).first().addClass('torncat-hide-offline');
             if( !tornPdaMode && develCheck ) console.log('FPF: ' + playerData.name + ' became idle');
        }
        break;
    }

    // Update HTML classes to show/ hide row.
    if ($('#tc-filter-revive').prop('checked')) {
        // Hide traveling
        if (playerData.status.color == 'blue') {
            if (!($(selector).first().hasClass('torncat-hide-revive'))){
                $(selector).first().addClass('torncat-hide-revive');
                 if( !tornPdaMode && develCheck ) console.debug('FPF: ' + playerData.name + ' is now travelling');
            }
        }
        // Hide Okay
        if (playerData.status.color == 'green') {
            if (!($(selector).first().hasClass('torncat-hide-revive'))){
                $(selector).first().addClass('torncat-hide-revive');
                 if( !tornPdaMode && develCheck ) console.debug('FPF: ' + playerData.name + ' is Okay and no longer a revivable target.');
            }
        }
        return;
    }

    if ($('#tc-filter-attack').prop('checked')) {
        // Hide traveling
        if (playerData.status.color == 'blue') {
            if (!($(selector).first().hasClass('torncat-hide-attack'))){
                $(selector).first().addClass('torncat-hide-attack');
                 if( !tornPdaMode && develCheck ) console.debug('FPF: ' + playerData.name + ' is now travelling');
            }
        }
        // Hide anyone else not OK
        if (playerData.status.color == 'red') {
            if (!($(selector).first().hasClass('torncat-hide-revive'))){
                $(selector).first().addClass('torncat-hide-revive');
                 if( !tornPdaMode && develCheck ) console.debug('FPF: ' + playerData.name + ' is no longer an attackable target.');
            }
        }
    }
}

var styles= `
.torncat-filters div.msg {
    display: flex;
    justify-content: center;
}

.torncat-filters {
    width: 100%
}

.torncat-filter {
    display: inline-block;
    margin: 0 10px 0 10px;
    text-align: center;
}

.torncat-update {
    background: rgba(76, 200, 76, 0.2) !important;
}
.torncat-hide-revive {
    display:none !important;
}
.torncat-hide-attack {
    display:none !important
}
.torncat-hide-offline {
    display:none !important
}

.torncat-icon {
    background-image: url("data:image/svg+xml,%3Csvg data-v-fde0c5aa='' xmlns='http://www.w3.org/2000/svg' viewBox='0 0 300 300' class='icon'%3E%3C!----%3E%3Cdefs data-v-fde0c5aa=''%3E%3C!----%3E%3C/defs%3E%3C!----%3E%3C!----%3E%3Cdefs data-v-fde0c5aa=''%3E%3C!----%3E%3C/defs%3E%3Cg data-v-fde0c5aa='' id='761e8856-1551-45a8-83d8-eb3e49301c32' fill='black' stroke='none' transform='matrix(2.200000047683716,0,0,2.200000047683716,39.999999999999986,39.99999999999999)'%3E%3Cpath d='M93.844 43.76L52.389 70.388V85.92L100 55.314zM0 55.314L47.611 85.92V70.384L6.174 43.718zM50 14.08L9.724 39.972 50 65.887l40.318-25.888L50 14.08zm0 15.954L29.95 42.929l-5.027-3.228L50 23.576l25.077 16.125-5.026 3.228L50 30.034z'%3E%3C/path%3E%3C/g%3E%3C!----%3E%3C/svg%3E");
    background-position: center center;
    background-repeat: no-repeat;
    border-top-left-radius: 5px;
    border-bottom-left-radius: 5px;
    display: inline-block;
    width: 32px;
}

`;
// eslint-disable-next-line no-undef
GM_addStyle(styles);""";

    return UserScriptModel(
      // IMPORTANT: increment version by 1
      version: 1,

      enabled: true,
      urls: getUrls(source),
      name: "TornCAT Faction Player Filters",
      exampleCode: 2,
      edited: false,
      source: source,
    );
  }

  static UserScriptModel _racingPresetsExample() {
    var source = r"""// ==UserScript==
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
      version: 2,

      enabled: true,
      urls: getUrls(source),
      name: "Custom Race Presets",
      exampleCode: 3,
      edited: false,
      source: source,
    );

  }

  static UserScriptModel _specialGymRatios() {
    var source = r"""// ==UserScript==
// @name         Custom Gym Ratios
// @version      2.3.1
// @description  Monitors battle stat ratios and provides warnings if they approach levels that would preclude access to special gyms
// @author       RGiskard [1953860], assistance by Xiphias [187717] - Torn PDA adaptation v1 [Manuito]
// @match      	 torn.com/gym.php
// ==/UserScript==

gymLoaded().then(() => {
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
});


function gymLoaded() {
  return new Promise((resolve) => {
	let checker = setInterval(() => {
	  if (document.querySelector("#gymroot")) {
		setInterval(() => {
		  resolve(true);
		}, 300);
		return clearInterval(checker);
	  }
	});
  });
} """;

    return UserScriptModel(
      // IMPORTANT: increment version by 1
      version: 1,

      enabled: true,
      urls: getUrls(source),
      name: "Custom Gym Ratios",
      exampleCode: 4,
      edited: false,
      source: source,
    );

  }

  static UserScriptModel _companyStocksOrderExample() {
    var source = r"""// ==UserScript==
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
      version: 1,

      enabled: false,
      urls: getUrls(source),
      name: "Company Stocks Order",
      exampleCode: 5,
      edited: false,
      source: source,
    );

  }

  static UserScriptModel _companyActivity() {
    var source = r"""// ==UserScript==
// @name         Company Activity for Torn PDA
// @namespace    TornExtensions
// @version      1.0
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
    let callback = function(mutationsList, observer) {
        $("a.user.name").each(function() {
            if($(this).closest("li").attr("data-user").length > 0 && $(this).next("img")) {
                let uID = $(this).closest("li").attr("data-user");
                let API = `https://api.torn.com/user/${uID}?selections=profile&key=${APIKey}`;
                fetch(API)
                  .then((res) => res.json())
                  .then((res) => {
                    $($($(this).parent().parent().parent()).find(".acc-body")).find(".stats").append('<span tabindex="0" class="span-cont t-first" aria-label="Active: "' + res.last_action.relative + '"><span class="bold t-show">Active:</span> ' + res.last_action.relative + '</span><span class="t-hide">/</span>');
                    $($($(this).parent().parent().parent()).find(".acc-body")).find(".stats").append('<span tabindex="0" class="span-cont t-first" aria-label=" "><span class="bold t-show"></span></span> <span class="t-hide">/</span>');
                    let days = res.last_action.relative.split(" ");
                    if(days[1].includes("day"))
                        if(parseInt(days[0]) == 1)
                            $(this).parent().css("background-color", "orange");
                        else if(parseInt(days[0]) >= 2)
                            $(this).parent().css("background-color", "red");
                  });
            }
        });
    };
    let observer = new MutationObserver(callback);
    observer.observe(targetNode, config);
})();""";

    return UserScriptModel(
      // IMPORTANT: increment version by 1
      version: 1,

      enabled: false,
      urls: getUrls(source),
      name: "Company Activity",
      exampleCode: 6,
      edited: false,
      source: source,
    );

  }
}
