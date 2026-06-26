# GM Compatibility Features

This document describes the GM (Greasemonkey) compatibility features added to Torn PDA for third-party script developers.

## Overview

Torn PDA now supports standard userscript metadata headers and improved version matching, bringing it closer to compatibility with ViolentMonkey and TamperMonkey.

## Supported GM APIs

Torn PDA ships a built-in GM compatibility handler that exposes the most common Greasemonkey APIs in both dot notation (`GM.getValue`) and underscore notation (`GM_getValue`). Scripts can also load the advanced, self-updating [GMforPDA](https://github.com/Manuito83/torn-pda/blob/master/userscripts/GMforPDA.user.js) script, which overrides the built-in handler with the latest version.

| API | `GM.*` | `GM_*` | Notes |
| --- | :---: | :---: | --- |
| `info` | ✅ | ✅ | Reports `scriptHandler` and handler version |
| `getValue(key, default)` | ✅ | ✅ | Returns the default on missing or corrupt values |
| `getValues(keys)` | ✅ | ✅ | Accepts an array of keys or a `{key: default}` map |
| `setValue(key, value)` | ✅ | ✅ | |
| `setValues(values)` | ✅ | ✅ | Accepts a `{key: value}` map |
| `deleteValue(key)` | ✅ | ✅ | |
| `deleteValues(keys)` | ❌ | ✅ | Only the `GM_deleteValues` form is exposed |
| `listValues()` | ✅ | ✅ | |
| `addStyle(css)` | ✅ | ✅ | Works even when called before `<head>` exists (e.g. at document-start) |
| `notification(...)` | ✅ | ✅ | Rendered through a native confirm dialog |
| `setClipboard(text)` | ✅ | ✅ | |
| `xmlHttpRequest(details)` | ✅ | ✅ | Dot form is `GM.xmlHttpRequest`, underscore form is `GM_xmlhttpRequest`; routed through PDA's [HTTP handlers](../webview/http-handlers.md) |

`unsafeWindow` is also exposed and points at the page `window`.

The bulk value helpers (`getValues`, `setValues`, `deleteValues`) were added in GMforPDA 2.3.0.

> Note: if `GM` is already present in the window, the handler skips re-declaring it (with a console warning) instead of overwriting it. This prevents errors when a page spawns extra tabs (e.g. via `window.open`).

## Supported Headers

### @grant

The `@grant` header specifies which GM_* and GM.* APIs the script needs access to.

**Example:**
```javascript
// ==UserScript==
// @grant GM_xmlhttpRequest
// @grant GM_setValue
// @grant GM_getValue
// ==/UserScript==
```

**Currently supported:**
- Header parsing and storage
- Grant list is available in the UserScriptModel
- Torn PDA includes a baseline GM compatibility handler for common `GM_*` and `GM.*` APIs

**TODO:**
- Extend the [Supported GM APIs](#supported-gm-apis) matrix with ViolentMonkey/TamperMonkey parity gaps
- Add any missing PDA-specific permission handling if Torn PDA starts enforcing grants

### @require

The `@require` header specifies external JavaScript libraries that should be loaded before the script runs.

**Example:**
```javascript
// ==UserScript==
// @require https://example.com/library.js
// @require https://cdn.example.com/jquery.min.js
// ==/UserScript==
```

**Currently supported:**
- Header parsing and storage
- Require list is available in the UserScriptModel

**TODO:**
- Implement automatic loading of required scripts
- Handle script loading order
- Cache required scripts

### @match

The `@match` header specifies which URLs the script should run on. Pattern matching has been improved to better support wildcards.

**Example:**
```javascript
// ==UserScript==
// @match https://*.torn.com/*
// @match https://torn.com/*
// ==/UserScript==
```

**Current implementation:**
- `*` as a universal match for backwards compatibility
- Scheme wildcards such as `*://www.torn.com/*`
- Domain wildcards such as `*://*.torn.com/*`
- Path wildcards such as `*://www.torn.com/profiles.php*`
- Legacy patterns without a protocol, such as `www.torn.com/*`
- Fallback handling for non-standard legacy patterns

**TODO:**
- Add support for @exclude patterns
- Add support for @include patterns
- Keep expanding edge-case coverage against the userscript manager specifications

## Version Matching

Version comparison has been improved to follow ViolentMonkey's semantic versioning rules, including support for pre-release versions.

**Examples:**
- `1.0.0` vs `1.0.1` → `1.0.1` is newer
- `1.0.0-alpha` vs `1.0.0` → `1.0.0` is newer (pre-release is older)
- `2.0.0` vs `1.9.9` → `2.0.0` is newer

**Implementation:**
- Uses `VersionModel` class for proper semantic versioning
- Supports pre-release versions (e.g., `1.0.0-alpha`, `1.0.0-beta.1`)
- Falls back to simple string comparison for non-standard versions

## API Changes

### UserScriptModel

**New fields:**
```dart
List<String> grants;      // List of @grant headers
List<String> requires;    // List of @require headers
```

**Updated methods:**
- `parseHeader()` - Now parses @grant and @require headers
- `fromJson()` - Deserializes grants and requires
- `toJson()` - Serializes grants and requires
- `shouldInject()` - Improved pattern matching with URL normalization
- `isNewerVersion()` - Uses VersionModel for better version comparison
- `adaptSource()` in `UserScriptsProvider` replaces `###PDA-APIKEY###` at injection time

### ScriptHeaderModel

**New class:**
```dart
class ScriptHeaderModel {
  Map<String, List<String>> header;
  VersionModel version;
  
  List<String> getHeader(String key);
  int compareVersion(ScriptHeaderModel otherModel);
  bool shouldInject(Uri uri);
  
  factory ScriptHeaderModel.fromHeader(Map<String, List<String>> header);
  factory ScriptHeaderModel.fromHeaderText(String text);
  factory ScriptHeaderModel.fromScriptText(String text);
}
```

**New class:**
```dart
class VersionModel {
  final int major;
  final int minor;
  final int patch;
  final String? pre;
  
  int compareTo(VersionModel other);
  
  factory VersionModel.parse(String text);
}
```

## Migration Guide

### For Script Developers

If you're developing userscripts for Torn PDA:

1. **Add @grant headers** for any GM_* APIs you use:
   ```javascript
   // @grant GM_xmlhttpRequest
   ```

2. **Use @require** for external libraries:
   ```javascript
   // @require https://cdn.jsdelivr.net/npm/jquery@3.6.0/dist/jquery.min.js
   ```

3. **Use proper @match patterns**:
   ```javascript
   // @match https://*.torn.com/*
   ```

4. **Use semantic versioning**:
   ```javascript
   // @version 1.2.0
   ```

### For App Developers

If you're working on the Torn PDA codebase:

1. **Use the new fields** when working with UserScriptModel:
   ```dart
   final grants = script.grants;
   final requires = script.requires;
   ```

2. **Use VersionModel** for version comparisons:
   ```dart
   final v1 = VersionModel.parse('1.0.0');
   final v2 = VersionModel.parse('1.0.1');
   if (v1.compareTo(v2) < 0) {
     // v1 is older
   }
   ```

## Testing

Tests have been added in `test/models/script_header_model_test.dart` covering:
- ScriptHeaderModel parsing
- VersionModel comparison
- UserScriptModel integration
- URL pattern matching

Run tests with:
```bash
flutter test test/models/script_header_model_test.dart
```

## Future Work

### High Priority
- Implement automatic loading of @require scripts
- Expand the GM API compatibility matrix with ViolentMonkey/TamperMonkey parity gaps and missing behavior
- Add PDA-specific permission handling if grant enforcement is introduced

### Medium Priority
- @exclude and @include pattern support
- Script installation improvements
- Update check improvements

### Low Priority
- Runtime devtools integration
- Console improvements
- Hot reload for development

## References

- [ViolentMonkey Source Code](https://github.com/violentmonkey/violentmonkey)
- [TamperMonkey Documentation](https://www.tampermonkey.net/documentation.php)
- [Greasemonkey Wiki](https://wiki.greasespot.net/)
