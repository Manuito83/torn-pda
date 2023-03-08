// Allows scripts to evaluate javascript source code directly from PDA's webview
// Might be useful if the source code being evaluated is not yet known, but obtained from
// a different source, because Torn won't allow execution of eval()
async function PDA_evaluateJavascript(source) {
    await __PDA_platformReadyPromise;
    return window.flutter_inappwebview.callHandler("PDA_evaluateJavascript", source);
}


