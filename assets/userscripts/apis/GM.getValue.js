// https://wiki.greasespot.net/GM.getValue
GM.getValue = function(key, defaultValue) {
	return Promise.resolve(localStorage.getItem(key) ?? defaultValue);
}