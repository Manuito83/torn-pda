# 📲 Torn PDA - PDA Intent Handler

## Overview

This handler allows web content to launch external applications (like Discord) by passing a URL from JavaScript to the native side of the app.

The handler takes a URL string, attempts to launch it using the device's operating system, and returns whether the launch was successful.

## Handler: launchIntent

### Arguments

1.  `url` (String): The full URL to launch. This can be a standard web URL (`https://...`) or a custom URL scheme recognized by another app (`discord://...`).

### Returns

A `Promise` that resolves to an object indicating the outcome:

- On success: `{ success: true }`
- On failure: `{ success: false, error: 'Error message' }`

### Usage Example:

This example shows how to open a specific Discord channel by calling the `launchIntent` handler.

```javascript
// The standard web URL for Torn PDA channel
const discordChannelUrl =
  "https://discord.com/channels/715785867519721534/715955949772472421";

window.flutter_inappwebview
  .callHandler("launchIntent", discordChannelUrl)
  .then((response) => {
    if (response.success) {
      console.log("Successfully requested to launch Discord.");
    } else {
      console.error("Failed to launch Discord:", response.error);
    }
  })
  .catch((error) => {
    console.error(
      "An error occurred when calling the launchIntent handler:",
      error
    );
  });
```

## Notes:

- Torn PDA will also show a native error toast automatically
