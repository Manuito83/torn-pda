# Javascript-webview communication

From JS code, you can communicate with the native (Flutter) side of Torn PDA, which offers some additional capabilities (such as notifications) and also helps to overcome restrictions imposed by Torn (such as cross-origin http requests).

Index:

- [Platform readiness before calling a handler](#platform-readiness-before-calling-a-handler)
- [Utility handlers](#utility-handlers)
- [HTTP handlers](#http-handlers)
- [Notification handlers](#notification-handlers)
  <br></br>

## Platform readiness before calling a handler

The main communication with the native side of Torn PDA takes place by using `window.flutter_inappwebview.callHandler` either inside a JavaScript file or within a `<script>` tag in your HTML.

If you expect to call this as soon as possible while the page is loading, **you need to wait for the underlying Flutter InAppWebView platform to be ready**. This readiness is signaled by the dispatch of the flutterInAppWebViewPlatformReady event. Once this event fires, the callHandler method becomes fully available, allowing you to safely execute your calls.

There are two common approaches to ensure you only call callHandler after the platform is ready:

1. Using an event listener:
   Attach an event listener to the flutterInAppWebViewPlatformReady event and execute your callHandler code within the callback. For example:

   ```javascript
   window.addEventListener(
     "flutterInAppWebViewPlatformReady",
     function (event) {
       window.flutter_inappwebview
         .callHandler("isTornPDA")
         .then((response) => {
           if (response.isTornPDA) {
             console.log("Running in Torn PDA");
           } else {
             console.log("Not running in Torn PDA");
           }
         })
         .catch((error) => {
           console.error("Error checking Torn PDA:", error);
         });
     }
   );
   ```

2. Using a global flag variable:
   Set a global flag variable when the flutterInAppWebViewPlatformReady event is dispatched, and check this flag before calling callHandler anywhere in your code. For example:

   ```javascript
   // First set a global flag when the platform is ready
   var isFlutterReady = false;
   window.addEventListener(
     "flutterInAppWebViewPlatformReady",
     function (event) {
       isFlutterReady = true;
     }
   );

   // Later in your code, check the flag before calling "isTornPDA"
   if (isFlutterReady) {
     window.flutter_inappwebview
       .callHandler("isTornPDA")
       .then((response) => {
         if (response.isTornPDA) {
           console.log("Running in Torn PDA");
         } else {
           console.log("Not running in Torn PDA");
         }
       })
       .catch((error) => {
         console.error("Error checking Torn PDA:", error);
       });
   } else {
     console.log("Platform not ready yet.");
   }
   ```

Using either of these approaches ensures that your code will not attempt to call callHandler before the platform is ready, thereby preventing errors or unexpected behavior.

<br></br>

## Utility handlers

- [Torn PDA Check Handler](./torn-pda-check-handler.md) – Check if running in Torn PDA.
- [Evaluate JavaScript Handler](./evaluate-js-handler.md) – Execute JavaScript code fetched from external sources.
- [Reload page Handler](./reload-page-handler.md) – Reload the page in the native webview from the app (fix for `window.location.reload`in some devices)
- [Toast Handler](./toast-handler.md) – Display toast messages within Torn PDA
- [PDA Intent Handler](./pda-intent-handler.md) – Launch external applications like Discord using a custom URL scheme.

<br></br>

## HTTP handlers

- [HTTP Handlers](./http-handlers.md) – HTTP GET and POST handlers for data fetching.

<br></br>

## Notification handlers

- [User scripts notification handlers](./notification-handlers.md), in order to trigger notifications, alarms (Android) and timers (Android) directly from user scripts.
- [HTML source code](./notification-handlers.md) of the [example website](https://info.tornpda.com/notifications-test.html), which serves as a sandbox for testing notifications, alarms, and timers for Torn PDA using JavaScript code.
