# Voice companion app

Flutter client for the Mobile AI Voice Companion. Setup, the backend URL, and how speech and text-to-speech are wired are in the repository [README](../README.md).

From this directory:

```bash
flutter pub get
flutter run --dart-define=BACKEND_URL=http://10.0.2.2:8080
```

`flutter test` covers the conversation controller and the chat screen with fake speech, fake speech synthesis, and a fake HTTP client.
