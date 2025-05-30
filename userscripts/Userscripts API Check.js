// ==UserScript==
// @name         Userscripts API Check
// @namespace    https://github.com/TravisTheTechie
// @version      1.0
// @description  Attempts to validate a userscript's API compatibility with spec.
// @author       Travis Smith
// @license      MIT
// @match        https://*
// @grant        GM.getValue
// @grant        GM.setValue
// ==/UserScript==

// clear out the document body
document.body.innerHTML = '';

const checks = [
    {
        name: "GM",
        checker: () => {
            if (typeof GM !== 'object') {
                return Promise.reject("GM is not an object.");
            }
            return Promise.resolve(true);
        }
    },
    {
        name: "GM.info",
        checker: () => {
            if (typeof GM.info !== 'object') {
                return Promise.reject("GM.info is not an object.");
            }
            return Promise.resolve(true);
        }
    },
    {
        name: "GM.getValue/GM.setValue",
        checker: () => {
            if (typeof GM.getValue !== 'function') {
                return Promise.reject("GM.getValue is not a function.");
            }
            if (typeof GM.setValue !== 'function') {
                return Promise.reject("GM.setValue is not a function.");
            }
            try {
                return GM.setValue("testKey", "testValue")
                    .then(() => GM.getValue("testKey", "defaultValue"))
                    .then(value => value === "testValue" ? true : Promise.reject("GM.getValue did not return the expected value."))
                    .then(() => GM.getValue("testKey-doesn't-exist", "defaultValue"))
                    .then(value => value === "defaultValue" ? true : Promise.reject("GM.getValue did not return the default value for a non-existent key."));
            } catch (error) {
                return Promise.reject(`GM.getValue threw an error: ${error}`);
            }
        }
    },
    {
        name: "GM.deleteValue",
        checker: () => {
            if (typeof GM.deleteValue !== 'function') {
                return Promise.reject("GM.deleteValue is not a function.");
            }
            try {
                return GM.setValue("testKey2", "testValue")
                    .then(() => GM.deleteValue("testKey2"))
                    .then(() => GM.getValue("testKey2", "defaultValue"))
                    .then(value => value === "defaultValue" ? true : Promise.reject("GM.deleteValue did not remove the key."));
            } catch (error) {
                return Promise.reject(`GM.deleteValue threw an error: ${error}`);
            }
        }
    },
    {
        name: "GM.listValues",
        checker: () => {
            if (typeof GM.listValues !== 'function') {
                return Promise.reject("GM.listValues is not a function.");
            }
            try {
                return GM.setValue("ListTestKey", "testValue")
                    .then(() => GM.setValue("ListTestKey2", "testValue2"))
                    .then (() => GM.listValues())
                    .then(values => {
                        if (!Array.isArray(values)) {
                            return Promise.reject("GM.listValues did not return an array.");
                        }
                        // Check if the array contains the test key
                        if (!values.includes("ListTestKey") && !values.includes("ListTestKey2")) {
                            return Promise.reject("GM.listValues did not include expected keys.");
                        }
                        return true;
                    });
            } catch (error) {
                return Promise.reject(`GM.listValues threw an error: ${error}`);
            }
        }
    }
].map(check => ({
    ...check,
    checkPromise: check.checker()
}));

checks.forEach(check => {
    check.checkPromise
        .then(() => {
            const resultElement = document.createElement('div');
            resultElement.className = "result pass";
            resultElement.textContent = `${check.name}: Passed`;
            document.body.appendChild(resultElement);
        })
        .catch(error => {
            console.log(`Check failed for ${check.name}:`, error);
            const resultElement = document.createElement('div');
            resultElement.className = "result fail";
            resultElement.textContent = `${check.name}: Failed - ${error}`;
            document.body.appendChild(resultElement);
        });
});