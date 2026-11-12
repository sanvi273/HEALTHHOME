# MSG91 Authentication OTP Setup

## Credentials

Keep the existing Render variables `MSG91_AUTH_KEY` and `MSG91_WIDGET_ID` unchanged. The account Auth Key stays on the backend and is used to send Widget OTP requests and validate MSG91 access tokens.

When a Widget-specific `tokenAuth` is available, the client can use MSG91's Flutter/Web SDK to verify OTP. If it is not supplied to the app, the app sends the six-digit code to HealthHome and the backend verifies it with MSG91's Widget API using the existing server Auth Key. The backend does not need a separate `MSG91_WIDGET_TOKEN` environment variable.

The Widget ID is optional for the backend-verified OTP path. To enable the client SDK fast path, supply both Widget values at build time:

```powershell
cd frontend
flutter pub get
flutter run --dart-define=MSG91_WIDGET_ID=<widget-id> --dart-define=MSG91_WIDGET_TOKEN=<widget-token>
```

For a web build with the client SDK fast path, use the same build defines:

```powershell
flutter build web --dart-define=MSG91_WIDGET_ID=<widget-id> --dart-define=MSG91_WIDGET_TOKEN=<widget-token>
```

Do not pass `MSG91_AUTH_KEY` to Flutter. Without the optional Widget token define, Flutter uses the backend verification path.

## Backend

```powershell
cd backend
npm start
```

The backend requires `MSG91_AUTH_KEY`, `MSG91_WIDGET_ID`, `JWT_SECRET`, and `MONGO_URL` in its runtime environment. It stores only short-lived Widget request/challenge metadata and hashed registration passwords. Temporary challenges are removed by a MongoDB TTL index.

## Verification

```powershell
cd backend
node --test test/*.test.js
```

The OTP provider should be exercised from Render after its Widget token is configured and the Render outbound IP is allowed by MSG91, if IP allowlisting is enabled.
