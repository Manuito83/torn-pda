// ==UserScript==
// @name         Company Activity for Torn PDA
// @namespace    TornExtensions
// @version      1.2 (updated by Manuito)
// @description  Shows the activity of employees.
// @author       Twenu [XID 2659526]
// @match        https://www.torn.com/companies.php*
// @grant        none
// ==/UserScript==

(function () {
    //'use strict';
    let APIKey = '###PDA-APIKEY###';
    let targetNode = document.getElementById('employees');
    let config = { childList: true };

    function removeElementsByClass(className) {
        const elements = document.getElementsByClassName(className);
        while (elements.length > 0) {
            elements[0].parentNode.removeChild(elements[0]);
        }
    }

    function checkEmployees() {
        // Make sure to remove previous 'Active' lines (needed for iOS)
        removeElementsByClass('activeEmployee');

        $("a.user.name").each(function () {

            if ($(this).closest("li").attr("data-user").length > 0 && $(this).next("img")) {

                let uID = $(this).closest("li").attr("data-user");
                let API = `https://api.torn.com/user/${uID}?selections=profile&key=${APIKey}`;
                fetch(API)
                    .then((res) => res.json())
                    .then((res) => {

                        $($($(this).parent().parent().parent()).find(".acc-body")).find(".stats").append('<span tabindex="0" class="span-cont t-first activeEmployee" aria-label="Active: "' + res.last_action.relative + '"><span class="bold t-show">Active:</span> ' + res.last_action.relative + '</span><span class="t-hide">/</span>');
                        $($($(this).parent().parent().parent()).find(".acc-body")).find(".stats").append('<span tabindex="0" class="span-cont t-first activeEmployee" aria-label=" "><span class="bold t-show"></span></span> <span class="t-hide">/</span>');
                        let days = res.last_action.relative.split(" ");

                        if (days[1].includes("hour"))
                            if (parseInt(days[0]) == 1)
                                $(this).parent().css("background-color", "orange");
                            else if (parseInt(days[0]) >= 2)
                                $(this).parent().css("background-color", "red");
                    });
            }
        });
    }

    var waitForElementsAndRun = setInterval(function () {
        if (document.querySelector(".employee-effectiveness") !== null) {
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