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

## 12. Android Setup for Continuation Apps

When a new Flutter project continues the same diary app, for example:

```text
mobileModule04/diary_app
mobileModule05/advanced_diary_app
```

the projects can share the same Firebase project and Firestore database, but each Android app package must still be registered separately in Firebase.

Module 04 uses:

```text
com.example.diary_app
```

Module 05 uses:

```text
com.example.advanced_diary_app
```

Even though both apps use the same Firebase project:

```text
diary-app-20745
```

Firebase Authentication treats each Android package as a separate Android client. Google sign-in on Android checks the package name and signing certificate fingerprints before allowing authentication. Therefore each package needs its own Firebase Android app registration and its own `google-services.json`.

The Firestore documents can still be shared because both apps point to the same Firebase project id and use the same Firestore collections, such as:

```text
notes
```

So:

- Firestore data sharing is controlled by the Firebase project and database.
- Android sign-in trust is controlled by the Android package name plus SHA fingerprints.

### Required Steps for Each Android App

For each Flutter Android app, do the following.

1. Register the Android app in Firebase Console.

For Module 04:

```text
Package name: com.example.diary_app
```

For Module 05:

```text
Package name: com.example.advanced_diary_app
```

2. Generate the debug SHA fingerprints.

Run this from the target app's Android folder:

```bash
cd /home/sthiagar/Desktop/mobile_piscine/mobileModule05/advanced_diary_app/android
./gradlew signingReport
```

Use the `Variant: debug` values:

```text
SHA1
SHA-256
```

For the current development machine, Module 05 used:

```text
SHA1: FB:1F:D6:85:0F:AF:92:89:A5:50:C3:1E:9F:40:5B:F5:3D:77:1F:1B
SHA-256: 9B:2F:C2:4F:99:8D:98:A7:49:DF:A1:3B:11:D8:AE:18:B4:A7:42:E8:F4:F8:3F:3E:00:3A:5F:14:F3:3C:0B:2F
```

3. Add both SHA values in Firebase Console.

Open:

```text
Firebase Console > Project settings > Your apps > Android app
```

Select the matching Android package and add:

```text
SHA-1
SHA-256
```

Then save.

4. Download a fresh `google-services.json`.

After adding SHA values, download the updated file and place it in the target app:

```bash
cp ~/Downloads/google-services.json \
  /home/sthiagar/Desktop/mobile_piscine/mobileModule05/advanced_diary_app/android/app/google-services.json
```

The file must match the app package. For Module 05, it should contain:

```text
package_name: com.example.advanced_diary_app
```

After SHA setup, it should also include an Android OAuth client for the same package:

```text
client_type: 1
certificate_hash: fb1fd6850faf9289a550c31e9f405bf53d771f1b
```

5. Update Gradle configuration.

In `android/settings.gradle.kts`, include the Google Services plugin:

```kotlin
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
    id("com.google.gms.google-services") version "4.4.4" apply false
}
```

In `android/app/build.gradle.kts`, apply the plugin in the app module:

```kotlin
plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("dev.flutter.flutter-gradle-plugin")
}
```

Do not apply `com.android.application`, `kotlin-android`, or `com.google.gms.google-services` in the root `android/build.gradle.kts`. The root file should keep the normal Flutter project-level configuration. Applying app plugins in the root file can cause errors such as:

```text
Cannot add task 'clean' as a task with that name already exists
```

6. Rebuild the project.

From the Flutter project folder:

```bash
flutter clean
flutter pub get
flutter run
```

If testing on a physical Android phone, uninstall the old app from the phone before reinstalling if sign-in still behaves oddly.

### Troubleshooting Notes

If Google login fails with:

```text
GoogleSigninException(... clientId must be provided on Android ...)
```

then Android cannot find the generated Google client id. Check:

- `android/app/google-services.json` exists.
- `android/settings.gradle.kts` declares `com.google.gms.google-services`.
- `android/app/build.gradle.kts` applies `com.google.gms.google-services`.
- The JSON package name matches the app's `applicationId`.

If Google login fails with:

```text
GoogleSigninExceptionCode canceled, [16] Account reauth failed
```

then the Android OAuth client is usually missing or mismatched. Check:

- SHA-1 and SHA-256 were added to the correct Firebase Android app.
- A fresh `google-services.json` was downloaded after saving SHA values.
- The JSON includes `client_type: 1` and a `certificate_hash` for the app package.

GitHub sign-in on Android may open a browser or custom tab. That is normal OAuth behavior. After GitHub/Firebase completes authentication, returning to the app should show the user as signed in.

## 13. Next Phase

Phase 2 will add the service layer:

- Create an `AuthService` abstraction.
- Add Google sign-in logic.
- Add GitHub sign-in logic.
- Add sign-out logic.
- Expose Firebase auth state for navigation and login persistence.
