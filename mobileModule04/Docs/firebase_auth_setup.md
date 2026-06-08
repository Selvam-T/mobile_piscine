# Diary App Firebase Authentication Setup

This document records the Phase 1 setup for adding Firebase Authentication to the `diary_app` Flutter project.

The authentication system chosen for this project is **Firebase Authentication**. Firebase Auth stores and manages users, supports login persistence, and provides sign-in providers such as Google and GitHub.

## 1. Project Location

The Flutter project is located at:

```bash
/home/sthiagar/Desktop/mobile_piscine/mobileModule04/diary_app
```

Move into the project before running setup commands:

```bash
cd /home/sthiagar/Desktop/mobile_piscine/mobileModule04/diary_app
```

## 2. Add Firebase Dependencies

The following packages were added:

```bash
flutter pub add firebase_core firebase_auth google_sign_in
```

Purpose of each dependency:

- `firebase_core`: initializes Firebase in the Flutter app.
- `firebase_auth`: provides Firebase Authentication APIs.
- `google_sign_in`: supports Google account sign-in from Flutter.

Then dependencies were fetched:

```bash
flutter pub get
```

The resulting `pubspec.yaml` contains:

```yaml
firebase_core: ^4.10.0
firebase_auth: ^6.5.2
google_sign_in: ^7.2.0
```

## 3. Firebase CLI Login

Firebase CLI access was authorized using the evaluation Google account:

```text
selvam.coder@gmail.com
```

Because Firebase CLI was installed locally for this setup, commands used the local executable:

```bash
/tmp/firebase-tools12/node_modules/.bin/firebase login
```

The browser opened a Google login/authorization page. The account `selvam.coder@gmail.com` was selected, and Firebase CLI access was allowed.

Login was verified with:

```bash
/tmp/firebase-tools12/node_modules/.bin/firebase login:list
```

## 4. Firebase Project

A Firebase project was created in the Firebase Console:

```text
Project name: Diary App
Project ID: diary-app-20745
Google Analytics: Disabled
```

The project was confirmed from the terminal:

```bash
/tmp/firebase-tools12/node_modules/.bin/firebase projects:list
```

The project list showed `Diary App` with project id `diary-app-20745`.

## 5. FlutterFire CLI Configuration

FlutterFire CLI was used to connect the Flutter app to the Firebase project.

The command used was:

```bash
PATH="/tmp/firebase-tools12/node_modules/.bin:$HOME/.pub-cache/bin:$PATH" \
flutterfire configure \
  --project=diary-app-20745 \
  --platforms=android,web
```

The Android package id used by the current project is:

```text
com.example.diary_app
```

The configuration generated the Firebase options and Android config files.

Important generated files:

```bash
lib/firebase_options.dart
android/app/google-services.json
firebase.json
```

The following file was not generated:

```bash
web/firebase-messaging-sw.js
```

This is acceptable for the current authentication setup. That file is related to Firebase Cloud Messaging, not basic Google/GitHub authentication.

## 6. Enable Google Sign-In

Google sign-in was enabled in Firebase Console.

Steps followed:

1. Open Firebase Console.
2. Select the project:

```text
Diary App
```

3. Open:

```text
Build > Authentication > Sign-in method
```

4. Select the Google provider.
5. Enable Google sign-in.
6. Save the provider settings.

Google sign-in lets users authenticate with an existing Google account. Firebase Auth then creates and manages the user record in the Firebase project.

## 7. Enable GitHub Sign-In

GitHub sign-in was also enabled in Firebase Console.

GitHub sign-in provides a second authentication option for users who prefer a developer-focused account. This is useful for the diary app requirement because the login page must offer Google or GitHub account login. Firebase still remains the central authentication system: after the GitHub OAuth flow succeeds, Firebase Auth stores and manages the signed-in user.

Steps followed in Firebase Console:

1. Open Firebase Console.
2. Select project `Diary App`.
3. Open:

```text
Build > Authentication > Sign-in method
```

4. Select the GitHub provider.
5. Enable GitHub sign-in.
6. Copy the Firebase OAuth callback URL shown by Firebase.

The callback URL format is:

```text
https://diary-app-20745.firebaseapp.com/__/auth/handler
```

Steps followed in GitHub:

