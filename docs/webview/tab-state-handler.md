# 📲 Torn PDA - Tab State Handler

## Overview
Provides the tab UID and two flags to user scripts:
- `uid`: UUID v4 per tab (persists while the tab exists, restored from saved sessions when available).
- `isActiveTab`: `true` when the tab is the active Torn PDA browser tab.
- `isWebViewVisible`: `true` when the browser is in foreground (WebView visible).

You can query the current state via handler or subscribe to events to stay in sync.

## Handler: PDA_getTabState

Example:
```javascript
window.flutter_inappwebview.callHandler('PDA_getTabState')
  .then(({ uid, isActiveTab, isWebViewVisible }) => {
    console.log('Tab state', uid, isActiveTab, isWebViewVisible);
  })
  .catch((error) => console.error('Tab state error', error));
```

## Event: tornpda:tabState

The app dispatches a `CustomEvent` with the same payload:
```javascript
window.addEventListener('tornpda:tabState', (event) => {
  const { uid, isActiveTab, isWebViewVisible } = event.detail;
  console.log('Tab event', uid, isActiveTab, isWebViewVisible);
});
```

**When it fires:**
- On tab activation switches.
- When the browser goes foreground/background.
- After navigation loads/resumes (keeps scripts synced even after sleeping tabs).

## Injected helpers
These are convenience caches set by the app at document start; the handler/event is what keeps them fresh. You can read them right away, but call the handler or listen to the event to be sure you have the latest values.

- `window.__tornpda.tab.uid` → The tab UID injected at document start.
- `window.__tornpda.tab.state` → Last known `{ uid, isActiveTab, isWebViewVisible }` snapshot.


## Full code example (handler + listener)

```javascript
(async () => {
  // Fetch UID, isActiveTab, and isWebViewVisible in a single call
  const { uid, isActiveTab, isWebViewVisible } = await window.flutter_inappwebview.callHandler('PDA_getTabState');
    console.log(`[PDA handler ${new Date().toISOString()}] uid=${uid} active=${isActiveTab} visible=${isWebViewVisible}`);

  // Stay in sync with any change (active tab or webview visibility)
  window.addEventListener('tornpda:tabState', (event) => {
    const { uid, isActiveTab, isWebViewVisible } = event.detail;
      console.log(`[PDA listener ${new Date().toISOString()}] uid=${uid} active=${isActiveTab} visible=${isWebViewVisible}`);
  });
})();
```

Result:

```text
[PDA handler 2026-01-04T18:23:06.716Z] uid=8e7c0f96-a9b2-4f2b-9a7b-135e8c9c1d2f active=true visible=true
[PDA listener 2026-01-04T18:23:05.820Z] uid=8e7c0f96-a9b2-4f2b-9a7b-135e8c9c1d2f active=true visible=true
```
