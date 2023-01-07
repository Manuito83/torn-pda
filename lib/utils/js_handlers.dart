String handler_flutterPlatformReady() {
  return '''
    // Initialize event listener for other handlers
    const __PDA_platformReadyPromise = new Promise(resolve => {
        window.addEventListener("flutterInAppWebViewPlatformReady", resolve);
    });
  ''';
}

String handler_pdaAPI() {
  return '''
    // Performs a GET request to the provided URL
    // Returns a promise for a response object that has these properties:
    //     responseHeaders - String, with CRLF line terminators.
    //     responseText
    //     status
    //     statusText
    async function PDA_httpGet(url) {
        await __PDA_platformReadyPromise;
        return window.flutter_inappwebview.callHandler("PDA_httpGet", url);
    }

    // Performs a POST request to the provided URL
    // The expected arguments are:
    //     url
    //     headers - Object with key, value string pairs 
    //     body - String or Object with key, value string pairs. If it's an object,
    //            it will be encoded as form fields
    // Returns a promise for a response object that has these properties:
    //     responseHeaders: String, with CRLF line terminators.
    //     responseText
    //     status
    //     statusText
    async function PDA_httpPost(url, headers, body) {
        await __PDA_platformReadyPromise;
        return window.flutter_inappwebview.callHandler("PDA_httpPost", url, headers, body);
    }
  ''';
}

String handler_evaluateJS() {
  return '''
    // Allows scripts to evaluate javascript source code directly from PDA's webview
    // Might be useful if the source code being evaluated is not yet known, but obtained from
    // a different source, because Torn won't allow execution of eval()
    async function PDA_evaluateJavascript(source) {
        await __PDA_platformReadyPromise;
        return window.flutter_inappwebview.callHandler("PDA_evaluateJavascript", source);
    }
  ''';
}
