```html
<!DOCTYPE html>
<html lang="en">

<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Torn PDA Notification Tester</title>
    <style>
        :root {
            --primary-color: #4a6da7;
            --primary-dark: #3a5a8c;
            --primary-light: #c7d4e8;
            --success-color: #28a745;
            --danger-color: #dc3545;
            --warning-color: #ffc107;
            --android-color: #a4c639;
            --ios-color: #888;
            --section-bg: #f8f9fa;
            --border-color: #dee2e6;
        }

        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            padding: 20px;
            max-width: 700px;
            margin: auto;
            background-color: #f0f2f5;
            color: #333;
        }

        h1 {
            color: var(--primary-dark);
            text-align: center;
            margin-bottom: 20px;
        }

        h2 {
            border-bottom: 1px solid var(--border-color);
            padding-bottom: 10px;
            margin-top: 0;
            color: var(--primary-dark);
        }

        .section {
            margin-bottom: 20px;
            padding: 20px;
            border: 1px solid var(--border-color);
            border-radius: 10px;
            background-color: var(--section-bg);
            box-shadow: 0 2px 5px rgba(0, 0, 0, 0.05);
            transition: all 0.3s ease;
        }

        .section:hover {
            box-shadow: 0 5px 15px rgba(0, 0, 0, 0.1);
        }

        label {
            display: block;
            margin-top: 10px;
            margin-bottom: 5px;
            font-weight: 500;
        }

        input,
        select {
            width: 100%;
            padding: 8px 10px;
            margin-top: 3px;
            box-sizing: border-box;
            border: 1px solid var(--border-color);
            border-radius: 4px;
            transition: border-color 0.3s;
        }

        input:focus,
        select:focus {
            outline: none;
            border-color: var(--primary-color);
            box-shadow: 0 0 0 2px rgba(74, 109, 167, 0.2);
        }

        button {
            margin-top: 15px;
            padding: 10px 15px;
            cursor: pointer;
            background-color: var(--primary-color);
            color: white;
            border: none;
            border-radius: 4px;
            font-weight: bold;
            transition: background-color 0.3s, transform 0.2s;
        }

        button:hover {
            background-color: var(--primary-dark);
            transform: translateY(-1px);
        }

        button:active {
            transform: translateY(1px);
        }

        .reset-btn {
            background-color: var(--danger-color);
            color: white;
            border: none;
            width: 100%;
            margin-top: 20px;
            padding: 12px;
        }

        .reset-btn:hover {
            background-color: #bd2130;
        }

        .platform-badge {
            font-size: 12px;
            font-weight: bold;
            padding: 3px 8px;
            border-radius: 12px;
            margin-left: 8px;
            color: white;
            background-color: var(--ios-color);
        }

        .android-only {
            border-left: 4px solid var(--android-color);
            position: relative;
        }

        .android-badge {
            position: absolute;
            top: 10px;
            right: 10px;
            background-color: var(--android-color);
            color: white;
            font-size: 12px;
            padding: 3px 8px;
            border-radius: 12px;
            font-weight: bold;
        }

        .info-text {
            font-size: 13px;
            color: #666;
            margin-top: 5px;
            font-style: italic;
        }

        .toast-container {
            position: fixed;
            top: 20px;
            right: 20px;
            z-index: 1000;
        }

        .toast {
            padding: 15px 20px;
            margin-bottom: 10px;
            min-width: 250px;
            color: white;
            border-radius: 4px;
            box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
            display: flex;
            align-items: center;
            animation: slideIn 0.3s, fadeOut 0.5s 2.5s forwards;
            opacity: 0.9;
        }

        .toast-success {
            background-color: var(--success-color);
        }

        .toast-error {
            background-color: var(--danger-color);
        }

        .toast-warning {
            background-color: var(--warning-color);
            color: #212529;
        }

        .toast-icon {
            margin-right: 10px;
            font-size: 20px;
        }

        @keyframes slideIn {
            from {
                transform: translateX(100%);
            }

            to {
                transform: translateX(0);
            }
        }

        @keyframes fadeOut {
            from {
                opacity: 0.9;
            }

            to {
                opacity: 0;
                transform: translateY(-20px);
            }
        }

        .collapsible {
            cursor: pointer;
        }

        .collapsible::after {
            content: ' ▼';
            font-size: 12px;
            color: var(--primary-color);
        }

        .collapsed::after {
            content: ' >';
        }

        .content {
            display: block;
            transition: max-height 0.3s ease-out;
            overflow: hidden;
        }

        .collapsed+.content {
            max-height: 0;
        }

        .row {
            display: flex;
            gap: 10px;
            justify-content: space-between;
        }

        .column {
            flex: 1;
            min-width: 0;
        }

        @media (max-width: 600px) {
            .row {
                flex-direction: column;
            }
        }

        .status-indicator {
            display: inline-block;
            width: 10px;
            height: 10px;
            border-radius: 50%;
            margin-right: 5px;
        }

        .status-active {
            background-color: var(--success-color);
        }

        .status-none {
            background-color: var(--danger-color);
        }

        #platformStatus {
            margin-top: 15px;
            padding: 10px;
            border-radius: 4px;
            background-color: var(--primary-light);
            display: none;
        }

        .log-container {
            margin-top: 10px;
            max-height: 150px;
            overflow-y: auto;
            border: 1px solid var(--border-color);
            border-radius: 4px;
            padding: 10px;
            background-color: #f1f1f1;
            font-family: monospace;
            font-size: 12px;
        }

        #logOutput {
            margin: 0;
        }

        .log-clear-btn {
            background-color: #777;
            margin-top: 5px;
            padding: 5px 10px;
            font-size: 12px;
        }

        .number-input {
            position: relative;
            display: flex;
            align-items: center;
        }

        .number-input input {
            text-align: center;
        }

        .number-btn {
            background: var(--primary-color);
            border: none;
            color: white;
            width: 30px;
            height: 30px;
            font-size: 16px;
            display: flex;
            align-items: center;
            justify-content: center;
            cursor: pointer;
            padding: 0;
            margin: 0;
            border-radius: 4px;
        }

        .required-indicator {
            display: inline-block;
            width: 24px;
            height: 24px;
            line-height: 24px;
            border-radius: 50%;
            background-color: var(--danger-color);
            color: white;
            font-weight: bold;
            text-align: center;
            font-size: 10px;
            margin-right: 5px;
        }
    </style>
</head>

<body>
    <h1>Torn PDA Notification Tester</h1>
    <div id="toastContainer" class="toast-container"></div>

    <div class="section"
        style="text-align: center; background-color: var(--primary-light); border: 1px solid var(--primary-dark);">
        <p>
            Documentation available in
            <a href="https://github.com/Manuito83/torn-pda/blob/notification-handler/docs/webview/notification-handlers.md"
                target="_blank">
                GitHub
            </a>
        </p>
    </div>

    <div class="section">
        <h2>Console</h2>
        <div class="log-container">
            <pre id="logOutput">Console output will appear here...</pre>
        </div>
        <button class="log-clear-btn" onclick="clearLog()">Clear Log</button>
    </div>

    <div class="section">
        <h2 class="collapsible">Platform Status</h2>
        <div class="content">
            <button onclick="checkPlatform()">Check Platform Status</button>
            <div id="platformStatus"></div>
        </div>
    </div>

    <div class="section">
        <h2 class="collapsible">1. Schedule Notification</h2>
        <div class="content">
            <div class="row">
                <div class="column">
                    <label>
                        <span class="required-indicator">REQ</span>
                        Title:</label>
                    <input type="text" id="notifTitle" value="Torn PDA Alert">
                </div>
                <div class="column">
                    <label>Subtitle:</label>
                    <input type="text" id="notifSubtitle" value="Test notification">
                </div>
            </div>

            <div class="row">
                <div class="column">
                    <label>
                        <span class="required-indicator">REQ</span>
                        ID (1-9999):</label>
                    <div class="number-input">
                        <button class="number-btn" onclick="adjustNumberInput('notifId', -1)">-</button>
                        <input type="number" id="notifId" value="123" min="1" max="9999">
                        <button class="number-btn" onclick="adjustNumberInput('notifId', 1)">+</button>
                    </div>
                </div>
                <div class="column">
                    <label>
                        <span class="required-indicator">REQ</span>
                        Seconds from now:</label>
                    <div class="number-input">
                        <button class="number-btn" onclick="adjustNumberInput('notifDelay', -10)">-</button>
                        <input type="number" id="notifDelay" value="60" min="1">
                        <button class="number-btn" onclick="adjustNumberInput('notifDelay', 10)">+</button>
                    </div>
                </div>
            </div>

            <label>Overwrite existing ID:
                <select id="notifOverwrite">
                    <option value="true">True</option>
                    <option value="false">False</option>
                </select>
            </label>

            <label>Launch Native Toast:<select id="notifToastLaunch">
                    <option value="true">True</option>
                    <option value="false">False</option>
                </select>
            </label>

            <label>Toast Message:</label>
            <small>
                Note: if <code>launchNativeToast</code> is true but <code>toastMessage</code> is left empty, a default
                notification message will be shown, containing date and local time, such as:
                <em><code>Notification scheduled for 2025-01-01 12:00:00.000</code></em>
            </small>
            <input type="text" id="notifToastMessage" value="Notification Scheduled">

            <label>Toast Color: red, green, blue [default]:</label>
            <input type="text" id="notifToastColor" value="blue">

            <label>Toast Duration (seconds):</label>
            <input type="number" id="notifToastDuration" value="3" min="1">

            <label>URL callback (notification tapped):</label>
            <input type="text" id="notifUrlCallback" value="https://www.torn.com/gym.php">

            <button onclick="scheduleNotification()">Schedule Notification</button>
        </div>
    </div>

    <div class="section">
        <h2 class="collapsible">2. Cancel Notification</h2>
        <div class="content">
            <label>
                <span class="required-indicator">REQ</span>
                ID to Cancel:</label>
            <div class="number-input">
                <button class="number-btn" onclick="adjustNumberInput('cancelId', -1)">-</button>
                <input type="number" id="cancelId" value="123" min="1" max="9999">
                <button class="number-btn" onclick="adjustNumberInput('cancelId', 1)">+</button>
            </div>
            <button onclick="cancelNotification()">Cancel Notification</button>
        </div>
    </div>

    <div class="section">
        <h2 class="collapsible">3. Get Notification Info</h2>
        <div class="content">
            <label>
                <span class="required-indicator">REQ</span>
                ID to Check:</label>
            <div class="number-input">
                <button class="number-btn" onclick="adjustNumberInput('checkId', -1)">-</button>
                <input type="number" id="checkId" value="123" min="1" max="9999">
                <button class="number-btn" onclick="adjustNumberInput('checkId', 1)">+</button>
            </div>
            <button onclick="getNotification()">Check Notification</button>
        </div>
    </div>

    <div class="section android-only">
        <span class="android-badge">Android Only</span>
        <h2 class="collapsible">4. Set Alarm</h2>
        <div class="content">
            <div class="info-text">This feature is only available on Android devices</div>

            <div class="row">
                <div class="column">
                    <label>Message:</label>
                    <input type="text" id="alarmMessage" value="TORN PDA Alarm">
                </div>
            </div>

            <div class="column">
                <label>
                    <span class="required-indicator">REQ</span>
                    Time:</label>
                <input type="time" id="alarmTime">
            </div>

            <div class="row">
                <div class="column">
                    <label>Vibrate:</label>
                    <select id="alarmVibrate">
                        <option value="true">Yes</option>
                        <option value="false">No</option>
                    </select>
                </div>
                <div class="column">
                    <label>Alarm Sound:</label>
                    <select id="alarmSound">
                        <option value="true">Yes</option>
                        <option value="false">No</option>
                    </select>
                </div>
            </div>

            <button onclick="setAlarm()">Set Alarm</button>
        </div>
    </div>

    <div class="section android-only">
        <span class="android-badge">Android Only</span>
        <h2 class="collapsible">5. Set Timer</h2>
        <div class="content">
            <div class="info-text">This feature is only available on Android devices</div>

            <div class="row">
                <div class="column">
                    <label>
                        <span class="required-indicator">REQ</span>
                        Seconds:</label>
                    <div class="number-input">
                        <button class="number-btn" onclick="adjustNumberInput('timerSeconds', -30)">-</button>
                        <input type="number" id="timerSeconds" value="120" min="1">
                        <button class="number-btn" onclick="adjustNumberInput('timerSeconds', 30)">+</button>
                    </div>
                </div>
                <div class="column">
                    <label>Message:</label>
                    <input type="text" id="timerMessage" value="TORN PDA Timer">
                </div>
            </div>

            <button onclick="setTimer()">Set Timer</button>
        </div>
    </div>

    <button class="reset-btn" onclick="resetFields()">Reset to Defaults</button>

    <script>
        document.addEventListener("DOMContentLoaded", function () {
            setDefaultDateTime();
            setupCollapsibles();
            checkPlatformSilently();
        });

        function setupCollapsibles() {
            const collapsibles = document.getElementsByClassName("collapsible");
            for (let i = 0; i < collapsibles.length; i++) {
                const header = collapsibles[i];
                const content = header.nextElementSibling;

                header.addEventListener("click", function () {
                    const currentMaxHeight = window.getComputedStyle(content).maxHeight;

                    if (currentMaxHeight !== "0px") {
                        header.classList.add("collapsed");
                        content.style.maxHeight = "0px";
                    } else {
                        header.classList.remove("collapsed");
                        content.style.maxHeight = content.scrollHeight + "px";
                    }
                });
            }
        }

        function adjustNumberInput(id, amount) {
            const input = document.getElementById(id);
            let value = parseInt(input.value) || 0;
            value += amount;

            if (input.hasAttribute('min')) {
                const min = parseInt(input.getAttribute('min'));
                if (value < min) value = min;
            }

            if (input.hasAttribute('max')) {
                const max = parseInt(input.getAttribute('max'));
                if (value > max) value = max;
            }

            input.value = value;
        }

        function showToast(message, type = 'success') {
            const container = document.getElementById('toastContainer');
            const toast = document.createElement('div');
            toast.className = `toast toast-${type}`;

            let icon = '';
            if (type === 'success') icon = '✓';
            else if (type === 'error') icon = '✗';
            else if (type === 'warning') icon = '⚠';

            toast.innerHTML = `<span class="toast-icon">${icon}</span>${message}`;
            container.appendChild(toast);

            setTimeout(() => {
                container.removeChild(toast);
            }, 3000);
        }

        function log(message) {
            const logOutput = document.getElementById('logOutput');
            const timestamp = new Date().toLocaleTimeString();
            logOutput.textContent += `\n[${timestamp}] ${message}`;
            logOutput.scrollTop = logOutput.scrollHeight;
            console.log(message);
        }

        function clearLog() {
            document.getElementById('logOutput').textContent = 'Console output will appear here...\n';
        }

        function setDefaultDateTime() {
            const now = new Date();
            now.setMinutes(now.getMinutes() + 30);

            const hours = String(now.getHours()).padStart(2, '0');
            const minutes = String(now.getMinutes()).padStart(2, '0');

            document.getElementById('alarmTime').value = `${hours}:${minutes}`;
        }

        function checkPlatformSilently() {
            window.flutter_inappwebview.callHandler('getPlatform')
                .then(response => {
                    log(`Platform detected: ${response.platform}`);
                    if (response.platform && response.platform.toLowerCase() !== 'android') {
                        hideAndroidSections();
                    }
                })
                .catch(e => {
                    log(`Error detecting platform: ${e}`);
                });
        }

        function hideAndroidSections() {
            const androidSections = document.getElementsByClassName('android-only');
            for (let i = 0; i < androidSections.length; i++) {
                androidSections[i].style.display = 'none';
            }
        }

        function checkPlatform() {
            window.flutter_inappwebview.callHandler('getPlatform')
                .then(response => {
                    log(`Platform detected: ${response.platform}`);
                    const platformStatus = document.getElementById('platformStatus');
                    platformStatus.style.display = 'block';

                    const isAndroid = response.platform && response.platform.toLowerCase() === 'android';

                    platformStatus.innerHTML = `
            <div>
              <strong>Current Platform:</strong> ${response.platform}
            </div>
            <div style="margin-top: 10px;">
              <strong>Alarms/Timers (Android):</strong> 
              <span class="status-indicator ${isAndroid ? 'status-active' : 'status-none'}"></span>
              ${isAndroid ? 'Available' : 'Not Available'}
            </div>
          `;
                    showToast(`Platform: ${response.platform}`, 'success');
                })
                .catch(e => {
                    log(`Error detecting platform: ${e}`);
                    showToast(`Error: ${e}`, 'error');
                });
        }

        function scheduleNotification() {
            const params = {
                title: document.getElementById('notifTitle').value,
                subtitle: document.getElementById('notifSubtitle').value,
                id: parseInt(document.getElementById('notifId').value),
                timestamp: Date.now() + parseInt(document.getElementById('notifDelay').value) * 1000,
                overwriteID: document.getElementById('notifOverwrite').value === 'true',
                launchNativeToast: document.getElementById('notifToastLaunch').value === 'true',
                toastMessage: document.getElementById('notifToastMessage').value,
                toastColor: document.getElementById('notifToastColor').value,
                toastDurationSeconds: parseInt(document.getElementById('notifToastDuration').value),
                urlCallback: document.getElementById('notifUrlCallback').value,
            };

            log(`Scheduling notification ID ${params.id} for ${new Date(params.timestamp).toLocaleString()}`);
            window.flutter_inappwebview.callHandler('scheduleNotification', params)
                .then(response => {
                    if (response.status && response.status === 'error') {
                        log(`Error scheduling notification: ${response.message}`);
                        showToast(`Error: ${response.message}`, 'error');
                    } else {
                        log(`Notification scheduled: ${JSON.stringify(response)}`);
                        showToast('Notification scheduled successfully', 'success');
                    }
                })
                .catch(e => {
                    log(`Error calling scheduleNotification: ${e}`);
                    showToast(`Error: ${e}`, 'error');
                });
        }

        function cancelNotification() {
            const id = parseInt(document.getElementById('cancelId').value);
            const params = { id: id };

            log(`Cancelling notification ID ${id}`);
            window.flutter_inappwebview.callHandler('cancelNotification', params)
                .then(response => {
                    if (response.status === 'error') {
                        log(`Error cancelling notification: ${response.message}`);
                        showToast(`Error: ${response.message}`, 'error');
                    } else {
                        log(`Notification cancelled: ${response.message}`);
                        showToast('Notification cancelled', 'success');
                    }
                })
                .catch(e => {
                    log(`Error cancelling notification: ${e}`);
                    showToast(`Error: ${e}`, 'error');
                });
        }

        function getNotification() {
            const id = parseInt(document.getElementById('checkId').value);
            const params = { id: id };

            log(`Checking notification ID ${id}`);
            window.flutter_inappwebview.callHandler('getNotification', params)
                .then(response => {
                    if (response.status === 'error') {
                        log(`Error getting notification: ${response.message}`);
                        showToast(`No notification found with ID ${id}`, 'warning');
                    } else {
                        const notif = response.data;
                        const notifTime = new Date(notif.timestamp).toLocaleString();
                        log(`Notification found: ${response.message}`);
                        log(`Scheduled for: ${notifTime}`);
                        showToast(`Notification #${id} found, scheduled at ${notifTime}`, 'success');
                    }
                })
                .catch(e => {
                    log(`Error checking notification: ${e}`);
                    showToast(`Error: ${e}`, 'error');
                });
        }

        function setAlarm() {
            const alarmTime = document.getElementById('alarmTime').value;

            if (!alarmTime) {
                showToast("Please select time for the alarm", 'warning');
                return;
            }

            const now = new Date();
            const [hours, minutes] = alarmTime.split(':');

            let alarmDateTime = new Date(
                now.getFullYear(),
                now.getMonth(),
                now.getDate(),
                parseInt(hours, 10),
                parseInt(minutes, 10)
            );

            if (alarmDateTime <= now) {
                alarmDateTime.setDate(alarmDateTime.getDate() + 1);
            }

            const timestamp = alarmDateTime.getTime();

            const params = {
                timestamp: timestamp,
                message: document.getElementById('alarmMessage').value,
                vibrate: document.getElementById('alarmVibrate').value === "true",
                sound: document.getElementById('alarmSound').value === "true",
            };

            log(`Setting alarm for ${new Date(timestamp).toLocaleString()}`);
            window.flutter_inappwebview.callHandler('setAlarm', params)
                .then(response => {
                    log(`Alarm response: ${JSON.stringify(response)}`);
                    if (response.status === 'error') {
                        showToast(`Error: ${response.message}`, 'error');
                    } else {
                        showToast(`Alarm set successfully for ${new Date(timestamp).toLocaleString()}`, 'success');
                    }
                })
                .catch(e => {
                    log(`Error setting alarm: ${e}`);
                    showToast(`Error: ${e}`, 'error');
                });
        }

        function setTimer() {
            const seconds = parseInt(document.getElementById('timerSeconds').value);

            if (isNaN(seconds) || seconds <= 0) {
                showToast("Please enter a valid number of seconds", 'warning');
                return;
            }

            const params = {
                seconds: seconds,
                message: document.getElementById('timerMessage').value
            };

            const endTime = new Date(Date.now() + seconds * 1000).toLocaleTimeString();
            log(`Setting timer for ${seconds} seconds (ends at ${endTime})`);

            window.flutter_inappwebview.callHandler('setTimer', params)
                .then(response => {
                    log(`Timer response: ${JSON.stringify(response)}`);
                    if (response.status === 'error') {
                        showToast(`Error: ${response.message}`, 'error');
                    } else {
                        showToast(`Timer set for ${seconds} seconds`, 'success');
                    }
                })
                .catch(e => {
                    log(`Error setting timer: ${e}`);
                    showToast(`Error: ${e}`, 'error');
                });
        }

        function resetFields() {
            document.getElementById('notifTitle').value = "Torn PDA Alert";
            document.getElementById('notifSubtitle').value = "Test notification";
            document.getElementById('notifId').value = "123";
            document.getElementById('notifDelay').value = "60";
            document.getElementById('notifToastLaunch').value = "true";
            document.getElementById('notifToastMessage').value = "Notification Scheduled";
            document.getElementById('notifToastColor').value = "blue";
            document.getElementById('notifToastDuration').value = "3";
            document.getElementById('notifUrlCallback').value = "https://www.torn.com/gym.php";
            document.getElementById('notifOverwrite').value = "true";
            document.getElementById('cancelId').value = "123";
            document.getElementById('checkId').value = "123";

            document.getElementById('alarmMessage').value = "TORN PDA Alarm";
            document.getElementById('alarmVibrate').value = "true";
            document.getElementById('alarmRingtone').value = "";
            document.getElementById('timerSeconds').value = "120";
            document.getElementById('timerMessage').value = "TORN PDA Timer";

            setDefaultDateTime();
            showToast("All fields reset to default values", 'success');
            log("All fields reset to defaults");
        }
    </script>

</body>

</html>
```

