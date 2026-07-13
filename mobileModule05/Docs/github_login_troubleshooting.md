# GitHub Login Troubleshooting

This note records the GitHub login issues seen while testing
`mobileModule05/advanced_diary_app` with Firebase Authentication.

The app uses Firebase Auth providers:

- Google
- GitHub

Both `diary_app` and `advanced_diary_app` use the same Firebase project:

```text
diary-app-20745
```

Therefore they share the same Firebase Authentication provider setup and the
same Firestore database.

## Important Difference: Chrome Run vs Android App

Running on Chrome means the Flutter app is running as **Flutter Web**.

```text
flutter run -d chrome
```

In this mode, GitHub OAuth happens inside the browser/web Firebase auth flow.

Running on a physical Android phone as an installed app means the app is using
**native Firebase Auth**.

```text
flutter run -d <android-device>
```

In this mode, GitHub sign-in still opens a browser/custom tab because GitHub
login is OAuth-based:

```text
Installed app
→ Firebase Auth GenericIdpActivity
→ default browser/custom tab
→ GitHub
→ Firebase OAuth callback
→ app
```

So even though the app is installed on the phone, GitHub login still depends on
the phone browser that handles the OAuth page and redirect.

## Error: account-exists-with-different-credential

This error can happen when Firebase receives an email from GitHub that already
exists under another Firebase Auth provider, such as Google.

Example:

```text
Google user: user@example.com
GitHub OAuth returns: user@example.com
```

Firebase blocks the sign-in unless account linking is implemented.

Things to check:

- Firebase Console > Authentication > Users
- GitHub account > Settings > Emails
- GitHub primary and verified emails
- Whether a different GitHub browser session is active

GitHub may return a primary verified email, not necessarily the email shown
visually in one place on the GitHub account.

## Debug Logging Used

Temporary debug lines were added in `login_page.dart` to inspect
`FirebaseAuthException` details:

```dart
debugPrint('Auth error provider: $provider');
debugPrint('Auth error code: ${error.code}');
debugPrint('Auth error email: ${error.email}');
debugPrint('Auth error message: ${error.message}');
debugPrint('Auth credential provider: ${error.credential?.providerId}');
```

The most useful field is:

```text
Auth error email
```

If this value is present, it identifies the email Firebase thinks is conflicting.

If it is `null`, Firebase may not have received enough provider information to
identify an email.

## Error: invalid-credential, message "401"

This was seen during Android GitHub login:

```text
Auth error provider: github
Auth error code: invalid-credential
Auth error email: null
Auth error message: "401"
Auth credential provider: null
```

This points to the GitHub OAuth flow being rejected or not completing cleanly.
Possible causes include:

- stale browser/custom-tab session
- wrong GitHub account session
- browser privacy/cookie behavior
- default browser handling the Firebase redirect poorly
- GitHub provider Client ID or Client Secret mismatch in Firebase

Because the same GitHub login worked in Chrome/Flutter Web, the Firebase GitHub
provider setup was not the only issue. The Android browser/custom-tab path also
mattered.

## Chrome / Flutter Web Resolution

When testing in device Chrome or desktop Chrome, GitHub login worked after
using the correct GitHub account/session.

Useful cleanup steps for Chrome web testing:

1. Open `github.com`.
2. Sign out of unwanted GitHub accounts.
3. Clear site data for:

```text
github.com
firebaseapp.com
diary-app-20745.firebaseapp.com
```

4. Retry GitHub login from the Flutter web app.

In Flutter Web, the browser owns the whole OAuth session, so clearing the
browser session directly affects GitHub login behavior.

## Android Phone Resolution

On the Android phone, GitHub cookies and cache were cleared, the diary apps were
uninstalled, and Chrome was set as the default browser.

The important fix was:

```text
Set Chrome as the default browser
```

After that, GitHub login worked.

Why this helped:

- The installed Android app uses native Firebase Auth.
- Native Firebase Auth opens `GenericIdpActivity` for GitHub OAuth.
- `GenericIdpActivity` uses the phone's browser/custom-tab handling.
- When Firefox was the default browser, the OAuth redirect flow failed.
- When Chrome was the default browser, Chrome Custom Tabs handled the GitHub and
  Firebase redirect flow correctly.

No separate Firebase app needed to be installed on Android. `firebaseapp.com` is
only a web domain used by the Firebase OAuth callback:

```text
https://diary-app-20745.firebaseapp.com/__/auth/handler
```

## Android Cleanup Steps Used

Useful Android troubleshooting steps:

1. Uninstall `diary_app` and `advanced_diary_app`.
2. Clear browser site data for:

```text
github.com
firebaseapp.com
diary-app-20745.firebaseapp.com
```

3. Set Chrome as the default browser.
4. Open Chrome manually and confirm the intended GitHub account/session.
5. Reinstall/run the app.
6. Retry GitHub login.

## Timeout Note

A 45-second login timeout made OAuth debugging confusing because GitHub login
can involve leaving the app, completing a browser/custom-tab flow, and returning
to the app.

The timeout was increased to:

```dart
const Duration(minutes: 2)
```

This does not fix provider errors, but it gives the OAuth flow more time to
complete.

## Final Understanding

GitHub login is configured once at the Firebase project provider level.

Both apps can use it because both apps use:

```text
diary-app-20745
```

But Android GitHub OAuth depends on the installed app, Firebase Auth native
flow, the default browser/custom tab, GitHub session cookies, and the Firebase
callback redirect all working together.

For reliable Android testing, Chrome as the default browser worked best.
