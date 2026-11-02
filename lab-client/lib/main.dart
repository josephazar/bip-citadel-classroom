import 'dart:convert';
import 'package:flutter/material.dart';
import 'api.dart';
import 'crypto_lab.dart';
import 'demo_config.dart';
import 'insights.dart';
import 'platform.dart';

const ink = Color(0xff132b43);
const blue = Color(0xff087eb9);
const paper = Color(0xfff3f6fb);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ClassroomApp());
}

class ClassroomApp extends StatelessWidget {
  const ClassroomApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: isFixed ? 'Citadel Notes Fixed' : 'Citadel Notes',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      fontFamily: 'NotoSans',
      colorScheme: ColorScheme.fromSeed(seedColor: blue),
      scaffoldBackgroundColor: paper,
      appBarTheme: const AppBarTheme(
        backgroundColor: paper,
        foregroundColor: ink,
        surfaceTintColor: Colors.transparent,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
    ),
    home: frameApp(const NotesHome()),
  );
}

class Exercise {
  const Exercise(this.id, this.title, this.risk, this.hint, this.icon);
  final int id;
  final String title, risk, hint;
  final IconData icon;
}

const exercises = [
  Exercise(
    1,
    'A session left behind',
    'M9 · Data storage',
    'Sign in, close and reopen the app. Inspect what was saved on the device.',
    Icons.folder_open,
  ),
  Exercise(
    2,
    'The chatty app',
    'M6 · Privacy',
    'Inspect diagnostics and Android logcat after signing in. What should never have been logged?',
    Icons.bug_report_outlined,
  ),
  Exercise(
    3,
    'The next notebook',
    'M3 · Authorization',
    'Alice owns note 101. Does knowing another note ID grant permission to read it?',
    Icons.lock_open_outlined,
  ),
  Exercise(
    4,
    'Who chooses the role?',
    'M3 · Authorization',
    'Change a request header. Does the API trust the phone to decide who is an admin?',
    Icons.admin_panel_settings_outlined,
  ),
  Exercise(
    5,
    'When text becomes SQL',
    'M4 · Input validation',
    'Search for a title, then try an apostrophe. Follow the input into the query.',
    Icons.search,
  ),
  Exercise(
    6,
    'Inside the APK',
    'M1 · Credentials',
    'Inspect the assets packaged in the APK. Is a shared partner key really a secret?',
    Icons.inventory_2_outlined,
  ),
  Exercise(
    7,
    'A helpful dependency?',
    'M2 · Supply chain',
    'The local notes_insights SDK counts notebook opens. Inspect its source and payload.',
    Icons.extension_outlined,
  ),
  Exercise(
    8,
    'Across the wire',
    'M5 · Communication',
    'Check the API URL, Android manifest and certificate validation code.',
    Icons.wifi_outlined,
  ),
  Exercise(
    9,
    'A patched premium screen',
    'M7 · Binary protections',
    'A patch can change local state. Does the server independently verify membership?',
    Icons.verified_user_outlined,
  ),
  Exercise(
    10,
    'An exported door',
    'M8 · Misconfiguration',
    'Can a different Android process open the internal diagnostics activity?',
    Icons.door_front_door_outlined,
  ),
  Exercise(
    11,
    'The repeating secret',
    'M10 · Cryptography',
    'Encrypt the same note twice. Inspect the key and nonce; changing the algorithm alone is not enough.',
    Icons.enhanced_encryption_outlined,
  ),
];

class NotesHome extends StatefulWidget {
  const NotesHome({super.key});
  @override
  State<NotesHome> createState() => _NotesHomeState();
}

