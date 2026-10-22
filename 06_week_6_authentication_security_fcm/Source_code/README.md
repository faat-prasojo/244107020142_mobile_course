# Campus Notify (Week 6: Authentication, Security & FCM)

Terhubung ke project Firebase `week6-mobile-course`.

## Setup (sekali saja)

```bash
flutter pub add firebase_core firebase_auth firebase_messaging flutter_riverpod go_router flutter_secure_storage
dart pub global activate flutterfire_cli
flutterfire configure --project=week6-mobile-course
```

`flutterfire configure` menimpa `lib/firebase_options.dart` (sekarang masih placeholder)
dan membuat `android/app/google-services.json`.

Di Firebase Console: Authentication > Sign-in method > aktifkan **Email/Password**.

## Menjalankan dan menguji

```bash
flutter analyze
flutter test
flutter run
```

Uji FCM: login, salin token di halaman Home, lalu Firebase Console > Messaging >
New campaign > Send test message. Isi Additional options > Custom data dengan
`route` = `/announcement`. Uji tiga state: foreground, background, terminated.

## Struktur

```
lib/
├── main.dart
├── firebase_options.dart
├── router/app_router.dart
├── auth/{token_store,auth_controller,login_page}.dart
├── messaging/push_service.dart
└── pages/{home_page,announcement_page}.dart
```
