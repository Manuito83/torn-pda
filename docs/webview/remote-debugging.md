# Remote debugging of the Torn PDA browser

Torn PDA's browser is the WebView of the phone, so you can open the same developer tools you use on a desktop and point them at it: console, DOM inspector, network panel and breakpoints. This is the fastest way to find out why a userscript fails on mobile.

Index:

- [Remote debugging of the Torn PDA browser](#remote-debugging-of-the-torn-pda-browser)
  - [1. Turn it on in Torn PDA](#1-turn-it-on-in-torn-pda)
  - [2. Android](#2-android)
  - [3. iOS](#3-ios)
  - [4. Examples for userscripts](#4-examples-for-userscripts)
  - [5. Known limits](#5-known-limits)

## 1. Turn it on in Torn PDA

Go to Settings, **Advanced browser settings** (in the Browser section), and enable **Allow remote debugging** under Maintenance. Then **restart the app**, as the setting itself says.

Two warnings, both shown in the setting's own description:

- While it is enabled, Google sign-in inside the browser may not work.
- Turn it off when you are done. It is meant for development, not for everyday use.

What the setting does on each platform:

| Platform | Effect |
|---|---|
| Android | Calls `setWebContentsDebuggingEnabled(true)` at startup. In Android this applies to every WebView of the app. |
| iOS | Sets `isInspectable` on each WebView window listed below. Apple requires iOS 16.4 or later for this property. |

On iOS, these windows can be inspected once the setting is on:

- The main browser (every tab).
- The trades browser (the one opened from the trades widget).
- The simple dialogs (for example the page that opens to create an API key, or the wiki pages).
- The chat link window.
- The chain mini window.

The engine of the native chat is only inspectable in debug builds of the app, so you cannot inspect it from a release build, with or without the setting.

## 2. Android

You need a computer with Chrome, a USB cable and the phone with Torn PDA.

1. On the phone, enable **Developer options** and, inside them, **USB debugging**. Android's own guide: <https://developer.android.com/studio/debug/dev-options>.
2. Connect the phone to the computer with the cable. The first time, the phone asks you to authorize the computer: accept.
3. In Chrome on the computer, open `chrome://inspect#devices` and make sure **Discover USB devices** is checked.
4. Open Torn PDA on the phone and load the page you want to debug.
5. Refresh `chrome://inspect#devices`. The phone appears by its model name, and every app that uses a WebView gets its own section. Look for the Torn PDA section.
6. Click **inspect** under the page. A DevTools window opens, connected to that page.

How to tell the Torn PDA entry from the rest: Chrome tabs are listed in their own section, separate from the apps. Inside the Torn PDA section, the entry with the URL of the page you have open (for example the Torn page) is your tab. If you have several tabs open, they can appear as several entries, so check the URL and use **Select Element** or the console to confirm which one you are looking at.

If nothing shows up in the list, confirm that the setting is on and the app was restarted, open the page on the phone, and refresh `chrome://inspect`.

Debugging over Wi-Fi: Chrome's remote debugging page only describes the USB workflow, and mentions that adb can also connect over Wi-Fi, linking to Android's adb documentation.

Sources: [Remote debug Android devices](https://developer.chrome.com/docs/devtools/remote-debugging), [Remote debugging WebViews](https://developer.chrome.com/docs/devtools/remote-debugging/webviews).

## 3. iOS

You need a Mac with Safari, a cable and the iPhone with Torn PDA.

1. On the iPhone, enable **Web Inspector** in Settings, Safari, Advanced (in recent iOS versions the path is Settings, Apps, Safari, Advanced).
2. On the Mac, open Safari, then Safari, Settings, Advanced, and enable **Show features for web developers** (older Safari versions call it "Show Develop menu in menu bar"). The **Develop** menu appears in the menu bar.
3. Connect the iPhone to the Mac with a cable, unlock it and accept **Trust This Computer** if it asks.
4. Open Torn PDA on the iPhone and load the page you want to debug.
5. In Safari on the Mac, open **Develop**, then the name of your iPhone, then the page. Web Inspector opens.

Requirements and behavior:

- The app must mark its WebView as inspectable. Torn PDA does it when the setting from step 1 is on. Apple introduced `isInspectable` in iOS 16.4 and macOS 13.3; apps built with that SDK are not inspectable unless they set it. So on an iPhone with iOS older than 16.4 this guide does not apply as written.
- Each inspectable WebView appears under your iPhone in the Develop menu, named after the page it has loaded.
- The Develop menu has a **Connect via Network** option for an iPhone that has already been paired by cable.

Without a Mac: Safari's Web Inspector for an iPhone is a Mac feature, and Apple's documentation does not offer another route. If you do not have a Mac, the practical options are to debug the script's logic on Android or in a desktop browser, and on the iPhone to show values with the [toast handler](./toast-handler.md) or write them to the page.

Sources: [Inspecting iOS and iPadOS](https://developer.apple.com/documentation/safari-developer-tools/inspecting-ios), [Enabling features for web developers](https://developer.apple.com/documentation/safari-developer-tools/enabling-developer-features), [Enabling the inspection of web content in apps](https://webkit.org/blog/13936/enabling-the-inspection-of-web-content-in-apps/).

## 4. Examples for userscripts

The console and the debugger are the same in Chrome DevTools and Safari Web Inspector for what follows. Examples use the names documented in [JavaScript-webview communication](./webview-handlers.md).

### See the errors of a script

Open the Console tab with the page loaded. Errors thrown by your script, and everything it prints with `console.log`, `console.warn` and `console.error`, appear there. Reload the page with the console open to catch errors that happen at load time.

Torn PDA runs your script inside a function, so its variables are not visible from the console. To look at one, expose it temporarily:

```javascript
window.__debug = { items }; // remove when done
```

and then type `__debug` in the console.

### Call a PDA handler from the console

Handlers are available as `window.flutter_inappwebview.callHandler`. In the console, once the page has loaded, you can call one and print its answer:

```javascript
window.flutter_inappwebview.callHandler('isTornPDA').then(console.log);
```

The response has an `isTornPDA` field (see the [check handler](./torn-pda-check-handler.md)). Another one that takes no arguments is `PDA_getTabState`, documented in the [tab state handler](./tab-state-handler.md):

```javascript
window.flutter_inappwebview.callHandler('PDA_getTabState').then(console.log);
```

It answers with `uid`, `isActiveTab`, `isWebViewVisible` and `isOnScreen`. A handler with parameters, such as `showToast`, is called the same way (see the [toast handler](./toast-handler.md)):

```javascript
window.flutter_inappwebview
  .callHandler('showToast', { text: 'Hello from the console', seconds: 3 })
  .then(console.log);
```

If `callHandler` is not defined, the platform is not ready yet or the page is not running inside Torn PDA. See [Platform readiness before calling a handler](./webview-handlers.md#platform-readiness-before-calling-a-handler).

### Pause a script with a breakpoint

The simplest way is to write `debugger;` where you want to stop. When DevTools (or Web Inspector) is attached, the script pauses on that line, and you can inspect local variables, step through the code and look at the call stack.

```javascript
const rows = document.querySelectorAll('.some-row');
debugger; // the script pauses here while DevTools is attached
rows.forEach((row) => {
  // ...
});
```

Chrome also offers other breakpoints (conditional, logpoints, XHR, event listeners and pause on exceptions) in the Sources panel. See [Pause your code with breakpoints](https://developer.chrome.com/docs/devtools/javascript/breakpoints).

## 5. Known limits

- Google sign-in inside the browser may fail while the setting is on.
- The setting is read when the app starts, so restart after changing it.
- The native chat engine is not inspectable in release builds.
- On iOS, only the windows listed in section 1 are inspectable.

See also: [GM compatibility](../userscripts/gm-compatibility.md) for the GM functions available to scripts.