class _NotesHomeState extends State<NotesHome> {
  LabApi? api;
  final store = SessionStore();
  final flags = <String>{};
  final flagInput = TextEditingController();
  final searchInput = TextEditingController();
  int tab = 0;
  bool busy = true, signedIn = false;
  String? startupError;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    try {
      final client = await LabApi.create();
      client.token = await store.read();
      if (!mounted) {
        client.close();
        return;
      }
      setState(() {
        api = client;
        signedIn = client.token != null;
        busy = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          startupError = '$e';
          busy = false;
        });
      }
    }
  }

  Future<void> login() async {
    setState(() => busy = true);
    try {
      final response = await api!.request('/demo/login', body: {});
      if (response.status != 200) throw StateError('${response.data}');
      api!.token = response.data['sessionToken'] as String;
      await store.write(api!.token!);
      logSession(api!.token!);
      if (mounted) setState(() => signedIn = true);
    } catch (e) {
      if (mounted) await showResult(context, 'Connection', {'error': '$e'});
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> logout() async {
    try {
      if (api?.token != null) await api!.request('/demo/logout', body: {});
      await store.clear();
      api?.token = null;
      if (mounted) {
        setState(() {
          signedIn = false;
          flags.clear();
          tab = 0;
        });
      }
    } catch (e) {
      if (mounted) await showResult(context, 'Sign out', {'error': '$e'});
    }
  }

  Future<void> openNote(String id) async {
    try {
      final r = await api!.request('/lab-api/notes/${Uri.encodeComponent(id)}');
      if (mounted) {
        await showResult(context, 'Notebook · HTTP ${r.status}', r.data);
      }
    } catch (e) {
      if (mounted) await showResult(context, 'Notebook', {'error': '$e'});
    }
  }

  @override
  void dispose() {
    api?.close();
    flagInput.dispose();
    searchInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Row(
        children: [
          Icon(Icons.shield_outlined, color: blue),
          SizedBox(width: 9),
          Text(
            'Citadel Notes',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 21),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Chip(
            label: Text(
              isFixed ? 'FIXED' : 'CLASSROOM',
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
            side: BorderSide.none,
            backgroundColor: isFixed
                ? const Color(0xffd9f4e6)
                : const Color(0xffdceefa),
          ),
        ),
      ],
    ),
    body: busy && api == null
        ? const Center(child: CircularProgressIndicator())
        : startupError != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(startupError!),
            ),
          )
        : IndexedStack(index: tab, children: [notes(), labs(), captures()]),
    bottomNavigationBar: NavigationBar(
      selectedIndex: tab,
      height: 72,
      onDestinationSelected: (value) => setState(() => tab = value),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.sticky_note_2_outlined),
          selectedIcon: Icon(Icons.sticky_note_2),
          label: 'My notes',
        ),
        NavigationDestination(
          icon: Icon(Icons.science_outlined),
          selectedIcon: Icon(Icons.science),
          label: 'Security lab',
        ),
        NavigationDestination(
          icon: Icon(Icons.flag_outlined),
          selectedIcon: Icon(Icons.flag),
          label: 'Flags',
        ),
      ],
    ),
  );

  Widget notes() => ListView(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
    children: [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: const LinearGradient(
            colors: [Color(0xff113f60), Color(0xff098bc3)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.auto_stories_outlined,
              color: Colors.white,
              size: 38,
            ),
            const SizedBox(height: 24),
            Text(
              signedIn
                  ? 'A little space\nfor your ideas.'
                  : 'Your notes.\nYour little citadel.',
              style: const TextStyle(
                fontSize: 29,
                height: 1.15,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Personal notebooks, always close by.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            if (!signedIn)
              FilledButton(
                onPressed: busy ? null : login,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: ink,
                ),
                child: Text(busy ? 'Connecting…' : 'Load demo as Alice'),
              )
            else
              const Row(
                children: [
                  CircleAvatar(
                    radius: 17,
                    backgroundColor: Colors.white24,
                    child: Text('A', style: TextStyle(color: Colors.white)),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Alice · Personal workspace',
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
          ],
        ),
      ),
      if (signedIn)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: busy ? null : login,
            icon: const Icon(Icons.refresh),
            label: const Text('Renew demo session'),
          ),
        ),
      const SizedBox(height: 24),
      const Text(
        'Your notebooks',
        style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: ink),
      ),
      const SizedBox(height: 8),
      Card(
        child: ListTile(
          contentPadding: const EdgeInsets.all(18),
          leading: const CircleAvatar(
            backgroundColor: Color(0xffffefc8),
            child: Icon(Icons.shopping_bag_outlined, color: Color(0xffa77600)),
          ),
          title: const Text(
            'My shopping',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: const Text('A few things to remember · Note 101'),
          trailing: const Icon(Icons.chevron_right),
          onTap: signedIn ? () => openNote('101') : null,
        ),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: searchInput,
        enabled: signedIn,
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(
          hintText: 'Search your notes',
          prefixIcon: Icon(Icons.search),
        ),
        onSubmitted: (_) => runSearch(),
      ),
      const SizedBox(height: 10),
      if (signedIn)
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: runSearch,
            child: const Text('Search notes'),
          ),
        ),
      const SizedBox(height: 20),
      Card(
        color: const Color(0xffe5edf5),
        child: const Padding(
          padding: EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.school_outlined, color: blue),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'A fictional notes app for guided security practice. Open Security lab to explore the eleven exercises.',
                  style: TextStyle(height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
      if (signedIn)
        TextButton.icon(
          onPressed: logout,
          icon: const Icon(Icons.logout, size: 18),
          label: const Text('Sign out'),
        ),
    ],
  );
  Future<void> runSearch() async {
    try {
      final r = await api!.request(
        '/lab-api/search?q=${Uri.encodeQueryComponent(searchInput.text)}',
      );
      if (mounted) {
        await showResult(context, 'Search · HTTP ${r.status}', r.data);
      }
    } catch (e) {
      if (mounted) await showResult(context, 'Search', {'error': '$e'});
    }
  }

  Widget labs() => ListView(
    padding: const EdgeInsets.all(20),
    children: [
      const Text(
        'Behind the walls',
        style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: ink),
      ),
      const SizedBox(height: 8),
      const Text(
        '11 exercises · OWASP Mobile Top 10',
        style: TextStyle(color: Colors.black54),
      ),
      const SizedBox(height: 18),
      if (!signedIn)
        Card(
          color: const Color(0xffffefc8),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Load demo as Alice on My notes before starting.'),
          ),
        ),
      ...exercises.map(
        (e) => Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
            leading: CircleAvatar(
              backgroundColor: const Color(0xffe9f3fa),
              child: Icon(e.icon, color: blue),
            ),
            title: Text(
              e.title,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                'C${e.id.toString().padLeft(2, '0')}  /  ${e.risk}',
                style: const TextStyle(fontSize: 11),
              ),
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: !signedIn
                ? null
                : () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) =>
                          ExercisePage(exercise: e, api: api!, store: store),
                    ),
                  ),
          ),
        ),
      ),
    ],
  );
  Widget captures() => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const Text(
        'Flags collected',
        style: TextStyle(fontSize: 27, fontWeight: FontWeight.w800, color: ink),
      ),
      const SizedBox(height: 24),
      Center(
        child: SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: flags.length / totalFlags,
                  backgroundColor: const Color(0xffdce6ef),
                  strokeWidth: 12,
                ),
              ),
              Text(
                '${flags.length} / $totalFlags',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 28),
      TextField(
        controller: flagInput,
        autocorrect: false,
        enableSuggestions: false,
        decoration: const InputDecoration(
          labelText: 'CLASSROOM{...}',
          prefixIcon: Icon(Icons.flag_outlined),
        ),
      ),
      const SizedBox(height: 12),
      FilledButton(
        onPressed: !signedIn
            ? null
            : () async {
                try {
                  final value = flagInput.text.trim();
                  final r = await api!.request(
                    '/demo/capture',
                    body: {'flag': value},
                  );
                  if (!mounted) return;
                  if (r.data['captured'] == true) {
                    setState(() {
                      flags.add(value);
                      flagInput.clear();
                    });
                  } else {
                    await showResult(context, 'Flag', {
                      'message':
                          'No matching classroom flag. Sign in again if the demo session expired.',
                    });
                  }
                } catch (e) {
                  if (mounted) {
                    await showResult(context, 'Flag', {'error': '$e'});
                  }
                }
              },
        child: const Text('Capture flag'),
      ),
      const SizedBox(height: 20),
      ...flags.map(
        (f) => Card(
          child: ListTile(
            leading: const Icon(Icons.check_circle, color: Colors.green),
            title: Text(
              f,
              style: const TextStyle(fontFamily: 'NotoSansMono', fontSize: 11),
            ),
          ),
        ),
      ),
    ],
  );
}

