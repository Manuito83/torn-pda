// ==UserScript==
// @name         GMforPDA
// @namespace    https://github.com/Kwack-Kwack/GMforPDA
// @version      2.2.1
// @description  A script that allows native GM functions to be called in Torn PDA.
// @author       Kwack [2190604]
// @match        *
// @run-at       document-start
// ==/UserScript==

((window, Object, DOMException, AbortController, Promise, localStorage) => {
	const version = 2.2;

	const __GM_info = {
		script: {},
		scriptHandler: `GMforPDA version ${version}`,
		version,
	};
	function __GM_getValue(key, defaultValue) {
		if (!key) throw new TypeError("No key supplied to GM_getValue");
		try {
			const r = localStorage.getItem(key);
			if (typeof r !== "string") return defaultValue;
			if (r.startsWith("GMV2_"))
				return JSON.parse(r.slice(5)) ?? defaultValue;
			else return r ?? defaultValue;
		} catch (e) {
			console.error(e);
			return defaultValue;
		}
	}
	function __GM_setValue(key, value) {
		if (!key) throw new TypeError("No key supplied to GM_setValue");
		localStorage.setItem(key, "GMV2_" + JSON.stringify(value));
	}
	function __GM_deleteValue(key) {
		if (!key) throw new TypeError("No key supplied to GM_deleteValue");
		localStorage.removeItem(key);
	}
	function __GM_listValues() {
		return Object.keys(localStorage);
	}
	function __GM_addStyle(style) {
		if (!style || typeof style !== "string") return;
		const s = document.createElement("style");
		s.type = "text/css";
		s.innerHTML = style;
		document.head.appendChild(s);
	}
	function __GM_notification(...args) {
		if (typeof args[0] === "object") {
			const { text, title, onclick, ondone } = args[0];
			notify(text, title, onclick, ondone);
		} else if (typeof args[0] === "string") {
			const [text, title, , onclick] = args;
			notify(text, title, onclick);
		}
		return { remove: () => {} }; // There to prevent syntax errors.
		function notify(text, title, onclick, ondone) {
			if (!text)
				throw new TypeError(
					"No notification text supplied to GM_notification"
				);
			confirm(`${title ?? "No title specified"}\n${text}`) && onclick?.();
			ondone?.();
		}
	}
	function __GM_setClipboard(text) {
		if (!text) throw new TypeError("No text supplied to GM_setClipboard");
		navigator.clipboard.writeText(text);
	}
	function __GM_xmlhttpRequest(details) {
		const { abortController } = ___coreXmlHttpRequest(details);
		if (!details || typeof details !== "object")
			throw new TypeError("Invalid details passed to GM_xmlHttpRequest");
		return { abort: () => abortController.abort() };
	}
	const GM = {
		version,
		info: __GM_info,
		addStyle: __GM_addStyle,
		deleteValue: async (key) => __GM_deleteValue(key),
		getValue: async (key, defaultValue) => __GM_getValue(key, defaultValue),
		listValues: async () => __GM_listValues(),
		notification: __GM_notification,
		setClipboard: __GM_setClipboard,
		setValue: async (key, value) => __GM_setValue(key, value),
		xmlHttpRequest: async (details) => {
			if (!details || typeof details !== "object")
				throw new TypeError(
					"Invalid details passed to GM.xmlHttpRequest"
				);
			const { abortController, prom } = ___coreXmlHttpRequest(details);
			prom.abort = () => abortController.abort();
			return prom;
		},
	};
	Object.entries({
		GM: Object.freeze(GM),
		GM_info: Object.freeze(__GM_info),
		GM_getValue: __GM_getValue,
		GM_setValue: __GM_setValue,
		GM_deleteValue: __GM_deleteValue,
		GM_listValues: __GM_listValues,
		GM_addStyle: __GM_addStyle,
		GM_notification: __GM_notification,
		GM_setClipboard: __GM_setClipboard,
		GM_xmlhttpRequest: __GM_xmlhttpRequest,
		unsafeWindow: window,
	}).forEach(([key, value]) => {
		Object.defineProperty(window, key, {
			value: value,
			writable: false,
			enumerable: true,
			configurable: false,
		});
	});
	/** 3 underscores on this one, as it's an internal function */
	function ___coreXmlHttpRequest(details) {
		const abortController = new AbortController();
		const abortSignal = abortController.signal;
		const timeoutController = new AbortController();
		const timeoutSignal = timeoutController.signal;
		const {
			url,
			method,
			headers,
			timeout,
			data,
			onabort,
			onerror,
			onload,
			onloadend,
			onprogress,
			onreadystatechange,
			ontimeout,
		} = details;
		setTimeout(() => timeoutController.abort(), timeout ?? 30000);
		const prom = new Promise(async (res, rej) => {
			try {
				if (!url) rej("No URL supplied");
				abortSignal.addEventListener("abort", () =>
					rej("Request aborted")
				);
				timeoutSignal.addEventListener("abort", () =>
					rej("Request timed out")
				);
				if (!method || method.toLowerCase() !== "post") {
					PDA_httpGet(url).then(res).catch(rej);
					onprogress?.();
				} else {
					PDA_httpPost(url, headers ?? {}, data ?? "")
						.then(res)
						.catch(rej);
					onprogress?.();
				}
			} catch (e) {
				rej(e);
			}
		})
			.then((r) => {
				onload?.(r);
				onloadend?.(r);
				onreadystatechange?.(r);
				return r;
			})
			.catch((e) => {
				switch (true) {
					case e === "Request aborted":
						e = new DOMException("Request aborted", "AbortError");
						if (onabort) return onabort(e);
						else if (onerror) return onerror(e);
						else throw e;
					case e === "Request timed out":
						e = new DOMException(
							"Request timed out",
							"TimeoutError"
						);
						if (ontimeout) return ontimeout(e);
						else if (onerror) return onerror(e);
						else throw e;
					case e === "No URL supplied":
						e = new TypeError("Failed to fetch: No URL supplied");
						if (onerror) return onerror(e);
						else throw e;
					default:
						if (!e || !(e instanceof Error))
							e = new Error(e ?? "Unknown Error");
						if (onerror) return onerror(e);
						else throw e;
				}
			});
		return { abortController, prom };
	}
})(window, Object, DOMException, AbortController, Promise, localStorage);