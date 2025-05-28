// https://wiki.greasespot.net/GM.setValue
GM.setValue = function(key, value) {
    localStorage.setItem(key, value)
    return Promise.resolve();
}