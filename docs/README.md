# Documentation for developers

MAIN INDEX


- ## Javascript-webview communication

  Refer to the [specific documentation](./webview/webview-handlers.md).
  
  From JS code, you can communicate with the native (Flutter) side of Torn PDA, which offers some additional capabilities (such as notifications) and also helps to overcome restrictions imposed by Torn (such as cross-origin http requests).
<br></br>
- ## GM support for PDA

  As a general rule, Torn PDA supports standard Javascript and jQuery, but it does not include any external libraries that are served in frameworks such as GM or TM. 

  However, you can refer to this [script](https://github.com/Manuito83/torn-pda/blob/master/userscripts/GMforPDA.user.js) which incorporates handlers to make life easier when converting scripts, supporting dot notation (e.g.: 'GM.addStyle') and underscore notation (e.g.: 'GM\_addStyle'). Please note that, while this script and functionality are still under development, it is an advanced version of some [pre-existing handlers ](https://github.com/Manuito83/torn-pda/blob/a3e58b591317cf41b557072745a7ee20033e4908/lib/utils/js_handlers.dart#L178)which were incorporated natively to the app long ago; adding the newest version (via script) on top of the basic handlers that come with Torn PDA should be no problem, as the former will overwrite the latter.

  Whilst these handlers supply vanilla JS counterparts to the GM_ functions, they cannot prepare your script to run on mobile devices: viewports are different, the page looks different, some selectors change, etcetera. So even if using these handlers, be prepared to adapt your script as necessary.
<br></br>
- ## Building from Source

  If you want to build the app from a fork, you need to set up some private config files that are excluded from version control.

  ### 1. Copy the config templates

  The `lib/config/` directory contains `.dart.example` templates. Copy them removing the `.example` extension:

  ```bash
  cd lib/config
  cp yata_config.dart.example yata_config.dart
  cp webview_config.dart.example webview_config.dart
  cp tac_config.dart.example tac_config.dart
  ```

  ### 2. Copy the native stubs

  Some native modules are not included in the public repo. Stub implementations are provided in `lib/config/` — copy them to the expected locations:

  ```bash
  cd lib/config
  cp native_auth_models.dart.example ../torn-pda-native/auth/native_auth_models.dart
  cp native_auth_provider.dart.example ../torn-pda-native/auth/native_auth_provider.dart
  cp native_user_provider.dart.example ../torn-pda-native/auth/native_user_provider.dart
  cp native_login_widget.dart.example ../torn-pda-native/auth/native_login_widget.dart
  mkdir -p ../torn-pda-native/stats
  cp stats_controller.dart.example ../torn-pda-native/stats/stats_controller.dart
  ```

  ### 3. Set up Android signing (for release builds)

  Create `android/key.properties` with your keystore details:

  ```properties
  storePassword=<your-store-password>
  keyPassword=<your-key-password>
  keyAlias=<your-key-alias>
  storeFile=<path-to-your-keystore-file>
  ```

  See `android/local.properties.example` for an example. Copy it to `android/local.properties` and adjust paths for your system.

  ### 4. Build

  ```bash
  flutter build apk --release
  ```

  The app will compile with the placeholder config values, but some features (e.g. YATA proxy, TAC, native auth) will not function without real credentials.


