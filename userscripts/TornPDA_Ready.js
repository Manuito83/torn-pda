// Initialize event listener for other handlers
// Ready event, or the app answering first
const __PDA_platformReadyPromise = new Promise(resolve => {
    if (window.flutter_inappwebview?._platformReady) return resolve();
    let ready = false;
    const done = () => { ready = true; resolve(); };
    window.addEventListener("flutterInAppWebViewPlatformReady", done);
    let tries = 0;
    (function ping() {
        if (ready) return;
        const bridge = window.flutter_inappwebview;
        if (bridge && typeof bridge.callHandler === "function") {
            bridge.callHandler("PDA_handlersReady").then(r => { if (r === true) done(); }, () => {});
        } else if (++tries < 100) {
            setTimeout(ping, 10);
        }
    })();
});
