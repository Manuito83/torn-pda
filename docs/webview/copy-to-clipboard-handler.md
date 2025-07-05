# 📲 Torn PDA - Copy to Clipboard Handler

## Overview

This handler allows the native side of Torn PDA to copy a given text string to the device's clipboard. It was created to provide a reliable and unified way to copy text, bypassing potential browser compatibility issues or permissions with standard clipboard APIs (`document.execCommand('copy')` or the asynchronous Clipboard API).

## Handler: copyToClipboard

This handler expects one argument: the string of text that you want to copy to the clipboard.

### Usage Example:

```javascript
const textToCopy = "Hello Manuito!";

window.flutter_inappwebview
  .callHandler("copyToClipboard", textToCopy)
  .then(() => {
    console.log("Text copied to clipboard successfully");
  })
  .catch((error) => {
    console.error("Error copying to clipboard:", error);
  });
```
