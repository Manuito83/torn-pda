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

String handler_tabContext(String tabUid) {
  return '''
		(function() {
			const root = (window.__tornpda = window.__tornpda || {});
			root.tab = root.tab || {};

			if (root.tab.uid !== '$tabUid') {
				try {
					Object.defineProperty(root.tab, 'uid', { value: '$tabUid', writable: false, configurable: false });
				} catch (_) {
					root.tab.uid = '$tabUid';
				}
			}

			if (!root.tab.state) {
				root.tab.state = { uid: '$tabUid', isActiveTab: false, isWebViewVisible: false };
			}
		})();
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

    // Performs a PUT request to the provided URL
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

    // Check if loadedPdaApiPutUrls has been declared before, if not, declare it.
    if (typeof loadedPdaApiPutUrls === 'undefined') {
        var loadedPdaApiPutUrls = {};
    }

    async function PDA_httpPut(url, headers, body) {
        let parameters = `\${url}+\${JSON.stringify(headers)}+\${body}`;
        let now = Date.now();
        
        // If this PUT was sent less than 2 seconds ago, return immediately
        if (loadedPdaApiPutUrls[parameters] && (now - loadedPdaApiPutUrls[parameters] < 2000)) {
            // Skip request
            return;
        }
        
        // Update the timestamp for this PUT request
        loadedPdaApiPutUrls[parameters] = now;
        
        console.log("Handler: pdaHandler_httpPut");
        await __PDA_platformReadyPromise;
        
        return flutter_inappwebview.callHandler("PDA_httpPut", url, headers, body);
    }

    // Performs a DELETE request to the provided URL
    // The expected arguments are:
    //     url
    //     headers - Object with key, value string pairs (optional)
    //
    // Returns a promise for a response object that has these properties:
    //     responseHeaders - String, with CRLF line terminators.
    //     responseText
    //     status
    //     statusText
    //
    // NOTE: in order to make the function available ASAP and ensure compatibility is all operating systems, 
    // it will be declared several times while the page loads. However, it will only accept one call with the same
    // URL as a parameter each second

    // Check if loadedPdaApiDeleteUrls has been declared before, if not, declare it.
    if (typeof loadedPdaApiDeleteUrls === 'undefined') {
        var loadedPdaApiDeleteUrls = {};
    }

    async function PDA_httpDelete(url, headers = {}) {
        let parameters = `\${url}+\${JSON.stringify(headers)}`;
        let now = Date.now();

        // If this DELETE was sent less than 2 seconds ago, return immediately
        if (loadedPdaApiDeleteUrls[parameters] && (now - loadedPdaApiDeleteUrls[parameters] < 2000)) {
            // Skip request
            return;
        }

        // Update the timestamp for this DELETE request
        loadedPdaApiDeleteUrls[parameters] = now;

        console.log("Handler: pdaHandler_httpDelete");
        await __PDA_platformReadyPromise;

        return window.flutter_inappwebview.callHandler("PDA_httpDelete", url, headers);
    }

    // Performs a PATCH request to the provided URL
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

    // Check if loadedPdaApiPatchUrls has been declared before, if not, declare it.
    if (typeof loadedPdaApiPatchUrls === 'undefined') {
        var loadedPdaApiPatchUrls = {};
    }

    async function PDA_httpPatch(url, headers, body) {
        let parameters = `\${url}+\${JSON.stringify(headers)}+\${body}`;
        let now = Date.now();
        
        // If this PATCH was sent less than 2 seconds ago, return immediately
        if (loadedPdaApiPatchUrls[parameters] && (now - loadedPdaApiPatchUrls[parameters] < 2000)) {
            // Skip request
            return;
        }
        
        // Update the timestamp for this PATCH request
        loadedPdaApiPatchUrls[parameters] = now;
        
        console.log("Handler: pdaHandler_httpPatch");
        await __PDA_platformReadyPromise;
        
        return flutter_inappwebview.callHandler("PDA_httpPatch", url, headers, body);
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
    ((e, t, r, o, n, i) => {
      if ("GM" in e) return console.warn("GM already defined, skipping declaration");
      const s = { script: {}, scriptHandler: "GMforPDA version 2.2", version: 2.2 };
      function a(e, t) {
        if (!e) throw new TypeError("No key supplied to GM_getValue");
        try {
          const r = i.getItem(e);
          return "string" != typeof r
            ? t
            : r.startsWith("GMV2_")
              ? (JSON.parse(r.slice(5)) ?? t)
              : (r ?? t);
        } catch (e) {
          return (console.error(e), t);
        }
      }
      function c(e) {
        return Array.isArray(e)
          ? e.reduce((e, t) => {
              const r = a(t);
              return (void 0 !== r && (e[t] = r), e);
            }, {})
          : t.entries(e).reduce((e, [t, r]) => {
              const o = a(t, r);
              return ((e[t] = void 0 === o ? r : o), e);
            }, {});
      }
      function u(e, t) {
        if (!e) throw new TypeError("No key supplied to GM_setValue");
        i.setItem(e, "GMV2_" + JSON.stringify(t));
      }
      function l(e) {
        for (const [r, o] of t.entries(e)) u(r, o);
      }
      function d(e) {
        if (!e) throw new TypeError("No key supplied to GM_deleteValue");
        i.removeItem(e);
      }
      function f() {
        return t.keys(i);
      }
      function p(e) {
        if (!e || "string" != typeof e) return;
        const t = document.createElement("style");
        ((t.type = "text/css"),
          (t.innerHTML = e),
          (document.head || document.documentElement).appendChild(t));
      }
      function h(...e) {
        if ("object" == typeof e[0]) {
          const { text: r, title: o, onclick: n, ondone: i } = e[0];
          t(r, o, n, i);
        } else if ("string" == typeof e[0]) {
          const [r, o, , n] = e;
          t(r, o, n);
        }
        return { remove: () => {} };
        function t(e, t, r, o) {
          if (!e)
            throw new TypeError("No notification text supplied to GM_notification");
          (confirm(`\${t ?? "No title specified"}\n\${e}`) && r?.(), o?.());
        }
      }
      function y(e) {
        if (!e) throw new TypeError("No text supplied to GM_setClipboard");
        navigator.clipboard.writeText(e);
      }
      const w = {
        version: 2.2,
        info: s,
        addStyle: p,
        deleteValue: async (e) => d(e),
        getValue: async (e, t) => a(e, t),
        getValues: async (e) => c(e),
        listValues: async () => f(),
        notification: h,
        setClipboard: y,
        setValue: async (e, t) => u(e, t),
        setValues: async (e) => l(e),
        xmlHttpRequest: async (e) => {
          if (!e || "object" != typeof e)
            throw new TypeError("Invalid details passed to GM.xmlHttpRequest");
          const { abortController: t, prom: r } = b(e);
          return ((r.abort = () => t.abort()), r);
        },
      };
      function b(e) {
        const t = new o(),
          i = t.signal,
          s = new o(),
          a = s.signal,
          {
            url: c,
            method: u,
            headers: l,
            timeout: d,
            data: f,
            onabort: p,
            onerror: h,
            onload: y,
            onloadend: w,
            onprogress: b,
            onreadystatechange: m,
            ontimeout: M,
          } = e;
        setTimeout(() => s.abort(), d ?? 3e4);
        return {
          abortController: t,
          prom: new n(async (e, t) => {
            try {
              switch (
                (c || t("No URL supplied"),
                i.addEventListener("abort", () => t("Request aborted")),
                a.addEventListener("abort", () => t("Request timed out")),
                (u || "").toLowerCase())
              ) {
                case "post":
                  PDA_httpPost(c, l ?? {}, f ?? "")
                    .then(e)
                    .catch(t);
                  break;
                case "put":
                  PDA_httpPut(c, l ?? {}, f ?? "")
                    .then(e)
                    .catch(t);
                  break;
                case "delete":
                  PDA_httpDelete(c, l ?? {})
                    .then(e)
                    .catch(t);
                  break;
                case "patch":
                  PDA_httpPatch(c, l ?? {}, f ?? "")
                    .then(e)
                    .catch(t);
                  break;
                default:
                  PDA_httpGet(c, l ?? {})
                    .then(e)
                    .catch(t);
              }
              b?.();
            } catch (e) {
              t(e);
            }
          })
            .then((e) => (y?.(e), w?.(e), m?.(e), e))
            .catch((e) => {
              switch (!0) {
                case "Request aborted" === e:
                  if (((e = new r("Request aborted", "AbortError")), p))
                    return p(e);
                  if (h) return h(e);
                  throw e;
                case "Request timed out" === e:
                  if (((e = new r("Request timed out", "TimeoutError")), M))
                    return M(e);
                  if (h) return h(e);
                  throw e;
                case "No URL supplied" === e:
                  if (((e = new TypeError("Failed to fetch: No URL supplied")), h))
                    return h(e);
                  throw e;
                default:
                  if (
                    ((e && e instanceof Error) ||
                      (e = new Error(e ?? "Unknown Error")),
                    h)
                  )
                    return h(e);
                  throw e;
              }
            }),
        };
      }
      t.entries({
        GM: t.freeze(w),
        GM_info: t.freeze(s),
        GM_getValue: a,
        GM_getValues: c,
        GM_setValue: u,
        GM_setValues: l,
        GM_deleteValue: d,
        GM_deleteValues: function (e) {
          for (const t of e) d(t);
        },
        GM_listValues: f,
        GM_addStyle: p,
        GM_notification: h,
        GM_setClipboard: y,
        GM_xmlhttpRequest: function (e) {
          const { abortController: t } = b(e);
          if (!e || "object" != typeof e)
            throw new TypeError("Invalid details passed to GM_xmlHttpRequest");
          return { abort: () => t.abort() };
        },
        unsafeWindow: e,
      }).forEach(([r, o]) => {
        t.defineProperty(e, r, {
          value: o,
          writable: !1,
          enumerable: !0,
          configurable: !1,
        });
      });
    })(window, Object, DOMException, AbortController, Promise, localStorage);
  ''';
}
