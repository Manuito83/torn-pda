// ignore_for_file: non_constant_identifier_names

String handler_flutterPlatformReady() {
  return '''
    // Initialize event listener for other handlers
    var __PDA_platformReadyPromise;
    if(typeof __PDA_platformReadyPromise === 'undefined') {
        __PDA_platformReadyPromise = new Promise(resolve => {
            //console.log("Handler: pdaHandler_platformReady");
            if (window.flutter_inappwebview?._platformReady) return resolve();
            window.addEventListener("flutterInAppWebViewPlatformReady", resolve);
        });
    }
  ''';
}

String handler_pdaAPI() {
  return '''
    // Performs a GET request to the provided URL
    // The expected arguments are:
    //     url
    //     headers - Object with key, value string pairs (optional for backwards compatibility)
    // Returns a promise for a response object that has these properties:
    //     responseHeaders - String, with CRLF line terminators.
    //     responseText
    //     status
    //     statusText
    //
    // NOTE: in order to make the function available ASAP and ensure compatibility is all operating systems, 
    // it will be declared several times while the page loads. However, it will only accept one call with the same
    // URL as a parameter each second
    // 
    //
    // Example call:
    // 
    //
    // let url = 'https://api.example.com/data';
    // let headers = {
    //     "Content-Type": "application/json"
    // }
    // PDA_httpGet(url, headers).then(response => {
    //     console.log(response);
    // }).catch(error => {
    //     console.error(error);
    // });
    
    // Check if loadedPdaApiGetUrls has been declared before. If not, declare it.
    if (typeof loadedPdaApiGetUrls === 'undefined') {
        var loadedPdaApiGetUrls = {};
    }

    async function PDA_httpGet(url, headers = {}) {
        let parameters = `\${url}+\${JSON.stringify(headers)}`;
        let now = Date.now();

        // If this URL was loaded less than a second ago, return immediately
        if (loadedPdaApiGetUrls[url] && (now - loadedPdaApiGetUrls[url] < 2000)) {
            // Skip request
            return;
        }

        // Update the timestamp for this URL
        loadedPdaApiGetUrls[url] = now;
          
        //console.log(JSON.stringify(loadedPdaApiGetUrls));
        console.log("Handler: pdaHandler_ApiGet");
        await __PDA_platformReadyPromise;
          
        return window.flutter_inappwebview.callHandler("PDA_httpGet", url, headers);
    }


    // Performs a POST request to the provided URL
    // The expected arguments are:
    //     url
    //     headers - Object with key, value string pairs 
    //     body - String or Object with key, value string pairs. If it's an object,
    //            it will be encoded as form fields
    //
    // Returns a promise for a response object that has these properties:
    //     responseHeaders: String, with CRLF line terminators.
    //     responseText
    //     status
    //     statusText
    //
    // NOTE: in order to make the function available ASAP and ensure compatibility is all operating systems, 
    // it will be declared several times while the page loads. However, it will only accept one call with the same
    // URL as a parameter each second
    //
    // Example call:
    //
    // let url = 'https://api.example.com/data';
    // let headers = {
    //     "Content-Type": "application/json"
    // };
    // let body = JSON.stringify({
    //     key: 'value'
    // });
    //
    // PDA_httpPost(url, headers, body).then(response => {
    //     console.log(response);
    // }).catch(error => {
    //     console.error(error);
    // });

    // Check if loadedPdaApiPostUrls has been declared before, if not, declare it.
    if (typeof loadedPdaApiPostUrls === 'undefined') {
        var loadedPdaApiPostUrls = {};
    }

    async function PDA_httpPost(url, headers, body) {
        let parameters = `\${url}+\${JSON.stringify(headers)}+\${body}`;
        let now = Date.now();
        
        // If this POST was posted less than 2 seconds ago, return immediately
        if (loadedPdaApiPostUrls[parameters] && (now - loadedPdaApiPostUrls[parameters] < 2000)) {
            // Skip request
            return;
        }
        
        // Update the timestamp for this POST request
        loadedPdaApiPostUrls[parameters] = now;
        
        console.log("Handler: pdaHandler_httpPost");
        await __PDA_platformReadyPromise;
        
        return flutter_inappwebview.callHandler("PDA_httpPost", url, headers, body);
    }
  ''';
}

String handler_evaluateJS() {
  return '''
    // Allows scripts to evaluate javascript source code directly from PDA's webview
    // Might be useful if the source code being evaluated is not yet known, but obtained from
    // a different source, because Torn won't allow execution of eval()
    //
    // Example call (paired with PDA_httpGet to fetch the code):
    //
    // let codeUrl = 'https://example.com/my-script.js';
    // PDA_httpGet(codeUrl).then(response => {
    //     let code = response.data;
    //     PDA_evaluateJavascript(code).then(() => {
    //         console.log('JavaScript code has been fetched and executed');
    //     }).catch(error => {
    //         console.error('Error while evaluating the fetched JavaScript code: ', error);
    //     });
    // }).catch(error => {
    //     console.error('Error while fetching JavaScript code: ', error);
    // });

    // Check if loadedPdaApiEvalScripts has been declared before, if not, declare it
    if (typeof loadedPdaApiEvalScripts === 'undefined') {
        var loadedPdaApiEvalScripts = {};
    }

    async function PDA_evaluateJavascript(source) {
        let now = Date.now();
        
        // If this source was evaluated less than a second ago, return immediately
        if (loadedPdaApiEvalScripts[source] && (now - loadedPdaApiEvalScripts[source] < 2000)) {
            // Skip request
            return;
        }
        
        // Update the timestamp for this source
        loadedPdaApiEvalScripts[source] = now;
        
        console.log("Handler: pdaHandler_evaluateJavascript");
        await __PDA_platformReadyPromise;
        
        return flutter_inappwebview.callHandler("PDA_evaluateJavascript", source);
    }
  ''';
}

