# 📲 Torn PDA Check Handler

## Overview
This handler is used to verify if your code is running inside Torn PDA. It returns a simple response indicating that the current environment is Torn PDA. It is intended to help developers conditionally execute code based on the app environment

## Handler: isTornPDA

### Usage Example:
```javascript
window.flutter_inappwebview.callHandler('isTornPDA')
  .then(response => {
    if (response.isTornPDA) {
      console.log("Running in Torn PDA");
    } else {
      console.log("Not running in Torn PDA");
    }
  })
  .catch(error => {
    console.error("Error checking Torn PDA:", error);
  });
```

### Response Object:
- `isTornPDA` is `true` when running in Torn PDA.
