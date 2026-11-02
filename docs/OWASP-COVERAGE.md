# Classroom coverage — OWASP Mobile Top 10 (2024)

| Exercise | Main category | Observable behavior | Source |
|---|---|---|---|
| C01 Session left behind | M9 Insecure Data Storage | Bearer token in native `app_flutter/session.json`; browser Local Storage companion | `lab-client/lib/platform_android.dart`, `platform_web.dart` |
| C02 Chatty app | M6 Inadequate Privacy Controls | Token + fictional email in logcat and diagnostics response | `platform_android.dart`, `src/logs.js` |
| C03 Next notebook | M3 Insecure Authentication/Authorization | Alice requests Bob's note by ID | `src/notes.js` |
| C04 Who chooses the role | M3 Insecure Authentication/Authorization | Changing `X-Lab-Role` grants admin data | `src/admin.js` |
| C05 Text becomes SQL | M4 Insufficient Input/Output Validation | Input changes a two-record fixture query | `src/search.js` |
| C06 Inside the APK | M1 Improper Credential Usage | Bundled shared key authorizes partner report | `assets/partner-config.json`, `src/mobile.js` |
| C07 Helpful dependency | M2 Inadequate Supply Chain Security | Actual vendored Dart SDK adds token + email to its insight payload | `third_party/notes_insights`, `lib/insights.dart`, `src/mobile.js` |
| C08 Across the wire | M5 Insecure Communication | HTTP authentication and an accept-all TLS certificate callback | `platform_android.dart`, Android manifest |
| C09 Patched premium screen | M7 Insufficient Binary Protections (partial); also M3 | Change local premium state; server trusts patchable client assertion | `main.dart`, `src/mobile.js` |
| C10 Exported door | M8 Security Misconfiguration | External process starts internal activity that reads session file; backups allowed | Android manifest, `DiagnosticsActivity.kt` |
| C11 Repeating secret | M10 Insufficient Cryptography | AES-GCM with a hardcoded key and repeated zero nonce | `lib/crypto_lab.dart` |

The original five demonstrations remain and six mobile-oriented exercises have been added. These are category examples, not a complete MASVS audit or a claim that every attack in each category is implemented.

M2 is a deliberately local, visible dependency-review exercise. It does not fetch a malicious package or contact an outside collector. Application lockfiles are still committed so the class can reproduce the fixture; a lockfile does not make the locked code trustworthy.

M7 uses a local-state switch to model the effect of changing a binary. It does not perform a real Frida/repackaging exploit. Server-side checks and release obfuscation are discussed in the instructor material. Play Integrity, production signing and RASP are outside this emulator lab; no claim of full binary tamper resistance is made.

The Android `run-as` inspection uses a debuggable teaching build. It does not imply any arbitrary installed app can read another application's sandbox on a stock device. The exported-activity exercise separately demonstrates an actual cross-process exposure. Modern Android backup restrictions vary; the exercise does not rely on deprecated `adb backup` behavior.

The fixed reference uses local HTTPS for native debug demonstrations, with one explicitly trusted local certificate and hostname validation. It is a teaching reference, not production identity management. Alice's one-tap fixture login, known flag catalog, in-memory data and debug signing remain deliberate lab facilities.

The supplied Flutter/Dart audit guided this exercise selection. Its incident statistics/CVE examples are not reproduced or asserted here. Build-time Dart defines, `.env` packaging and obfuscation do not turn a client-side credential into a secret.

References:
- [OWASP Mobile Top 10 project](https://owasp.org/projects/mobile-top-10)
- [Flutter obfuscation and its limits](https://docs.flutter.dev/deployment/obfuscate)
- [Android emulator address space](https://developer.android.com/studio/run/emulator-networking-address)
- [Flutter Secure Storage](https://pub.dev/packages/flutter_secure_storage)
- [Dart cryptography package](https://pub.dev/packages/cryptography)
