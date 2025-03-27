Archivo 2: Torn PDA - HTTP Handlers

# 📲 Torn PDA - JavaScript HTTP Handlers

## Overview
This document explains how to use Torn PDA's HTTP handlers from JavaScript to perform GET and POST requests. Both handlers return a logical response object similar to GM_xmlHttpRequest().

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
- Both HTTP handlers are asynchronous and return promises.
- Ensure that the URL and headers are correctly provided.

