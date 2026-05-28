# Mobile Piscine Notes

## 1. Placeholder

This section will be updated later.

## 2. What Happens When Running `flutter run -d chrome`

When this command is executed:

```bash
flutter run -d chrome
```

Flutter runs the app as a web application in Chrome. The `-d chrome` option tells Flutter to use Chrome as the target device instead of an Android phone, Linux desktop, or another available device.

The sequence is:

1. Flutter reads the project files, including:

```text
pubspec.yaml
lib/main.dart
web/index.html
```

2. Flutter gets the project dependencies.

If the output says:

```text
Got dependencies!
8 packages have newer versions incompatible with dependency constraints.
```

that means dependency installation succeeded. The version messages are warnings only. They mean newer package versions exist, but the current `pubspec.yaml` constraints do not allow those newer versions.

3. Flutter selects Chrome as the target device.

Because the command includes:

```bash
-d chrome
```

Flutter launches the app in Chrome.

4. Flutter compiles the Dart application for the web.

The main source file:

```text
lib/main.dart
```

is compiled into browser-runnable web code.

5. Flutter starts a local debug web server.

The app is served from a temporary local URL, usually similar to:

```text
http://localhost:<random-port>
```

6. Flutter opens Chrome.

The message:

```text
Launching lib/main.dart on Chrome in debug mode...
```

means Flutter is starting Chrome and pointing it to the local development server.

7. Flutter waits for the browser debug connection.

The message:

```text
Waiting for connection from debug service on Chrome...
```

means Flutter is waiting for Chrome to connect back to the debug service. This enables development features such as hot reload, logs, errors, and DevTools.

The debug service is started because `flutter run -d chrome` runs the app in debug mode by default. Debug mode is meant for development, so Flutter keeps a live connection between the terminal, the Flutter tool, and the running app in Chrome.

That live debug connection is what allows:

- Hot reload, so code changes can be injected into the running app without restarting everything.
- Hot restart, so the app can restart quickly while keeping the development server alive.
- Debug console output, including messages from `print()` and `debugPrint()`.
- Runtime error reporting, so exceptions and stack traces are shown in the terminal.
- Flutter DevTools connection, for inspecting widgets, layout, performance, memory, and logs.

Without the debug service, Flutter could still build and serve the web app, but it would lose most of the interactive development features that make `flutter run` useful during coding.

8. The app opens in Chrome.

After the debug connection is ready, the Flutter app appears in the browser.

In short:

```text
flutter run -d chrome
= get dependencies
+ compile Flutter app for web
+ start local development server
+ open Chrome
+ connect debug service
+ run the app
```

The time shown in the terminal, for example:

```text
took 13.8s
```

mostly comes from web compilation, starting Chrome, and connecting the debug service.

## 3. What Happens When Running `flutter run -d <phone id>`

When this command is executed from inside a Flutter app folder:

```bash
flutter run -d R9WWB0HA0EM
```

Flutter runs the app on the specific Android phone with that device id. The `-d` option means "device", and `R9WWB0HA0EM` is the phone id reported by:

```bash
flutter devices
```

The sequence is:

1. Flutter checks the selected app project.

Flutter reads the app files, including:

```text
pubspec.yaml
lib/main.dart
android/
```

2. Flutter gets the project dependencies.

```text
Resolving dependencies...
Downloading packages...
Got dependencies!
```

If Flutter prints:

```text
4 packages have newer versions incompatible with dependency constraints.
Try `flutter pub outdated` for more information.
```

this is a warning, not a build failure. It means newer package versions exist, but the current `pubspec.yaml` constraints do not allow those newer versions.

3. Flutter selects the Android phone by device id.

```bash
flutter run -d R9WWB0HA0EM
```

The `-d R9WWB0HA0EM` part tells Flutter to run the app on that specific connected Android device. If the phone is detected correctly, Flutter shows the phone model:

```text
Launching lib/main.dart on SM A146P in debug mode...
```

4. Flutter builds a debug Android APK.

```text
Running Gradle task 'assembleDebug'...
Built build/app/outputs/flutter-apk/app-debug.apk
```

`assembleDebug` is the Android Gradle task that compiles the Flutter app and packages it as a debug APK. A debug APK is meant for development, so it includes debugging support.

5. Flutter installs the debug APK on the phone.

```text
Installing build/app/outputs/flutter-apk/app-debug.apk...
```

At this point Flutter uses ADB to copy and install the APK onto the Android phone.

6. Flutter starts the app on the phone in debug mode.

Debug mode keeps a live connection between Flutter and the running app. This allows:

- Hot reload.
- Hot restart.
- Debug console output from `print()` and `debugPrint()`.
- Runtime error and stack trace reporting.
- Flutter DevTools inspection.

In short:

```text
flutter run -d <phone id>
= get dependencies
+ select the connected phone
+ build debug APK with Gradle
+ install APK on phone with ADB
+ launch app on phone in debug mode
```
