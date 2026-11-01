# The Citadel — classroom CTF (vulnerable)

A guided teaching app for BIP 2026. This is the **classroom CTF**, separate from the assessed homework CTF at `citadel.961host.online`. All notes, users and credentials are fictional. There are no student records, grades, file access, shell commands or external-service credentials in this app.

The instructor demonstrates a request, captures a `CLASSROOM{...}` flag, opens the corresponding source file and discusses the trust boundary. The instructor's corrections and repaired copy are kept locally and are not included in this repository.

## Run

```sh
npm ci
npm start
```

Open `http://localhost:3250` and select **Load demo as Alice**. No database or secrets are required. The bundled Flutter web build serves its fonts and CanvasKit locally.

Five source files are intentionally weak: `src/session.js`, `src/logs.js`, `src/notes.js`, `src/admin.js` and `src/search.js`. They cover browser credential persistence, logging, object ownership, client-controlled roles and concatenated SQL. The SQL exercise is resource-bounded to a two-record in-memory fixture; its simple OR-injection flaw is intentionally preserved.

`npm test` verifies that the intended weaknesses remain reproducible. Do not reuse these handlers for a real application. The app is a deliberately vulnerable educational fixture, not an authentication starter.

## Teacher reset (hosted copy)

When several people use the same hosted copy, the instructor can sign everyone out: set the environment variable `TEACHER_PASSWORD` on the server, then open `/teacher.html`, type that password and use **Show active sessions** or **Reset the class**. Without the variable the controls stay disabled (HTTP 503). Wrong passwords are throttled. Demo sessions live in memory only, so a restart also clears them.

## Rebuild Flutter

```sh
cd lab-client
flutter pub get
flutter analyze
flutter build web --release --no-web-resources-cdn
cd ..
cp -R lab-client/build/web/. public/
```

Use Node 22+ and Flutter 3.35+ / Dart 3.9+. Deployment uses the included Dockerfile, `PORT`, one instance and `/healthz`. The client must be served from the same origin as the API. Noto fonts are distributed with their OFL license files.
