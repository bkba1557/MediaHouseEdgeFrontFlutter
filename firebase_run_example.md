# Firebase Web Run Example

Run Flutter Web with your Firebase project values:

```powershell
flutter run -d chrome `
  --dart-define=FIREBASE_API_KEY=your_api_key `
  --dart-define=FIREBASE_APP_ID=your_web_app_id `
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=your_sender_id `
  --dart-define=FIREBASE_PROJECT_ID=your_project_id `
  --dart-define=FIREBASE_STORAGE_BUCKET=your_project_id.appspot.com `
  --dart-define=FIREBASE_AUTH_DOMAIN=your_project_id.firebaseapp.com
```

Firebase Storage rules must allow authenticated/admin uploads for your app setup.
