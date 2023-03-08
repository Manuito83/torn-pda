// Initialize event listener for other handlers
const __PDA_platformReadyPromise = new Promise(resolve => {
    window.addEventListener("flutterInAppWebViewPlatformReady", resolve);
});


