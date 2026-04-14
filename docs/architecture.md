# Torn PDA - Architecture Overview

A high-level map of how the app is wired together, aimed at contributors who want to understand the codebase before diving in.

---

## Table of Contents

- [Project Layout](#project-layout)
- [App Startup](#app-startup)
- [Widget Tree](#widget-tree)
- [Navigation](#navigation)
- [State Management](#state-management)
- [WebView System](#webview-system)
- [Userscript Pipeline](#userscript-pipeline)
- [API Layer](#api-layer)
- [Data Persistence](#data-persistence)
- [Notification System](#notification-system)
- [Key Dependencies](#key-dependencies)

---

## Project Layout

```
lib/
 ├── main.dart                   # Entry point, provider registration, Firebase init
 ├── drawer.dart                 # Drawer-based navigation (3.4k lines)
 ├── config/                     # Private config stubs (API keys, feature flags)
 ├── models/                     # Data classes, API models, Swagger-generated code
 │   └── api_v2/                 # Chopper + Swagger generated Torn API V2 models
 ├── pages/                      # Feature screens (profile, chaining, travel, etc.)
 ├── providers/                  # State management — Provider + GetX controllers
 │   └── api/                    # API caller, V1 & V2 endpoint definitions
 ├── utils/                      # Helpers: JS snippets, notifications, storage
 │   ├── js_snippets/            # Injected JavaScript (HTTP handlers, GM bridge, quick items)
 │   ├── webview/                # WebView handlers (Dart ↔ JS bridge)
 │   └── live_activities/        # iOS Live Activities bridge
 ├── widgets/                    # Reusable components
 │   └── webviews/               # Core browser: tabs, FAB, dialogs, dev tools
 └── torn-pda-native/            # Native auth & stats modules (stubs in public repo)

userscripts/                     # Bundled JS: TornPDA_API, GMforPDA, example scripts
cloud_functions/                  # Firebase Cloud Functions (Node.js)
docs/                            # Developer documentation (you are here)
```

---

## App Startup

`main.dart` orchestrates a sequential initialization before handing off to the widget tree.

```mermaid
flowchart TD
    A[main] --> B[WidgetsFlutterBinding]
    B --> C[Firebase.initializeApp]
    C --> D[SharedPreferences]
    D --> E[MyApp.initState]

    E --> F1[_initializeAppCompilation]
    E --> F2[_initializePlatformSpecifics]
    E --> F3[_initializeBackupAndTheme]
    E --> F4[_initializeFirebase]
    E --> F5[_initializeWorkManager]
    E --> F6[_initializeGetXControllers]
    E --> F7[_initializeSendbird]
    E --> F8[_initializeNotifications]
    E --> F9[_initializePlatformPlugins]
    E --> F10[_initializeAudioAndConnectivity]

    F6 --> G1[UserController]
    F6 --> G2[ApiCallerController]
    F6 --> G3[ChainStatusController]
    F6 --> G4[StakeoutsController]
    F6 --> G5[SendbirdController]
    F6 --> G6[AudioController]
    F6 --> G7[+ 5 more GetX controllers]
```

All `ChangeNotifierProvider`s are registered in the `MultiProvider` wrapping `MyApp`. GetX controllers are registered via `Get.put()` during init.

---

## Widget Tree

```mermaid
flowchart TD
    MP[MultiProvider ×16 providers] --> MA[MaterialApp]
    MA --> FB[FutureBuilder — waits for init]
    FB --> C2[Consumer2 — Settings + WebView]

    C2 -->|normal mode| IS[IndexedStack]
    IS -->|index 0| DP[DrawerPage]
    IS -->|index 1| WS[WebViewStackView]

    C2 -->|split screen| ROW[Row]
    ROW --> DP2[DrawerPage]
    ROW --> WS2[WebViewStackView]

    WS --> TAB1[WebViewFull — Tab 1]
    WS --> TAB2[WebViewFull — Tab 2]
    WS --> TABN[WebViewFull — Tab N]
```

`IndexedStack` keeps both the drawer and browser alive in memory. `WebViewStackView` renders all tabs and uses visibility flags to show only the active one.

---

## Navigation

```mermaid
flowchart LR
    DRAWER[DrawerPage] -->|pushes| PAGES[Feature Pages]
    DRAWER -->|toggles browser| BROWSER[WebViewStackView]
    BROWSER -->|tab bar| TABS[Tab switching]
    BROWSER -->|URL bar| NAV[In-browser navigation]
    BROWSER -->|FAB menu| ACTIONS[Quick actions, shortcuts]
    PAGES -->|opens URL| BROWSER
```

| Mechanism | Where | Notes |
|-----------|-------|-------|
| Drawer menu | `drawer.dart` | `Navigator.push` to feature pages |
| Browser toggle | `WebViewProvider.browserShowInForeground` | Swaps IndexedStack index |
| Tab management | `WebViewProvider.tabList` | Add / remove / activate / sleep tabs |
| Split screen | `WebViewProvider.webViewSplitActive` | Side-by-side drawer + browser on wide displays |

---

## State Management

Two patterns coexist, roughly split by purpose:

```mermaid
flowchart TD
    subgraph Provider["Provider (ChangeNotifier) — UI-facing state"]
        P1[ThemeProvider]
        P2[SettingsProvider]
        P3[WebViewProvider]
        P4[UserScriptsProvider]
        P5[TargetsProvider]
        P6[FriendsProvider]
        P7[AttacksProvider]
        P8[AwardsProvider]
        P9[ShortcutsProvider]
        P10[TerminalProvider]
        P11[+ 6 more]
    end

    subgraph GetX["GetX (GetxController) — Business logic & singletons"]
        G1[UserController]
        G2[ApiCallerController]
        G3[ChainStatusController]
        G4[StakeoutsController]
        G5[SendbirdController]
        G6[SpiesController]
        G7[WarController]
        G8[AudioController]
        G9[+ 7 more]
    end

    Provider -.->|widgets use Consumer / context.read| UI[Widgets]
    GetX -.->|accessed via Get.find| UI
```

**Provider** powers anything that drives widget rebuilds (theme, settings, webview tab state, userscripts).
**GetX** manages long-lived services that don't need per-widget rebuild semantics (API rate limiter, chain watcher, chat, audio).

---

## WebView System

The browser is the heart of the app. Every tab is its own `WebViewFull` widget backed by `flutter_inappwebview`.

```mermaid
flowchart TD
    WVP[WebViewProvider] -->|manages| TL[tabList — List of TabDetails]
    TL --> T1["TabDetails #1"]
    TL --> T2["TabDetails #2"]
    TL --> TN["TabDetails #N"]

    T1 --> WVF1[WebViewFull widget]
    WVF1 --> IAW[InAppWebView]

    IAW -->|addJavaScriptHandler| JSH[JS Handlers — Dart side]
    IAW -->|addUserScripts| USI[Userscript Injection]
    IAW -->|onLoadStart / onLoadStop| LC[Lifecycle callbacks]

    JSH --> H1[PDA_httpGet / Post / Put / Delete]
    JSH --> H2[PDA_evaluateJavascript]
    JSH --> H3[isTornPDA / reloadPage / copyToClipboard]
    JSH --> H4[Toast / Notification / Share / Download]
```

### TabDetails

Each tab carries:

| Field | Purpose |
|-------|---------|
| `id` | Unique identifier |
| `webView` / `sleepingWebView` | Widget or sleeping placeholder |
| `currentUrl` / `pageTitle` | Current state |
| `historyBack` / `historyForward` | Navigation stacks |
| `isLocked` / `isLockFull` | Tab locking (prevent accidental navigation) |
| `isChainingBrowser` | Special chaining mode |
| `chatRemovalActiveTab` | Chat widget removal toggle |

---

## Userscript Pipeline

```mermaid
sequenceDiagram
    participant USP as UserScriptsProvider
    participant WVF as WebViewFull
    participant IAW as InAppWebView
    participant JS as JavaScript context

    Note over USP: Loads scripts from storage
    USP->>WVF: getHandlerSources() — platform ready, API, GM, eval handlers
    USP->>WVF: getCondSources() — user scripts matching current URL
    WVF->>IAW: addUserScripts(handlers + user scripts)

    Note over IAW: Page starts loading
    IAW->>JS: Inject AT_DOCUMENT_START scripts
    JS->>JS: __PDA_platformReadyPromise resolves
    JS->>JS: PDA_httpGet/Post/Put/Delete become available
    JS->>JS: GM.* / GM_* functions available via GMforPDA

    Note over IAW: Page finishes loading
    IAW->>JS: Inject AT_DOCUMENT_END scripts

    JS->>IAW: callHandler("PDA_httpGet", url, headers)
    IAW->>WVF: Dart handler fires
    WVF->>JS: Returns response object
```

### @match Pattern Matching

When a page loads, `UserScriptsProvider` calls `shouldInject(url)` on each script. The matching follows the [Tampermonkey @match standard](https://www.tampermonkey.net/documentation.php?locale=en#meta:match):

- `*` alone matches everything
- `*://` matches http and https
- `*.example.com` matches the domain with or without a subdomain
- `*` in the path matches any characters
- Legacy patterns without a protocol are auto-prefixed with `*://`

---

## API Layer

```mermaid
flowchart TD
    subgraph Callers["Code that needs data"]
        C1[Pages / Widgets]
        C2[Providers]
        C3[GetX Controllers]
    end

    Callers -->|enqueueApiCall| ACC[ApiCallerController]

    ACC -->|V1 endpoints| V1[api_v1_calls.dart]
    ACC -->|V2 endpoints| V2[api_v2_calls.dart — Chopper client]

    ACC -->|rate limiter| RL["Queue — max 95 calls / 60s"]
    RL --> TORN["Torn API (api.torn.com)"]

    subgraph External["Other services"]
        FB[Firebase — 8 services]
        SB[Sendbird Chat]
        YATA[YATA — spy data]
        TS[TornStats — spy data]
        FFS[FFScouter — target finder]
    end

    Callers --> External
```

| Service | Purpose | Package |
|---------|---------|---------|
| **Torn API V1** | Legacy game data endpoints | `http` |
| **Torn API V2** | Modern Swagger-based API | `chopper` + generated models |
| **Firebase Auth** | Anonymous auth | `firebase_auth` |
| **Firestore** | Settings backup, messaging tokens | `cloud_firestore` |
| **FCM** | Push notifications | `firebase_messaging` |
| **Crashlytics** | Error tracking | `firebase_crashlytics` |
| **Sendbird** | In-game chat | `sendbird_chat_sdk` |
| **YATA / TornStats** | Spy data, stats | `http` / `dio` |

---

## Data Persistence

```mermaid
flowchart LR
    subgraph Runtime["Runtime state"]
        PROV[Providers]
        GETX[GetX Controllers]
    end

    subgraph Storage["Persistent storage"]
        SP["SharedPreferences — 4.5k lines of keys"]
        SEM["Sembast DB — large blobs, lists"]
        FS["Firestore — cloud backup"]
        SS["flutter_secure_storage — sensitive data"]
    end

    Runtime <--> SP
    Runtime <--> SEM
    Runtime <--> FS
    Runtime <--> SS
```

| Store | What lives there | Access |
|-------|-----------------|--------|
| **SharedPreferences** | Settings, alert configs, targets, sort prefs, theme, tab state — almost everything | `Prefs()` singleton (`shared_prefs.dart`, ~4.5k lines) |
| **Sembast** | Large data that doesn't fit well in SharedPreferences | `SembastDb` class (`sembast_db.dart`) |
| **Firestore** | Cloud backup of user settings, alert configs, messaging tokens | `FirebaseFirestoreUtils` |
| **Secure Storage** | API keys, sensitive credentials | `flutter_secure_storage` / `encrypt_shared_preferences` |

---

## Notification System

```mermaid
flowchart TD
    subgraph Sources["Notification sources"]
        ALERT[Profile alerts — energy, nerve, travel, etc.]
        CHAIN[Chain watcher]
        LOOT[Loot timer]
        SB[Sendbird chat messages]
        WV[Userscript-triggered notifications]
        FCM_SRC[FCM push — server-side]
    end

    Sources --> NM[notification.dart — channel router]
    NM --> FLN[flutter_local_notifications]
    FLN --> AND[Android notification channels]
    FLN --> IOS[iOS notification center]

    FCM_SRC --> FCM[Firebase Messaging]
    FCM --> FLN
```

Notification IDs are namespaced by feature:
- `101–110` — Profile cooldowns
- `201` — Travel arrival
- `555` — Chain watcher
- `666+timestamp` — Sendbird chat
- `88001+` — WebView / userscript notifications

Each Android notification channel has its own color, sound, and importance level.

---

## Key Dependencies

| Category | Package | Purpose |
|----------|---------|---------|
| **WebView** | `flutter_inappwebview` | In-app browser with JS bridge |
| **State** | `provider`, `get` | UI state + business logic |
| **Firebase** | 8 packages | Auth, DB, messaging, analytics, crashlytics |
| **Chat** | `sendbird_chat_sdk` | In-game chat |
| **HTTP** | `http`, `dio`, `chopper` | API calls + code generation |
| **Storage** | `shared_preferences`, `sembast`, `flutter_secure_storage` | Local persistence |
| **Notifications** | `flutter_local_notifications`, `firebase_messaging` | Push + local alerts |
| **Background** | `workmanager` | Background task scheduling |
| **UI** | `expandable`, `fl_chart`, `flutter_slidable`, `showcaseview` | Specialized widgets |
| **Platform** | `device_info_plus`, `connectivity_plus`, `wakelock_plus` | Device capabilities |
| **Live Activities** | Custom bridge | iOS 16.2+ live activities for travel, racing |

---

## Further Reading

- [JavaScript ↔ WebView Handlers](./webview/webview-handlers.md) — full handler reference
- [HTTP Handlers](./webview/http-handlers.md) — GET, POST, PUT, DELETE from JS
- [Notification Handlers](./webview/notification-handlers.md) — triggering notifications from userscripts
- [Building from Source](./README.md) — config stubs, signing, build commands
