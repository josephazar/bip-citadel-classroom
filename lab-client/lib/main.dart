import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

void main() => runApp(const ClassroomApp());

const _blue = Color(0xff099bdd);
const _panel = Color(0xff12283d);
const _mono = 'NotoSansMono';

class ClassroomApp extends StatelessWidget {
  const ClassroomApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Citadel Notes',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      fontFamily: 'NotoSans',
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: _blue),
      scaffoldBackgroundColor: const Color(0xfff3f7fa),
    ),
    home: const _Shell(),
  );
}

/// On a big screen the app is drawn inside a phone, scaled to fit; on a real phone it fills the screen.
class _Shell extends StatelessWidget {
  const _Shell();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      if (c.maxWidth < 640 || c.maxHeight < 520) {
        return const NotesApp(framed: false);
      }
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xff051d2b), Color(0xff0b3f5c)],
          ),
        ),
        child: SizedBox(
          width: c.maxWidth,
          height: c.maxHeight,
          child: FittedBox(
            fit: BoxFit.contain,
            child: const Padding(
              padding: EdgeInsets.all(18),
              child: SizedBox(
                width: 400,
                height: 840,
                child: _PhoneFrame(child: NotesApp(framed: true)),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _PhoneFrame extends StatelessWidget {
  const _PhoneFrame({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(11),
    decoration: BoxDecoration(
      color: const Color(0xff10171e),
      borderRadius: BorderRadius.circular(56),
      border: Border.all(color: const Color(0xff4a5b6a), width: 2.5),
      boxShadow: const [
        BoxShadow(
          color: Color(0x99000000),
          blurRadius: 44,
          offset: Offset(0, 20),
        ),
      ],
    ),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(46),
      child: Stack(
        children: [
          child,
          Positioned(
            top: 9,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 104,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xff05090d),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _StatusBar extends StatelessWidget {
  const _StatusBar();
  @override
  Widget build(BuildContext context) => Material(
    color: Colors.white,
    child: SizedBox(
      height: 46,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(30, 10, 26, 0),
        child: Row(
          children: const [
            Text(
              '9:41',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
            Spacer(),
            Icon(Icons.signal_cellular_alt, size: 17),
            SizedBox(width: 5),
            Icon(Icons.wifi, size: 17),
            SizedBox(width: 5),
            Icon(Icons.battery_full, size: 19),
          ],
        ),
      ),
    ),
  );
}

class NotesApp extends StatefulWidget {
  const NotesApp({super.key, required this.framed});
  final bool framed;
  @override
  State<NotesApp> createState() => _NotesState();
}

class _NotesState extends State<NotesApp> {
  final note = TextEditingController(text: '101'),
      search = TextEditingController();
  final path = TextEditingController(text: '/lab-api/admin'),
      role = TextEditingController(text: 'user'),
      flag = TextEditingController();
  final captured = <String>{};
  String result = 'Load the demo. All users and notes are fictional.',
      mode = 'Guided classroom CTF';
  String? lastPath;
  int? lastStatus;
  dynamic lastJson;
  bool signedIn = false, panelOpen = true, help = false;
  int tab = 0;

  Uri uri(String p) => Uri.base.resolve(p);

  Future<void> show(String p, {Map<String, String>? headers}) async {
    try {
      if (!p.startsWith('/lab-api/')) throw Exception('Use a /lab-api/ path.');
      final r = await http
          .get(uri(p), headers: headers)
          .timeout(const Duration(seconds: 10));
      String text;
      dynamic parsed;
      try {
        parsed = jsonDecode(r.body);
        text = const JsonEncoder.withIndent('  ').convert(parsed);
      } catch (_) {
        text = r.body;
      }
      if (mounted) {
        setState(() {
          lastPath = p;
          lastStatus = r.statusCode;
          lastJson = parsed;
          panelOpen = true;
          result = 'HTTP ${r.statusCode}\nGET $p\n\n$text';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          lastPath = p;
          lastStatus = null;
          lastJson = null;
          result = e.toString();
        });
      }
    }
  }

  Future<void> login() async {
    try {
      final r = await http
          .post(uri('/demo/login'))
          .timeout(const Duration(seconds: 10));
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      web.window.localStorage.removeItem('citadel_classroom_session');
      // C1: the vulnerable server returns a credential for persistent browser storage.
      if (data['sessionToken'] != null) {
        web.window.localStorage.setItem(
          'citadel_classroom_session',
          data['sessionToken'] as String,
        );
      }
      if (mounted) {
        setState(() {
          signedIn = true;
          mode = data['mode'] as String;
          lastPath = null;
          lastStatus = null;
          lastJson = null;
          result =
              'Signed in as fictional Alice.\nRead note 101, inspect logs, or try the request console.\nThis classroom CTF is separate from graded homework.';
        });
      }
    } catch (e) {
      if (mounted) setState(() => result = e.toString());
    }
  }

  Future<void> capture() async {
    try {
      final r = await http.post(
        uri('/demo/capture'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'flag': flag.text.trim()}),
      );
      final data = jsonDecode(r.body) as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          lastPath = null;
          lastStatus = null;
          if (data['captured'] == true) {
            captured.add(flag.text.trim());
            result = 'Classroom flag captured. ${captured.length} / 5';
            flag.clear();
          } else {
            result =
                'Not a classroom flag. Homework uses a different application and flag format.';
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => result = e.toString());
    }
  }

  @override
  void dispose() {
    for (final c in [note, search, path, role, flag]) {
      c.dispose();
    }
    super.dispose();
  }

  // ---------------------------------------------------------------- screens

  Widget _title(String t, {String? sub}) => Padding(
    padding: const EdgeInsets.only(top: 6, bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        if (sub != null)
          Text(sub, style: const TextStyle(fontSize: 13, color: Colors.black54)),
      ],
    ),
  );

  Widget _welcome() => Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xffe3f3fb),
            ),
            child: const Icon(Icons.shield_outlined, size: 40, color: _blue),
          ),
          const SizedBox(height: 14),
          const Text(
            'Citadel Notes',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          const Text(
            'A fictional notes app for the classroom CTF. All users and notes are fictional.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: login,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Load demo as Alice'),
            ),
          ),
          const SizedBox(height: 16),
          const _Steps(),
        ],
      ),
    ),
  );

  Widget _noteCard() {
    final j = lastJson;
    if (lastPath == null || !lastPath!.startsWith('/lab-api/notes/')) {
      return const SizedBox.shrink();
    }
    if (j is Map && j['title'] != null) {
      return Card(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.sticky_note_2, color: _blue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${j['title']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text('Note ${j['id']}'),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SelectableText('${j['body']}', style: const TextStyle(fontSize: 15)),
              const SizedBox(height: 8),
              Text(
                'Owner: ${j['owner']}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }
    final msg = j is Map && j['error'] != null ? '${j['error']}' : 'No note to show.';
    return Card(
      elevation: 0,
      color: const Color(0xfffdecec),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.error_outline, color: Color(0xffc62828)),
        title: Text(msg),
        subtitle: Text('HTTP ${lastStatus ?? '?'}'),
      ),
    );
  }

  Widget _notesPage() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      if (!signedIn)
        _welcome()
      else ...[
        _title('Hi, Alice', sub: 'Your notes'),
        Wrap(
          spacing: 8,
          children: [
            Chip(
              avatar: const Icon(Icons.cloud_done_outlined, size: 18),
              label: Text(mode),
              visualDensity: VisualDensity.compact,
            ),
            ActionChip(
              avatar: const Icon(Icons.refresh, size: 18),
              label: const Text('Load demo as Alice'),
              visualDensity: VisualDensity.compact,
              onPressed: login,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xffe3f3fb),
              child: Icon(Icons.sticky_note_2_outlined, color: _blue),
            ),
            title: const Text('My shopping'),
            subtitle: const Text('Note 101'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              note.text = '101';
              show('/lab-api/notes/101');
            },
          ),
        ),
        _title('Open a note by ID', sub: 'Type any number and read it'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: note,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Note ID',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: () =>
                  show('/lab-api/notes/${Uri.encodeComponent(note.text)}'),
              child: const Text('Read note'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _noteCard(),
      ],
    ],
  );

  Widget _searchPage() {
    final j = lastJson;
    final rows = lastPath != null &&
            lastPath!.startsWith('/lab-api/search') &&
            j is Map &&
            j['rows'] is List
        ? j['rows'] as List
        : null;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _title('Search', sub: 'Find a note by its title'),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: search,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => show(
                  '/lab-api/search?q=${Uri.encodeComponent(search.text)}',
                ),
                decoration: InputDecoration(
                  labelText: 'Search note titles',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: () => show(
                '/lab-api/search?q=${Uri.encodeComponent(search.text)}',
              ),
              child: const Text('Search'),
            ),
          ],
        ),
        const SizedBox(height: 14),
        if (rows == null)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Type a title and press Search. Results appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
          )
        else if (rows.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No notes found.', textAlign: TextAlign.center),
          )
        else
          ...rows.map(
            (row) => Card(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                leading: const Icon(Icons.description_outlined, color: _blue),
                title: Text('${row is Map ? row['title'] : row}'),
                subtitle: Text('${row is Map ? row['body'] : ''}'),
                trailing: Text(
                  '${row is Map ? row['owner'] : ''}',
                  style: const TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _toolsPage() {
    final j = lastJson;
    final lines = lastPath == '/lab-api/logs' && j is Map
        ? (j['logs'] ?? j['events']) as List?
        : null;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _title('Tools', sub: 'Diagnostics and the request console'),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            leading: const CircleAvatar(
              backgroundColor: Color(0xffe3f3fb),
              child: Icon(Icons.bug_report_outlined, color: _blue),
            ),
            title: const Text('Debug logs'),
            subtitle: const Text('What the server wrote down'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => show('/lab-api/logs'),
          ),
        ),
        if (lines != null)
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: lines
                    .map(
                      (l) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: SelectableText(
                          l is String ? l : jsonEncode(l),
                          style: const TextStyle(fontFamily: _mono, fontSize: 11),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        const SizedBox(height: 14),
        const Text(
          'Request console',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: path,
          decoration: const InputDecoration(
            labelText: 'GET path',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: role,
          decoration: const InputDecoration(
            labelText: 'X-Lab-Role request header',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 10),
        Align(
          alignment: Alignment.centerLeft,
          child: FilledButton.icon(
            onPressed: () => show(path.text, headers: {'X-Lab-Role': role.text}),
            icon: const Icon(Icons.send, size: 18),
            label: const Text('Send request'),
          ),
        ),
      ],
    );
  }

  Widget _flagsPage() => ListView(
    padding: const EdgeInsets.all(16),
    children: [
      _title('Flags', sub: 'Five weaknesses, five flags'),
      Center(
        child: SizedBox(
          width: 130,
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: CircularProgressIndicator(
                  value: captured.length / 5,
                  strokeWidth: 10,
                  backgroundColor: const Color(0xffdbe7ee),
                ),
              ),
              Text(
                '${captured.length} / 5',
                style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 10),
      Center(
        child: Text(
          'Classroom flags: ${captured.length} / 5',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      const SizedBox(height: 14),
      TextField(
        controller: flag,
        decoration: const InputDecoration(
          labelText: 'CLASSROOM{...}',
          border: OutlineInputBorder(),
          isDense: true,
        ),
      ),
      const SizedBox(height: 10),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: capture,
          child: const Text('Capture classroom flag'),
        ),
      ),
      const SizedBox(height: 10),
      ...captured.map(
        (f) => Card(
          elevation: 0,
          color: const Color(0xffe6f6ec),
          child: ListTile(
            dense: true,
            leading: const Icon(Icons.flag, color: Color(0xff1a9c4a)),
            title: SelectableText(f, style: const TextStyle(fontFamily: _mono, fontSize: 11)),
          ),
        ),
      ),
    ],
  );

  Widget _responsePanel() {
    final s = lastStatus;
    final ok = s != null && s < 300;
    return Material(
      color: _panel,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => setState(() => panelOpen = !panelOpen),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: s == null
                          ? const Color(0xff4a5b6a)
                          : ok
                          ? const Color(0xff1a9c4a)
                          : const Color(0xffc62828),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      s == null ? 'RESPONSE' : 'HTTP $s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      lastPath == null ? 'what the server sent back' : 'GET $lastPath',
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: _mono,
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                  Icon(
                    panelOpen ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),
          ),
          if (panelOpen)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                child: SizedBox(
                  width: double.infinity,
                  child: SelectableText(
                    result,
                    style: const TextStyle(
                      fontFamily: _mono,
                      color: Colors.white,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [_notesPage(), _searchPage(), _toolsPage(), _flagsPage()];
    final scaffold = Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: Row(
          children: [
            const Icon(Icons.shield, color: _blue),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Citadel Notes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                ),
                Text(
                  'Classroom lab',
                  style: TextStyle(fontSize: 11, color: Colors.black54),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'How to use this app',
            icon: const Icon(Icons.help_outline),
            onPressed: () => setState(() => help = true),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(child: pages[tab]),
              _responsePanel(),
            ],
          ),
          if (help) _helpOverlay(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 68,
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.sticky_note_2_outlined),
            selectedIcon: Icon(Icons.sticky_note_2),
            label: 'Notes',
          ),
          NavigationDestination(icon: Icon(Icons.search), label: 'Search'),
          NavigationDestination(
            icon: Icon(Icons.build_outlined),
            selectedIcon: Icon(Icons.build),
            label: 'Tools',
          ),
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Flags',
          ),
        ],
      ),
    );
    if (!widget.framed) return scaffold;
    return Column(children: [const _StatusBar(), Expanded(child: scaffold)]);
  }

  Widget _helpOverlay() => Positioned.fill(
    child: Container(
      color: const Color(0xcc0b2233),
      padding: const EdgeInsets.all(18),
      child: Center(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'How to use this app',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 10),
                  const _Steps(),
                  const SizedBox(height: 12),
                  const Text(
                    'Hints, no answers',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const Text(
                    'Debug logs: read every line.  Note ID: you own note 101; what about the next number?  Search: what does an apostrophe do?  Request console: who decides the role?  DevTools: what is stored for this site?',
                    style: TextStyle(fontSize: 13.5, height: 1.35),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => setState(() => help = false),
                      child: const Text('Got it'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The short guide for people who open the page without the instructor's walkthrough.
class _Steps extends StatelessWidget {
  const _Steps();
  @override
  Widget build(BuildContext context) {
    const bold = TextStyle(fontWeight: FontWeight.w700);
    Widget line(String n, List<InlineSpan> parts) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: _blue,
            child: Text(
              n,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text.rich(TextSpan(children: parts))),
        ],
      ),
    );
    return DefaultTextStyle.merge(
      style: const TextStyle(fontSize: 13.5, height: 1.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          line('1', const [
            TextSpan(text: 'Tap '),
            TextSpan(text: 'Load demo as Alice', style: bold),
            TextSpan(text: ' first. Nothing else works before that.'),
          ]),
          line('2', const [
            TextSpan(text: 'Try the tabs one at a time and read the dark box at the bottom: '),
            TextSpan(text: 'Notes', style: bold),
            TextSpan(text: ' (Note ID), '),
            TextSpan(text: 'Search', style: bold),
            TextSpan(text: ', '),
            TextSpan(text: 'Tools', style: bold),
            TextSpan(text: ' (Debug logs, Request console), and your browser DevTools (Application, Local storage).'),
          ]),
          line('3', const [
            TextSpan(text: 'Each weakness hides a flag shaped like '),
            TextSpan(text: 'CLASSROOM{...}', style: bold),
            TextSpan(text: '. Paste it on the '),
            TextSpan(text: 'Flags', style: bold),
            TextSpan(text: ' tab and tap '),
            TextSpan(text: 'Capture classroom flag', style: bold),
            TextSpan(text: '. Five in all.'),
          ]),
          line('4', const [
            TextSpan(text: 'If a tap answers '),
            TextSpan(text: 'Select Load demo first', style: bold),
            TextSpan(text: ', your session ended or the instructor reset the class: tap '),
            TextSpan(text: 'Load demo as Alice', style: bold),
            TextSpan(text: ' again.'),
          ]),
        ],
      ),
    );
  }
}
