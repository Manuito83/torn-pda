# 📲 Torn PDA Page Reload Handler

## Overview
This handler instructs the native side of Torn PDA to reload the current page. It was created to overcome issues on platforms (e.g., Android) where `window.location.reload()` does not work properly due when using WebView events such as `ShouldOverrideURLLoading` (as Torn PDA does). Use this handler to reliably reload the page across all platforms.

## Handler: reloadPage

### Usage Example:
```javascript
window.flutter_inappwebview.callHandler('reloadPage')
  .then(() => {
    console.log("Page reloaded successfully");
  })
  .catch(error => {
    console.error("Error reloading page:", error);
  });