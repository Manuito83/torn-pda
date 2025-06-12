## DEBUG commands

```
npm run watch
firebase emulators:start --only functions
firebase functions:shell
firebase deploy --only functions
```

## Test function (terminal call):

Note: `forceTest` also sends a fake notification

```
curl -X POST http://127.0.0.1:5002/torn-pda-manuito/us-east4/alertsTest-runForUser \
-H "Content-Type: application/json" \
-d '{"data": {"userName": "Manuito", "forceTest": false}}'
```

## Live Activities

Note 1: remember token production true/false if testing LA in la_apns_helper
Note 2: LA can be tested directly with liveActivities.sendTestTravelPushToManuito()
Note 3: change these to false in la_apns_helper.ts

```
production: false,
ejectUnauthorized: false,
```
