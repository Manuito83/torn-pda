# 📲 Torn PDA - Toast Handler

## Overview
This handler allows you to display toast messages within Torn PDA. Use it to provide feedback or notifications to users from your JavaScript code within the Torn PDA WebView environment.

## Handler: `showToast`

### Parameters:
| Parameter    | Type    | Required | Default                           | Description                                 |
|--------------|---------|----------|-----------------------------------|---------------------------------------------|
| `text`       | String  | ✅ Yes   | N/A                               | The message text displayed on the toast     |
| `clickClose` | Boolean | ❌ No    | `false`                           | Closes toast when tapped                    |
| `seconds`    | Integer | ❌ No    | `3`                               | Duration the toast appears on screen        |
| `bgColor`    | Object  | ❌ No    | `{a:255,r:0,g:0,b:255}` (blue)    | ARGB values for toast background            |
| `textColor`  | Object  | ❌ No    | `{a:255,r:255,g:255,b:255}` (white)| ARGB values for toast text color            |

- If `text` is omitted or empty, no toast will be displayed.

### Usage Example:
```javascript
window.flutter_inappwebview.callHandler('showToast', {
  text: '📱 Welcome to Torn PDA! 📱',
  clickClose: true,
  seconds: 5,
  bgColor: { a: 255, r: 204, g: 153, b: 0 }, // Dark yellow background
  textColor: { a: 255, r: 0, g: 0, b: 0 } // Black text
})
.then(response => {
  console.log(response.message);
})
.catch(error => {
  console.error("Error showing toast:", error);
});