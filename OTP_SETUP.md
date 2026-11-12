# MSG91 Authentication OTP Setup

## Credentials

Keep the existing Render variables `MSG91_AUTH_KEY` and `MSG91_WIDGET_ID` unchanged. Add `MSG91_WIDGET_TOKEN` in Render using the Widget-specific `tokenAuth` from MSG91. The account Auth Key stays on the backend and is used only to validate MSG91 access tokens.

The official Flutter and Web Widget integrations require `tokenAuth` in the client. Inject it at build time; do not commit it to Dart source, a frontend `.env`, or a repository secret file. Client-side Widget tokens are necessarily present in the compiled app/browser bundle. If the Widget token is treated as a confidential server-only secret, use a backend-only OTP integration instead of the MSG91 client SDK.

Flutter builds require the Widget ID and Widget token:

```powershell
cd frontend
flutter pub get
flutter run --dart-define=MSG91_WIDGET_ID=<widget-id> --dart-define=MSG91_WIDGET_TOKEN=<widget-token>
```

For a web build, use the same build defines:

```powershell
flutter build web --dart-define=MSG91_WIDGET_ID=<widget-id> --dart-define=MSG91_WIDGET_TOKEN=<widget-token>
```

Do not pass `MSG91_AUTH_KEY` to Flutter.

## Backend

```powershell
cd backend
npm start
```

The backend requires `MSG91_AUTH_KEY`, `MSG91_WIDGET_ID`, `MSG91_WIDGET_TOKEN`, `JWT_SECRET`, and `MONGO_URL` in its runtime environment. It stores only short-lived Widget request/challenge metadata and hashed registration passwords. Temporary challenges are removed by a MongoDB TTL index.

## Verification

```powershell
cd backend
node --test test/*.test.js
```

The OTP provider should be exercised from Render after its Widget token is configured and the Render outbound IP is allowed by MSG91, if IP allowlisting is enabled.
