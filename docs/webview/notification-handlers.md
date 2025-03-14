# 📲 Torn PDA - JavaScript Notification Handlers

## Overview
This document describes how to use Torn PDA's notification handlers from JavaScript.

Note: refer to this [working example website](https://info.tornpda.com/notifications-test.html) (with Torn PDA) to test these features. Its [source code](https://github.com/Manuito83/torn-pda/blob/notification-handler/docs/webview/notification-test-web.md) is also available for easier reference. 
<br/><br/>

## Handler #1 - Schedule Notification

Schedules a notification from JavaScript.

### 🔹 Usage Example:
```javascript
window.flutter_inappwebview.callHandler('scheduleNotification', {
  title: 'Notification title',                // [required]
  subtitle: 'Optional subtitle',
  id: 123,                                    // [required] Beware of existing notification ID (can be checked with another handler)
  timestamp: Date.now() + 60000,              // [required] UNIX timestamp in ms. Example: notification in 1 minute
  overwriteID: false,                         // Overwrite existing notification ID if true (default: false)
  launchNativeToast: true,                    // Shows a toast confirmation (default: true)
  toastMessage: 'Notification scheduled!',    // (default: if empty a custom message will show with date + time)
  toastColor: 'blue',                         // (default: 'blue', but also accepts 'red' and 'green')
  toastDurationSeconds: 4                     // Duration of the toast on screen (default: 3). The user can click to close.
  urlCallback: 'https://www.torn.com/gym.php' // (default: empty)
});
```
📖 Note: 
- If `launchNativeToast` is true but `toastMessage` is left empty, a default notification message will be show, containing date and local time, such as: *`Notification scheduled for 2025-01-01 12:00:00.000`*

--

🔸 Error Cases:
- Missing parameters: title, id, or timestamp
- Invalid ID (not between 0-9999)
- Timestamp in the past
- Duplicate ID without overwrite


---
<br/><br/>

## Handler #2 - Set Alarm (Android)

Sets an alarm on Android from JavaScript.

### 🔹 Usage Example:
```javascript
window.flutter_inappwebview.callHandler('setAlarm', {
  timestamp: Date.now() + 300000, // [required] UNIX timestamp in ms. Example: 5 minutes from now
  vibrate: true,                  // Enable vibration (default: true)
  sound: true,                    // Alarm sound (default: true)
  message: 'Alarm triggered!'     // Custom alarm message (default: 'TORN PDA Alarm')
});
```

🔸 Error Cases:
- Alarms are only supported on Android.
- Missing parameters: id or timestamp.
- Native helper errors (e.g., issues during scheduling) will return an error message.


---
<br/><br/>

## Handler #3 - Set Timer (Android)

Starts a timer on Android from JavaScript.

### 🔹 Usage Example:
```javascript
window.flutter_inappwebview.callHandler('setTimer', {
  seconds: 120,                   // [required] Timer duration in seconds
  message: 'Timer finished!'      // Custom timer message (default: 'TORN PDA Timer')
});
```

🔸 Error Cases:
-	Timers are only supported on Android.
-	Missing required parameter: seconds.
-	Native helper errors (e.g., issues during timer setup) will return an error message.


---
<br/><br/>

## Handler #4 - Cancel Notification

Cancels a scheduled notification.

🔹 Usage Example:

```javascript
window.flutter_inappwebview.callHandler('cancelNotification', {
  id: 123   // [required]
});
```

🔸 Error Cases:
-	Missing parameter id
-	Invalid ID (not between 0-9999)
-	Non-existent notification ID



---
<br/><br/>

## Handler #5 - Get Notification

Checks for an existing notification and retrieves its details.

🔹 Usage Example:

```javascript
window.flutter_inappwebview.callHandler('getNotification', {
  id: 123   // [required] Must be an integer between 0 and 9999
}).then(response => {
  // Process the response here
});
```

### Response Details

- **Success Response:**
  - **status:** `"success"`
  - **message:** A message indicating that the notification was found.
  - **data:** An object containing:
    - **id:** Notification ID.
    - **timestamp:** Scheduled time for the notification (Unix timestamp in milliseconds).
    - **title:** Notification title.
    - **body:** Notification body.

- **Error Response:**
  - **status:** `"error"`
  - **message:** A description of the error, such as:
    - Missing parameter `id`
    - Invalid `id` (must be between 0 and 9999)
    - Notification does not exist

### Web Example

Below is a valid example of how to use the **getNotification** handler:

```javascript
window.flutter_inappwebview.callHandler('getNotification', params)
  .then(response => {
    if (response.status === 'error') {
      console.error(`Error getting notification: ${response.message}`);
      showToast(`No notification found with ID ${id}`, 'warning');
    } else {
      const notif = response.data;
      const notifTime = new Date(notif.timestamp).toLocaleString();
      console.log(`Notification found: ${response.message}`);
      console.log(`Scheduled for: ${notifTime}`);
      showToast(`Notification #${id} found: ${notifTime}`, 'success');
    }
  })
  .catch(e => {
    console.error(`Error checking notification: ${e}`);
    showToast(`Error: ${e}`, 'error');
  });
```

🔸 Error Cases:
-	Missing parameter id
-	Invalid ID (not between 0-9999)
-	Notification doesn’t exist

---
<br/><br/>

## Handler #6 - Get Platform

Returns the current platform the app is running on.

🔹 Usage Example:

```javascript
window.flutter_inappwebview.callHandler('getPlatform').then(response => {
  console.log(`Current platform: ${response.platform}`);
});
```

🔸 Possible Results:
-	Android
-	iOS
-	Windows
-	Unknown

---
---
<br></br>
📌 Notes
-	Ensure timestamps are always future-based Unix epoch in milliseconds.
-	Internally (in case you are reviewing the Flutter code), in order to avoid clashes with other notifications, notification IDs requested from JS are prefixed with 88. For example, ID 123 becomes 88123. You don't need to worry about this from a scripting perspective.