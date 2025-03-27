# 📲 Torn PDA - JavaScript Evaluation Handler

## Overview
This handler allows you to execute arbitrary JavaScript code within the Torn PDA app's webview. It is useful for running dynamically loaded or generated code when direct use of eval() is restricted.

## Handler: PDA_evaluateJavascript

### Required Parameter:
- Source: A string containing the JavaScript code to be evaluated.

### Usage Example:
```javascript
const code = `
  console.log("Hello from an usercript!");
`;

window.flutter_inappwebview.callHandler('PDA_evaluateJavascript', code)
  .then(() => {
    console.log("JavaScript evaluated successfully");
  })
  .catch(error => {
    console.error("Evaluation Error:", error);
  });
```

---
<br></br>
### Combined Example: Fetch and Evaluate JavaScript Code
This example demonstrates how to combine the HTTP GET handler with the Evaluate JavaScript handler.
In this scenario, JavaScript source code is fetched from an external URL and then executed within the webview.


```javascript
let codeUrl = 'https://example.com/my-script.js';
window.flutter_inappwebview.callHandler('PDA_httpGet', codeUrl, { 'Content-Type': 'text/plain' })
  .then(response => {
    // Assuming the fetched code is available in response.responseText
    let code = response.responseText;
    window.flutter_inappwebview.callHandler('PDA_evaluateJavascript', code)
      .then(() => {
        console.log('JavaScript code has been fetched and executed');
      })
      .catch(error => {
        console.error('Error while evaluating the fetched JavaScript code:', error);
      });
  })
  .catch(error => {
    console.error('Error while fetching JavaScript code:', error);
  });
```

## Notes:
- This handler does not return a value upon successful execution.
- Any errors during code evaluation should be handled in the promise's catch block.