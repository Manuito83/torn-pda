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
    if (typeof GMforPDAversion === 'undefined') {

      const GMforPDAversion = 0.2;

      if (!window.flutter_inappwebview) {
        throw new Error(
            "GMforPDA requires flutter_inappwebview to be defined. Ensure this script is running inside of PDA."
        );
      }

      window.GM = {
        
        GMforPDAversion,

        getValue(key, defaultValue) {
            return localStorage.getItem(key) ?? defaultValue;
        },

        setValue(key, value) {
            localStorage.setItem(key, value);
        },

        deleteValue(key) {
            localStorage.removeItem(key);
        },

        listValues() {
            return Object.values(localStorage);
        },

        addStyle(style) {
            if (!style) return;
            const s = document.createElement("style");
            s.type = "text/css";
            s.innerHTML = style;

            document.head.appendChild(s);
        },

        setClipboard(text) {
            if (!document.hasFocus())
                throw new DOMException("Document is not focused");
            navigator.clipboard.writeText(text);
        },

        async xmlhttpRequest(details) {
            try {
                if (!details || typeof details !== "object")
                    throw new TypeError(
                        "Invalid details passed to GM.xmlHttpRequest"
                    );
                let { url, method, data, body, headers, onload, onerror } =
                    details;
                if (!url || !(typeof url === "string" || url instanceof URL))
                    throw new TypeError("Invalid url passed to GM.xmlHttpRequest");
                if ((method && typeof method !== "string"))
                    throw new TypeError(
                        "Invalid method passed to GM.xmlHttpRequest"
                    );
                if (!method || method.toLowerCase() === "get") {
		    const h = headers ?? {};
		    h["X-GMforPDA"] = "Sent from PDA via GMforPDA";
                    return await PDA_httpGet(url, h ?? {})
                        .then(onload ?? ((x) => x))
                        .catch(onerror ?? ((e) => console.error(e)));
                } else if (method.toLowerCase() === "post") {
                    const h = headers ?? {};
                    h["X-GMforPDA"] = "Sent from PDA via GMforPDA";
                    url = url instanceof URL ? url.href : url;
                    return await PDA_httpPost(url, h ?? {}, body ?? data ?? "")
                        .then(onload ?? ((x) => x))
                        .catch(onerror ?? ((e) => console.error(e)));
                } else
                    throw new TypeError(
                        "Invalid method passed to GM.xmlHttpRequest"
                    );
            } catch (e) {

                console.error(
                    "An uncaught error occured in GM.xmlHttpRequest - please report this in the PDA discord if this is unexpected. The error is above ^ "
                );
                console.error(e instanceof Error ? e : JSON.stringify(e));
                throw e instanceof Error ? e : new Error(e);
            }
        },

        notification(...args) {
            let text, title, onclick, ondone;
            if (typeof args[0] === "string") {
                [text, title, , onclick] = args;
            } else {
                ({ text, title, onclick, ondone } = args[0]);
            }
            const alert =
                (title
                    ? `Notification from script \${title}:`
                    : "Notification from unnamed source:") +
                "\\n" +
                text;
            if (confirm(alert)) onclick?.();
            return ondone?.();
        },

        openInTab(url) {
            if (!url) throw TypeError("No URL provided to GM.openInTab");
            window.open(url, "_blank");
        },

        info: {
            script: {
                description: "This information is unavailable in TornPDA",
                excludes: [],
                includes: [],
                matches: [],
                name: undefined,
                namespace: undefined,
                resources: {},
                "run-at": undefined,
                version: undefined,
            },
            scriptMetaStr: "This information is unavailable in TornPDA",
            scriptHandler: `TornPDA, using GMforPDA version \${GMforPDAversion}`,
            version: GMforPDAversion,
        },

      },

      Object.entries(GM).forEach(([k, v]) => window[`GM_\${k}`] = v);
    }
   ''';
}
