# 📲 Torn PDA - JavaScript Notification Handlers

## Overview
This document describes how to use Torn PDA's notification handlers from JavaScript.
<br/><br/>

## Handler #1 - Schedule Notification

Schedules a notification from JavaScript.

### 🔹 Usage Example:
```javascript
window.flutter_inappwebview.callHandler('scheduleNotification', {
  title: 'Notification title',
  subtitle: 'Optional subtitle',
  id: 123,
  timestamp: Date.now() + 60000,  // Example: notification in 1 minute
  overwriteID: true,              // Overwrite existing notification ID if true
  launchNativeToast: true,        // Shows a toast confirmation
  toastMessage: 'Notification scheduled!', 
  toastColor: 'blue',             // Defaults to 'blue', but also accepts 'red' and 'green' 
  toastDurationSeconds: 4         // Duration of the toast on screen (the user can always click to close)
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
  id: 456,                        // Unique alarm ID
  timestamp: Date.now() + 300000, // Alarm set for 5 minutes from now (in milliseconds)
  vibrate: true,                  // Optional: enable vibration (default: true)
  ringtone: 'default',            // Optional: alarm ringtone (default: empty string)
  message: 'Alarm triggered!'     // Optional: custom alarm message (default: 'TORN PDA Alarm')
});
```

🔸 Error Cases:
	•	Alarms are only supported on Android.
	•	Missing parameters: id or timestamp.
	•	Native helper errors (e.g., issues during scheduling) will return an error message.


---
<br/><br/>

## Handler #3 - Set Timer (Android)

Starts a timer on Android from JavaScript.

### 🔹 Usage Example:
```javascript
window.flutter_inappwebview.callHandler('setTimer', {
  seconds: 120,                   // Timer duration in seconds
  message: 'Timer finished!'      // Optional: custom timer message (default: 'TORN PDA Timer')
});
```

🔸 Error Cases:
	•	Timers are only supported on Android.
	•	Missing required parameter: seconds.
	•	Native helper errors (e.g., issues during timer setup) will return an error message.


---
<br/><br/>

## Handler #4 - Cancel Notification

Cancels a scheduled notification.

🔹 Usage Example:

```javascript
window.flutter_inappwebview.callHandler('cancelNotification', {
  id: 123
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
  id: 123
}).then(response => {
  if (response.status === 'success') {
    const data = response.data;
    console.log(`Notification ${data.id} scheduled for ${new Date(data.timestamp)}`);
  } else {
    console.error(response.message);
  }
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

```javascript
.then(response => {
  if (response.status === 'error') {
    console.error(`[Flutter JS Error] ${response.message}`);
  } else {
    console.log(`[Flutter JS Success] ${response.message}`);
  }
})
.catch(e => {
  console.error(`[Flutter JS Exception] ${e}`);
});
```
---
---
<br></br>
📌 Notes
-	Ensure timestamps are always future-based Unix epoch in milliseconds.
-	Internally (in case you are reviewing the Flutter code), in order to avoid clashes with other notifications, notification IDs requested from JS are prefixed with 88. For example, ID 123 becomes 88123. You don't need to worry about this from a scripting perspective.