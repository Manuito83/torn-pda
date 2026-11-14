Archivo 2: Torn PDA - HTTP Handlers

# 📲 Torn PDA - JavaScript HTTP Handlers

## Overview
This document explains how to use Torn PDA's HTTP handlers from JavaScript to perform GET, POST, PUT, PATCH, and DELETE  requests. All handlers return a logical response object similar to GM_xmlHttpRequest().

---

## Handler: PDA_httpGet

This handler performs an HTTP GET request.

### Required Parameters:
- URL: The target URL.
- Headers: An object containing key-value pairs for the request headers.

### Response Object:
- status: HTTP status code.
- statusText: HTTP status text.
- responseText: The response body.
- responseHeaders: A string of response headers with CRLF line terminators.

### Usage Example:
```javascript
const url = 'https://api.example.com/data';
const headers = {
  'Content-Type': 'application/json'
};

window.flutter_inappwebview.callHandler('PDA_httpGet', url, headers)
  .then(response => {
    console.log("GET Response:", response);
  })
  .catch(error => {
    console.error("GET Error:", error);
  });
```

---
<br></br>

## Handler: PDA_httpPost

This handler performs an HTTP POST request.

### Required Parameters:
- URL: The target URL.
- Headers: An object containing key-value pairs for the request headers.
- Body: The content to send. It can be a string or an object (if provided as an object, it will be converted to form fields).

### Response Object:
- status: HTTP status code.
- statusText: HTTP status text.
- responseText: The response body.
- responseHeaders: A string of response headers with CRLF line terminators.

### Usage Example:
```javascript
const url = 'https://api.example.com/data';
const headers = {
  'Content-Type': 'application/json'
};
const body = JSON.stringify({ key: 'value' });

window.flutter_inappwebview.callHandler('PDA_httpPost', url, headers, body)
  .then(response => {
    console.log("POST Response:", response);
  })
  .catch(error => {
    console.error("POST Error:", error);
  });
```

## Notes:
- All HTTP handlers are asynchronous and return promises.
- Ensure that the URL and headers are correctly provided.

---
<br></br>

## Handler: PDA_httpPut

This handler performs an HTTP PUT request.

### Required Parameters:
- URL: The target URL.
- Headers: An object containing key-value pairs for the request headers.
- Body: The content to send. It can be a string or an object (if provided as an object, it will be converted to form fields).

### Response Object:
- status: HTTP status code.
- statusText: HTTP status text.
- responseText: The response body.
- responseHeaders: A string of response headers with CRLF line terminators.

### Usage Example:
```javascript
const url = 'https://api.example.com/data/123';
const headers = {
  'Content-Type': 'application/json'
};
const body = JSON.stringify({ key: 'updatedValue' });

window.flutter_inappwebview.callHandler('PDA_httpPut', url, headers, body)
  .then(response => {
    console.log("PUT Response:", response);
  })
  .catch(error => {
    console.error("PUT Error:", error);
  });
```

---
<br></br>

## Handler: PDA_httpPatch

This handler performs an HTTP PATCH request.

### Required Parameters:
- URL: The target URL.
- Headers: An object containing key-value pairs for the request headers.
- Body: The content to send. It can be a string or an object (if provided as an object, it will be converted to form fields).

### Response Object:
- status: HTTP status code.
- statusText: HTTP status text.
- responseText: The response body.
- responseHeaders: A string of response headers with CRLF line terminators.

### Usage Example:
```javascript
const url = 'https://api.example.com/data/123';
const headers = {
  'Content-Type': 'application/json'
};
const body = JSON.stringify({ field: 'patchedValue' });

window.flutter_inappwebview.callHandler('PDA_httpPatch', url, headers, body)
  .then(response => {
    console.log("PATCH Response:", response);
  })
  .catch(error => {
    console.error("PATCH Error:", error);
  });
```

---
<br></br>

## Handler: PDA_httpDelete

This handler performs an HTTP DELETE request.

### Required Parameters:
- URL: The target URL.
- Headers: An object containing key-value pairs for the request headers.

### Response Object:
- status: HTTP status code.
- statusText: HTTP status text.
- responseText: The response body.
- responseHeaders: A string of response headers with CRLF line terminators.

### Usage Example:
```javascript
const url = 'https://api.example.com/data/123';
const headers = {
  'Content-Type': 'application/json'
};

window.flutter_inappwebview.callHandler('PDA_httpDelete', url, headers)
  .then(response => {
    console.log("DELETE Response:", response);
  })
  .catch(error => {
    console.error("DELETE Error:", error);
  });
```

## When the helpers can be called

`PDA_httpGet`, `PDA_httpPost`, `PDA_httpPut`, `PDA_httpDelete`, `PDA_httpPatch` and `PDA_evaluateJavascript` wait for Torn PDA on their own, so you can call them at any time, also from a `@run-at document-start` script. Since v4.0.0 they start as soon as Torn PDA is ready, usually before the page has finished loading, so a request made in the first lines of a script can return early.

This is how Tampermonkey works too. If your script runs at `document-start` and uses the response to change the page, wait for the elements you need (for example with `DOMContentLoaded` or a `MutationObserver`), since the response may arrive before they exist. Scripts that run at `document-end` (the default) are not affected.

Calling `window.flutter_inappwebview.callHandler` directly is not affected: it still needs the `flutterInAppWebViewPlatformReady` event (see [Platform readiness](webview-handlers.md#platform-readiness-before-calling-a-handler)).
