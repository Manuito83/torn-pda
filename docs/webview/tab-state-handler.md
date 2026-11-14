# 📲 Torn PDA - Tab State Handler

## Overview
Provides the tab UID and three flags to user scripts:
- `uid`: UUID v4 per tab (persists while the tab exists, restored from saved sessions when available).
- `isActiveTab`: `true` when the tab is the active Torn PDA browser tab. With two browsers side by side, it is the one with the focus (the panel the user last touched); there is never more than one active tab.
- `isWebViewVisible`: `true` when the browser is in foreground (WebView visible).
- `isOnScreen`: `true` when this tab is being shown right now.

### `isActiveTab` vs `isOnScreen`
On wide screens (800 points or more) the player can show two browsers side by side. Both tabs are on screen and running, but only one of them is the active tab:

| Layout | Active tab | Tab in the other panel | Any other tab |
|---|---|---|---|
| Single browser | `isActiveTab: true`, `isOnScreen: true` | | `false`, `false` |
| Two browsers side by side | `isActiveTab: true`, `isOnScreen: true` | `isActiveTab: false`, `isOnScreen: true` | `false`, `false` |

With a single browser `isOnScreen` is always `isActiveTab && isWebViewVisible`, so existing scripts lose nothing. Use `isOnScreen` to decide whether to keep refreshing what the player can see (timers, polling, animations), and `isActiveTab` for things that should only happen in one tab at a time (sounds, notifications, grabbing the keyboard focus).

You can query the current state via handler or subscribe to events to stay in sync.

## Handler: PDA_getTabState

Example:
```javascript
window.flutter_inappwebview.callHandler('PDA_getTabState')
  .then(({ uid, isActiveTab, isWebViewVisible, isOnScreen }) => {
    console.log('Tab state', uid, isActiveTab, isWebViewVisible, isOnScreen);
  })
  .catch((error) => console.error('Tab state error', error));
```

## Event: tornpda:tabState

The app dispatches a `CustomEvent` with the same payload:
```javascript
window.addEventListener('tornpda:tabState', (event) => {
  const { uid, isActiveTab, isWebViewVisible, isOnScreen } = event.detail;
  console.log('Tab event', uid, isActiveTab, isWebViewVisible, isOnScreen);
});
```

**When it fires:**
- On tab activation switches.
- When the browser goes foreground/background.
- After navigation loads/resumes (keeps scripts synced even after sleeping tabs).
- With two browsers side by side, when a tab starts or stops being shown in a panel without becoming active (for example, when the second panel opens or closes, or the app covers one of them).

## Injected helpers
These are convenience caches set by the app at document start; the handler/event is what keeps them fresh. You can read them right away, but call the handler or listen to the event to be sure you have the latest values.

- `window.__tornpda.tab.uid` → The tab UID injected at document start.
- `window.__tornpda.tab.state` → Last known `{ uid, isActiveTab, isWebViewVisible, isOnScreen }` snapshot.


## Full code example (handler + listener)

```javascript
(async () => {
  // Fetch UID, isActiveTab, isWebViewVisible and isOnScreen in a single call
  const { uid, isActiveTab, isWebViewVisible, isOnScreen } = await window.flutter_inappwebview.callHandler('PDA_getTabState');
    console.log(`[PDA handler ${new Date().toISOString()}] uid=${uid} active=${isActiveTab} visible=${isWebViewVisible} onScreen=${isOnScreen}`);

  // Stay in sync with any change (active tab, webview visibility or panels on screen)
  window.addEventListener('tornpda:tabState', (event) => {
    const { uid, isActiveTab, isWebViewVisible, isOnScreen } = event.detail;
      console.log(`[PDA listener ${new Date().toISOString()}] uid=${uid} active=${isActiveTab} visible=${isWebViewVisible} onScreen=${isOnScreen}`);
  });
})();
```

Result, with two browsers side by side: the script starts in the tab of the panel without the focus, which is on screen but not active, and then that panel gets the focus:

```text
[PDA handler 2026-10-09T00:42:43.356Z] uid=dbaa70a1-f3bd-4453-8d6d-9025c92dede1 active=false visible=true onScreen=true
[PDA listener 2026-10-09T00:42:58.534Z] uid=dbaa70a1-f3bd-4453-8d6d-9025c92dede1 active=true visible=true onScreen=true
```
