var GM_getValue = function(key, defaultValue) {
	return localStorage.getItem(key) ?? defaultValue;
}