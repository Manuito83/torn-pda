// ignore_for_file: non_constant_identifier_names

String handler_flutterPlatformReady() {
  return '''
    // Initialize event listener for other handlers
    var __PDA_platformReadyPromise;
    if(typeof __PDA_platformReadyPromise === 'undefined') {
        __PDA_platformReadyPromise = new Promise(resolve => {
            //console.log("Handler: pdaHandler_platformReady");
            window.addEventListener("flutterInAppWebViewPlatformReady", resolve);
        });
    }
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
    //
    // NOTE: in order to make the function available ASAP and ensure compatibility is all operating systems, 
    // it will be declared several times while the page loads. However, it will only accept one call with the same
    // URL as a parameter each second
    // 
    //
    // Example call:
    //
    // PDA_httpGet('https://api.example.com/data').then(response => {
    //     console.log(response);
    // }).catch(error => {
    //     console.error(error);
    // });
    
    // Check if loadedPdaApiGetUrls has been declared before. If not, declare it.
    if (typeof loadedPdaApiGetUrls === 'undefined') {
        var loadedPdaApiGetUrls = {};
    }

    async function PDA_httpGet(url) {
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
          
        return window.flutter_inappwebview.callHandler("PDA_httpGet", url);
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