/// By Kwack [2190604]
String handler_GM() {
  return '''
  ((e, t, o, r, n, i) => {
  	    const s = {
  		script: {},
  		scriptHandler: "GMforPDA version 2.2",
  		version: 2.2,
  	};
  	function a(e, t) {
  		if (!e) throw new TypeError("No key supplied to GM_getValue");
  		const o = i.getItem(e);
  		return "string" != typeof o
  			? t
  			: o.startsWith("GMV2_")
  			? JSON.parse(o.slice(5)) ?? t
  			: o ?? t;
  	}
  	function l(e, t) {
  		if (!e) throw new TypeError("No key supplied to GM_setValue");
  		i.setItem(e, "GMV2_" + JSON.stringify(t));
  	}
  	function u(e) {
  		if (!e) throw new TypeError("No key supplied to GM_deleteValue");
  		i.removeItem(e);
  	}
  	function c() {
  		return t.keys(i);
  	}
  	function d(e) {
  		if (!e || "string" != typeof e) return;
  		const t = document.createElement("style");
  		(t.type = "text/css"), (t.innerHTML = e), document.head.appendChild(t);
  	}
  	function p(...e) {
  		if ("object" == typeof e[0]) {
  			const { text: o, title: r, onclick: n, ondone: i } = e[0];
  			t(o, r, n, i);
  		} else if ("string" == typeof e[0]) {
  			const [o, r, , n] = e;
  			t(o, r, n);
  		}
  		return { remove: () => {} };
  		function t(e, t, o, r) {
  			if (!e)
  				throw new TypeError(
  					"No notification text supplied to GM_notification"
  				);
  			confirm(`\${t ?? "No title specified"}\n\${e}`) && o?.(), r?.();
  		}
  	}
  	function f(e) {
  		if (!e) throw new TypeError("No text supplied to GM_setClipboard");
  		navigator.clipboard.writeText(e);
  	}
  	const w = {
  		version: 2.2,
  		info: s,
  		addStyle: d,
  		deleteValue: async (e) => u(e),
  		getValue: async (e, t) => a(e, t),
  		listValues: async () => c(),
  		notification: p,
  		setClipboard: f,
  		setValue: async (e, t) => l(e, t),
  		xmlHttpRequest: async (e) => {
  			if (!e || "object" != typeof e)
  				throw new TypeError(
  					"Invalid details passed to GM.xmlHttpRequest"
  				);
  			const { abortController: t, prom: o } = y(e);
  			return (o.abort = () => t.abort()), o;
  		},
  	};
  	function y(e) {
  		const t = new r(),
  			i = t.signal,
  			s = new r(),
  			a = s.signal,
  			{
  				url: l,
  				method: u,
  				headers: c,
  				timeout: d,
  				data: p,
  				onabort: f,
  				onerror: w,
  				onload: y,
  				onloadend: h,
  				onprogress: b,
  				onreadystatechange: m,
  				ontimeout: M,
  			} = e;
  		setTimeout(() => s.abort(), d ?? 3e4);
  		return {
  			abortController: t,
  			prom: new n(async (e, t) => {
  				try {
  					l || t("No URL supplied"),
  						i.addEventListener("abort", () => t("Request aborted")),
  						a.addEventListener("abort", () =>
  							t("Request timed out")
  						),
  						u && "post" === u.toLowerCase()
  							? (PDA_httpPost(l, c ?? {}, p ?? "")
  									.then(e)
  									.catch(t),
  							  b?.())
  							: (PDA_httpGet(l).then(e).catch(t), b?.());
  				} catch (e) {
  					t(e);
  				}
  			})
  				.then((e) => (y?.(e), h?.(e), m?.(e), e))
  				.catch((e) => {
  					switch (!0) {
  						case "Request aborted" === e:
  							if (
  								((e = new o("Request aborted", "AbortError")),
  								f)
  							)
  								return f(e);
  							if (w) return w(e);
  							throw e;
  						case "Request timed out" === e:
  							if (
  								((e = new o(
  									"Request timed out",
  									"TimeoutError"
  								)),
  								M)
  							)
  								return M(e);
  							if (w) return w(e);
  							throw e;
  						case "No URL supplied" === e:
  							if (
  								((e = new TypeError(
  									"Failed to fetch: No URL supplied"
  								)),
  								w)
  							)
  								return w(e);
  							throw e;
  						default:
  							if (
  								((e && e instanceof Error) ||
  									(e = new Error(e ?? "Unknown Error")),
  								w)
  							)
  								return w(e);
  							throw e;
  					}
  				}),
  		};
  	}
  	t.entries({
  		GM: t.freeze(w),
  		GM_info: t.freeze(s),
  		GM_getValue: a,
  		GM_setValue: l,
  		GM_deleteValue: u,
  		GM_listValues: c,
  		GM_addStyle: d,
  		GM_notification: p,
  		GM_setClipboard: f,
  		GM_xmlhttpRequest: function (e) {
  			const { abortController: t } = y(e);
  			if (!e || "object" != typeof e)
  				throw new TypeError(
  					"Invalid details passed to GM_xmlHttpRequest"
  				);
  			return { abort: () => t.abort() };
  		},
  		unsafeWindow: e,
  	}).forEach(([o, r]) => {
  		t.defineProperty(e, o, {
  			value: r,
  			writable: !1,
  			enumerable: !0,
  			configurable: !1,
  		});
  	});
  })(window, Object, DOMException, AbortController, Promise, localStorage);
   ''';
}
