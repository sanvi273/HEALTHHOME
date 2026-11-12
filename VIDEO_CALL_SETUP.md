# HealthHome call notification setup

## Current call flow

The Flutter project is `frontend/`; the Node service is `backend/`. The doctor starts a call through `POST /api/video-calls/start`. The backend checks the JWT role and appointment doctor, creates a 45 second `VideoCallSession`, and sends a minimal FCM data payload to registered patient devices. The patient accepts or declines through authenticated endpoints. Agora credentials are minted only by the backend for call participants and are short lived. Declining a call leaves the appointment unchanged.

## Backend deployment

The Render service must deploy the `backend` directory and have these variables:

- `MONGO_URL` and `JWT_SECRET` (existing settings)
- `AGORA_APP_ID` and `AGORA_APP_CERTIFICATE` (existing settings)
- `FIREBASE_SERVICE_ACCOUNT_JSON` (new): the complete Firebase service-account JSON for the same Firebase project as the Android app. Add it as a Render secret. Do not place the private key in Flutter or commit it.

The backend also supports Google Application Default Credentials if the Render runtime is provisioned with them, but `FIREBASE_SERVICE_ACCOUNT_JSON` is the direct Render configuration used here. Deploy after setting the variable. If no patient device is registered or FCM is not configured, the doctor sees a delivery warning in the app.

## Android setup

The existing `frontend/android/app/src/main/AndroidManifest.xml` grants notification, vibration and full-screen notification permissions. The app requests notification and full-screen-intent permissions and creates the `incoming_calls` high-importance channel. Install/update the app, grant notifications, and allow full-screen notifications in Android settings when requested. Android 14 and later may restrict full-screen intent use. Battery optimization and force-stop policies can still delay or prevent delivery.

## iOS and web limitations

The repository does not currently contain a PushKit/CallKit integration, VoIP token registration, APNs VoIP provider, or iOS VoIP entitlement configuration. iOS delivery here uses ordinary FCM/APNs alert notifications and Flutter's local-notification handling; it does **not** provide a native CallKit incoming-call screen or guaranteed ringing while the app is terminated. Add a native PushKit/CallKit implementation and configure the Apple Developer VoIP push entitlement, APNs credentials, bundle ID capabilities, and production device tests before claiming that behavior. Flutter Web device-token registration is currently skipped.

Android full-screen notification support is not the same as a native Telecom `ConnectionService` call. This implementation does not guarantee call display after Android force-stop, denied permissions, or OEM background restrictions. No physical Android or iOS device test has been run in this workspace.

## API additions

- `POST /api/video-calls/devices` and `DELETE /api/video-calls/devices` — register/remove an authenticated device token.
- `POST /api/video-calls/start` — doctor starts a call for an eligible appointment.
- `POST /api/video-calls/:callId/accept` and `/decline` — patient decision.
- `POST /api/video-calls/:callId/join` — authenticated participant receives a short-lived Agora token.
- `POST /api/video-calls/:callId/end` and `/cancel` — end/cancel the call session.
- `GET /api/video-calls/:callId` and `/active` — participant call state.

`VideoCallSession` records call lifecycle/history and releases its unique active-appointment key when ended. Expired sessions are marked missed/ended; they are retained as history rather than TTL-deleted.

## Run from PowerShell

```powershell
cd C:\Users\hp\HEALTH_HOME\frontend
flutter pub get
flutter run
```

Run backend checks from `backend` with `node --test`.