class ExercisePage extends StatefulWidget {
  const ExercisePage({
    super.key,
    required this.exercise,
    required this.api,
    required this.store,
  });
  final Exercise exercise;
  final LabApi api;
  final SessionStore store;
  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage> {
  final input = TextEditingController();
  bool busy = false, elevated = false;
  String role = 'user';
  @override
  void initState() {
    super.initState();
    input.text = switch (widget.exercise.id) {
      3 => '101',
      5 => 'Shopping',
      11 => 'My private note',
      _ => '',
    };
  }

  @override
  void dispose() {
    input.dispose();
    super.dispose();
  }

  Future<void> run(Future<LabResponse> Function() action) async {
    setState(() => busy = true);
    try {
      final r = await action();
      if (mounted) {
        setState(() => busy = false);
        await showResult(context, 'Result · HTTP ${r.status}', r.data);
      }
    } catch (e) {
      if (mounted) await showResult(context, 'Result', {'error': '$e'});
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget field(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextField(
      controller: input,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(labelText: label),
    ),
  );
  Widget button(String label, VoidCallback action) => FilledButton.icon(
    onPressed: busy ? null : action,
    icon: busy
        ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : const Icon(Icons.play_arrow_rounded),
    label: Text(label),
  );
  List<Widget> controls() {
    final api = widget.api;
    switch (widget.exercise.id) {
      case 1:
        return [
          const Text(
            'Inspect the app’s actual saved session. On Android, compare it with run-as file inspection.',
          ),
          const SizedBox(height: 18),
          button(
            'Inspect saved session',
            () => run(
              () async =>
                  LabResponse(200, {'saved': await widget.store.inspect()}),
            ),
          ),
        ];
      case 2:
        return [
          const Text(
            'The app also writes a login event to Android logcat. Compare native logs with this API response.',
          ),
          const SizedBox(height: 18),
          button(
            'Read debug logs',
            () => run(() => api.request('/lab-api/logs')),
          ),
        ];
      case 3:
        return [
          field('Note ID'),
          button(
            'Read note',
            () => run(
              () => api.request(
                '/lab-api/notes/${Uri.encodeComponent(input.text)}',
              ),
            ),
          ),
        ];
      case 4:
        return [
          DropdownButtonFormField<String>(
            initialValue: role,
            decoration: const InputDecoration(labelText: 'X-Lab-Role header'),
            items: [
              'user',
              'admin',
            ].map((r) => DropdownMenuItem(value: r, child: Text(r))).toList(),
            onChanged: (r) => setState(() => role = r!),
          ),
          const SizedBox(height: 18),
          button(
            'Open admin archive',
            () => run(
              () =>
                  api.request('/lab-api/admin', headers: {'X-Lab-Role': role}),
            ),
          ),
        ];
      case 5:
        return [
          field('Search note titles'),
          button(
            'Search',
            () => run(
              () => api.request(
                '/lab-api/search?q=${Uri.encodeQueryComponent(input.text)}',
              ),
            ),
          ),
        ];
      case 6:
        return [
          field('Extracted partner key'),
          button(
            'Request partner report',
            () => run(
              () => api.request(
                '/lab-api/partner',
                headers: {'X-Partner-Key': input.text},
              ),
            ),
          ),
        ];
      case 7:
        return [
          const Text(
            'Send a notebook-opened event using the bundled demo SDK. Inspect which fields it collects and then inspect its source.',
          ),
          const SizedBox(height: 18),
          button(
            'Send notebook insight',
            () => run(
              () => api.request(
                '/lab-api/insights',
                body: collectInsights(api.token ?? ''),
              ),
            ),
          ),
        ];
      case 8:
        return [
          SelectableText(
            'Current API: ${api.endpoint}',
            style: const TextStyle(fontFamily: 'NotoSansMono', fontSize: 12),
          ),
          const SizedBox(height: 18),
          button(
            'Inspect transport',
            () => run(() => api.request('/lab-api/transport')),
          ),
        ];
      case 9:
        return [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Local premium state'),
            subtitle: const Text(
              'Models changing this value in a patched client.',
            ),
            value: elevated,
            onChanged: (v) => setState(() => elevated = v),
          ),
          const SizedBox(height: 18),
          button(
            'Open premium notebook',
            () => run(
              () => api.request(
                '/lab-api/vault',
                headers: {'X-App-Verified': '$elevated'},
              ),
            ),
          ),
        ];
      case 10:
        return [
          const Text(
            'From your Mac terminal, start the activity as an external caller. Its code reads the app-private session without asking the main app to sign in.',
          ),
          const SizedBox(height: 18),
          SelectableText(
            'adb shell am start -n $appPackage/online.citadel.classroom.DiagnosticsActivity',
            style: const TextStyle(fontFamily: 'NotoSansMono', fontSize: 12),
          ),
          const SizedBox(height: 16),
          Text(
            nativeApp
                ? 'This is a real Android activity; inspect AndroidManifest.xml and DiagnosticsActivity.kt.'
                : 'Run the native Android APK for this exercise.',
          ),
        ];
      case 11:
        return [
          field('Private note'),
          button(
            'Encrypt twice',
            () => run(() async {
              final crypto = NoteCrypto();
              final a = await crypto.encrypt(input.text);
              final b = await crypto.encrypt(input.text);
              return LabResponse(200, {
                'first': a,
                'second': b,
                'identical': a == b,
                'roundTrip': await crypto.decrypt(a),
                if (a == b) 'flag': 'CLASSROOM{NONCES_MUST_BE_UNIQUE}',
              });
            }),
          ),
        ];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        'Exercise ${widget.exercise.id}',
        style: const TextStyle(fontSize: 18),
      ),
    ),
    body: ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xffdceefa),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(widget.exercise.icon, size: 36, color: blue),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          widget.exercise.title,
          style: const TextStyle(
            fontSize: 28,
            height: 1.2,
            fontWeight: FontWeight.w800,
            color: ink,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          widget.exercise.risk,
          style: const TextStyle(color: blue, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 20),
        Text(
          widget.exercise.hint,
          style: const TextStyle(fontSize: 16, height: 1.6),
        ),
        const SizedBox(height: 26),
        ...controls(),
      ],
    ),
  );
}

Future<void> showResult(
  BuildContext context,
  String title,
  Map<String, dynamic> data,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * .68,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: ink,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: SelectableText(
                  const JsonEncoder.withIndent('  ').convert(data),
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'NotoSansMono',
                    fontSize: 12,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
