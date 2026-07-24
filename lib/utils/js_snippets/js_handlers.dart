// ignore_for_file: non_constant_identifier_names

// Project imports:
import 'package:torn_pda/utils/js_snippets/remote_snippets.dart';

String handler_flutterPlatformReady() {
  return '''
    // Initialize event listener for other handlers
    // Attached to window so it survives injection-time scope wrapping: some webviews wrap
    // document-start scripts in a block/closure, which would keep bare declarations local
    if (typeof window.__PDA_platformReadyPromise === 'undefined') {
        window.__PDA_platformReadyPromise = new Promise(resolve => {
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

String handler_activeTabFocus() {
  // Android WebView often reports document.hasFocus()=false even when visible
  // When PDA knows this tab is the active, visible one, report focus so scripts (isPageActive) work
  return '''
		(function() {
			if (window.__pdaActiveTabFocus) return;
			window.__pdaActiveTabFocus = true;
			const real = document.hasFocus ? document.hasFocus.bind(document) : function() { return true; };
			document.hasFocus = function() {
				try {
					const s = window.__tornpda && window.__tornpda.tab && window.__tornpda.tab.state;
					if (s && s.isActiveTab && s.isWebViewVisible) return true;
				} catch (_) {}
				return real();
			};
		})();
	''';
}

String handler_pdaAPI() {
  // PDA HTTP helpers (PDA_httpGet/Post/Put/Delete/Patch)
  return RemoteSnippets.resolve(RemoteSnippets.pdaApi);
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

    (function() {
      window.loadedPdaApiEvalScripts = window.loadedPdaApiEvalScripts || {};

      window.PDA_evaluateJavascript = async function(source) {
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
    })();
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
          const r = i ? i.getItem(e) : null;
          if ("string" != typeof r) return t;
          if (!r.startsWith("GMV2_")) return r ?? t;
          const json = r.slice(5);
          // Guard against "GMV2_undefined" written by a buggy GM_setValue call
          if (json === "undefined") return t;
          return (JSON.parse(json) ?? t);
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
        if (!i) return;
        // JSON.stringify(undefined) returns the JS value undefined (not the string),
        // which string-concatenates to "GMV2_undefined" — unreadable by JSON.parse.
        // Treat that the same as deleting the key.
        const serialized = JSON.stringify(t);
        if (serialized === undefined) { i.removeItem(e); return; }
        try {
          i.setItem(e, "GMV2_" + serialized);
        } catch (err) {
          console.warn("PDA-GM: localStorage full, GM_setValue('" + e + "') dropped", err);
          try {
            const now = Date.now();
            if (!window.__pdaGMQuotaToastAt || now - window.__pdaGMQuotaToastAt > 60000) {
              window.__pdaGMQuotaToastAt = now;
              window.flutter_inappwebview && window.flutter_inappwebview.callHandler("showToast", {
                text: "A userscript ran out of browser storage. Some data was not saved.",
                seconds: 5,
                bgColor: { a: 255, r: 230, g: 145, b: 0 }
              });
            }
          } catch (_) {}
        }
      }
      function l(e) {
        for (const [r, o] of t.entries(e)) u(r, o);
      }
      function d(e) {
        if (!e) throw new TypeError("No key supplied to GM_deleteValue");
        i?.removeItem(e);
      }
      function f() {
        return i ? t.keys(i) : [];
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
    })(window, Object, DOMException, AbortController, Promise,
       // Safe-capture localStorage: accessing it throws SecurityError in some
       // contexts (restrictive iframes, private-mode storage blocked, etc.).
       // Passing null lets the GM functions degrade gracefully instead of
       // aborting the entire IIFE and leaving GM/GM_getValue/... undefined.
       // Warn once, or a storage-less page silently drops every userscript with nothing in the log.
       // about: pages are ours (parking, prewarm) and always land here, so they stay quiet
       (() => { try { return localStorage; } catch (_) {
          if (!window.__pdaGMStoreWarned && location.protocol !== "about:") {
            window.__pdaGMStoreWarned = true;
            console.warn("PDA-GM: localStorage denied at " + location.href + ", GM values are unavailable here");
          }
          return null;
       } })());
  ''';
}
