# DEBUG commands

```
npm run watch
firebase emulators:start --only functions
firebase functions:shell
firebase deploy --only functions
```

</br></br>

# Live Activities

Note 1: remember token production true/false if testing LA in la_apns_helper
Note 2: LA can be tested directly with liveActivities.sendTestTravelPushToManuito()
Note 3: change these to false in la_apns_helper.ts

```
production: false,
ejectUnauthorized: false,
```

</br></br>

# Test functions: RUN FOR USER

### Default (Manuito)

```
curl -X POST http://127.0.0.1:5002/torn-pda-manuito/us-east4/alertsTest-runForUser \
-H "Content-Type: application/json" \
-d '{"data": {}}'
```

Shell:

```
alertsTest.runForUser({})
```

### Other user

```
# Specific user (eg. "Kwack")
curl -X POST http://127.0.0.1:5002/torn-pda-manuito/us-east4/alertsTest-runForUser \
-H "Content-Type: application/json" \
-d '{"data": {"userName": "Kwack"}}'
```

Shell:

```
alertsTest.runForUser({userName: "Kwack"})
```

</br></br>

# Test functions: TEST NOTIFICATION

### Default (Manuito)

```
curl -X POST http://127.0.0.1:5002/torn-pda-manuito/us-east4/alertsTest-sendTestNotification \
-H "Content-Type: application/json" \
-d '{"data": {}}'
```

Shell:

```
alertsTest.sendTestNotification({})
```

# Other user

```
curl -X POST http://127.0.0.1:5002/torn-pda-manuito/us-east4/alertsTest-sendTestNotification \
-H "Content-Type: application/json" \
-d '{"data": {"userName": "Kwack"}}'
```

Shell:

```
alertsTest.sendTestNotification({userName: "Kwack"})
```

</br></br>

# Test functions: MASSIVE NOTIFICATION

### Default (Manuito)

# Other user

**CHANGE 'const active'**

**CHANGE NOTIFICATION PARAMS!**

```
curl -X POST http://127.0.0.1:5002/torn-pda-manuito/us-east4/alertsTest-sendMassNotification \
-H "Content-Type: application/json" \
-d '{"data": {}}'
```

Shell:

```
alertsTest.sendMassNotification({})
```
