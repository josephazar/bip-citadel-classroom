# Citadel Notes — native Android classroom CTF

A real Flutter Android notes app with **11 deliberate classroom weaknesses**, mapped to the OWASP Mobile Top 10 (2024). It installs as **Citadel Notes** (`online.citadel.classroom.vulnerable`), uses a local Node API, and has native file storage, logcat output and an Android diagnostics activity. It is separate from the graded homework CTF.

All users, notes, keys and flags are fictional. The bundled supply-chain SDK sends data only to this same classroom API. No cloud account, database, paid service, Google login or real personal data is needed. Use this fixture on your own emulator; it is intentionally vulnerable.

## Run on an Android emulator

Requirements: Python 3, Node 22+, Flutter **3.35.7 / Dart 3.9.2** or a compatible version, Java 17+ (this Mac uses Android Studio's bundled Java 21), Android SDK and an Android AVD. Android Studio does not have to remain open. Complete Android SDK license acceptance interactively if required. No Docker is needed.

```sh
git clone https://github.com/josephazar/bip-citadel-classroom.git
cd bip-citadel-classroom
npm ci
python3 scripts/android-demo.py run
```

The launcher reuses a running emulator or launches an installed AVD (preferring `BIP_Gate_API_35`), starts the API on loopback port **3260**, gets the locked Flutter dependencies, builds and installs the native app, then attaches Flutter. Tap **Load demo as Alice**. Use **My notes**, **Security lab** and **Flags**. Eleven flags, no grades.

Press `r` in the Flutter terminal for hot reload, `R` for hot restart and `q` to detach. The API keeps running for code demonstrations. It restarts when `src/` changes; load Alice again after a restart.

Stop this demo's backend and its installed Android app:

```sh
cd bip-citadel-classroom
python3 scripts/android-demo.py stop
```

The emulator and other course apps stay running. Keys, logs and launcher state are ignored under `.local/`.

### Manual commands

Terminal A, from the repository root:

```sh
npm ci
HOST=127.0.0.1 PORT=3260 npm run dev
```

Terminal B, from the repository root (start an AVD first if needed):

```sh
cd lab-client
flutter pub get --enforce-lockfile
flutter devices
flutter run -d emulator-5554 --no-enable-impeller --dart-define=API_URL=http://10.0.2.2:3260
```

Replace `emulator-5554` with the running device ID. The AVD name and the device ID are different. `10.0.2.2` reaches the Mac/Linux host from the standard Android emulator; the emulator's `localhost` means Android itself.

## Code tour

- `lab-client/lib/main.dart`: native screens and eleven exercise pages.
- `lab-client/lib/api.dart`: same-origin web / bearer-authenticated native API calls.
- `lab-client/lib/platform_android.dart`: native persistence, logging and network client.
- `lab-client/lib/crypto_lab.dart`: intentionally incorrect key/nonce management.
- `lab-client/third_party/notes_insights/`: harmless local supply-chain teaching fixture.
- `lab-client/android/app/src/main/`: manifest and Kotlin activities.
- `src/`: API authentication, ownership, role, query and mobile examples.
- [OWASP coverage and limits](docs/OWASP-COVERAGE.md).

The public repository contains the vulnerable teaching version. Instructor corrections are maintained separately.

## Checks

```sh
npm test
cd lab-client
flutter analyze
flutter test
cd ..
python3 scripts/android-demo.py test
```

The last command runs real Android integration checks: API requests, persisted session, crypto behavior and screen interactions. `python3 scripts/android-demo.py build` builds a debug APK without opening the app. The artifact is `lab-client/build/app/outputs/flutter-apk/app-debug.apk`.

## Browser companion

The existing Flutter Web companion remains available; Android-specific exercises require the APK. From the repository root:

```sh
PORT=3250 npm start
```

Open `http://localhost:3250`. Rebuild the bundled web client after Dart changes:

```sh
cd lab-client
flutter build web --release --no-web-resources-cdn --pwa-strategy=none
cd ..
cp -R lab-client/build/web/. public/
```

The web client uses relative API URLs and must share the API's origin. Native `flutter run` does not use the bundled web build. Teacher reset controls remain disabled unless `TEACHER_PASSWORD` is configured in the server environment; no real credentials belong in this repo.