1. Open GitHub.
2. Open the profile menu.
3. Go to:

```text
Settings > Developer settings > OAuth Apps
```

4. Create a new OAuth App.
5. Use the following values:

```text
Application name: Diary App
Homepage URL: https://diary-app-20745.firebaseapp.com
Authorization callback URL: https://diary-app-20745.firebaseapp.com/__/auth/handler
```

6. After creating the OAuth App, copy the GitHub `Client ID`.
7. Generate and copy a GitHub `Client secret`.

Then return to Firebase Console:

1. Paste the GitHub `Client ID` into the GitHub provider settings.
2. Paste the GitHub `Client secret`.
3. Save the provider.

No new `google-services.json` download was required for enabling GitHub sign-in. The GitHub provider configuration lives in Firebase Auth provider settings.

Quick verification:

- Firebase Console should show the GitHub provider as enabled under `Authentication > Sign-in method`.
- GitHub OAuth App should have the Firebase callback URL exactly:

```text
https://diary-app-20745.firebaseapp.com/__/auth/handler
```

The full runtime verification will happen after the app has an auth service and login UI. A successful GitHub login should create a user under:

```text
Firebase Console > Authentication > Users
```

## 8. Add Android SHA Fingerprints

Firebase uses Android SHA certificate fingerprints to verify that Android sign-in requests are coming from the registered app. This is especially important for Google sign-in on Android.

For development builds, the required fingerprints come from the debug signing certificate.

The SHA fingerprints were generated from Gradle using the Android wrapper included in the Flutter project:

```bash
cd /home/sthiagar/Desktop/mobile_piscine/mobileModule04/diary_app/android
./gradlew signingReport
```

The important section in the output was the `debug` variant:

```text
Variant: debug
SHA1: ...
SHA-256: ...
```

Both values were copied into Firebase Console:

1. Open Firebase Console.
2. Select project `Diary App`.
3. Open project settings using the gear icon.
4. In `Your apps`, select the Android app.
5. Add the debug `SHA-1` fingerprint.
6. Add the debug `SHA-256` fingerprint.
7. Save the changes.

After saving the fingerprints, a new `google-services.json` file was downloaded from Firebase Console and used to replace the existing Android config file:

```bash
cd /home/sthiagar/Desktop/mobile_piscine/mobileModule04/diary_app
cp ~/Downloads/google-services.json android/app/google-services.json
```

If the browser downloaded the file with a suffix, for example `google-services (1).json`, the command should quote the filename:

```bash
cp ~/Downloads/"google-services (1).json" android/app/google-services.json
```

The replacement was confirmed with:

```bash
ls -l android/app/google-services.json
```

At this point, Android Firebase configuration for Google sign-in was complete.

## 9. Firebase Initialization in Flutter

Firebase was initialized in `lib/main.dart`.

Imports added:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
```

The `main()` function was updated to initialize Firebase before starting the app:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}
```

A minimal `MyApp` widget was kept in place so the app can run and confirm Firebase initialization:

```dart
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Diary App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Diary App Firebase setup complete'),
        ),
      ),
    );
  }
}
```

## 10. Phase 1 Verification

Static analysis was run:

```bash
flutter analyze
```

Expected result:

```text
No issues found!
```

The app can then be tested in Chrome:

```bash
flutter run -d chrome
```

Expected screen:

```text
Diary App Firebase setup complete
```

This confirms that Firebase configuration and initialization are working.

## 11. Phase 1 Status

Completed:

- Firebase project created.
- Firebase Auth selected as the authentication system.
- Google sign-in enabled in Firebase Console.
- GitHub sign-in enabled in Firebase Console.
- GitHub OAuth App created and connected to Firebase Auth.
- Android app registered with Firebase.
- Android `SHA-1` and `SHA-256` fingerprints added.
- Updated `google-services.json` downloaded and replaced.
- Web config generated through FlutterFire.
- Firebase initialized in `lib/main.dart`.

Skipped intentionally:

- iOS config.

## 12. Next Phase

Phase 2 will add the service layer:

- Create an `AuthService` abstraction.
- Add Google sign-in logic.
- Add GitHub sign-in logic.
- Add sign-out logic.
- Expose Firebase auth state for navigation and login persistence.
