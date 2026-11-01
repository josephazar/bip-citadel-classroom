import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

void main() => runApp(const ClassroomApp());

class ClassroomApp extends StatefulWidget {
  const ClassroomApp({super.key});
  @override
  State<ClassroomApp> createState() => _ClassroomState();
}

class _ClassroomState extends State<ClassroomApp> {
  final note = TextEditingController(text: '101'),
      search = TextEditingController();
  final path = TextEditingController(text: '/lab-api/admin'),
      role = TextEditingController(text: 'user'),
      flag = TextEditingController();
  final captured = <String>{};
  String result = 'Load the demo. All users and notes are fictional.',
      mode = 'Guided classroom CTF';
  Uri uri(String p) => Uri.base.resolve(p);
  Future<void> show(String p, {Map<String, String>? headers}) async {
    try {
      if (!p.startsWith('/lab-api/')) throw Exception('Use a /lab-api/ path.');
      final r = await http
          .get(uri(p), headers: headers)
          .timeout(const Duration(seconds: 10));
      String text;
      try {
        text = const JsonEncoder.withIndent('  ').convert(jsonDecode(r.body));
      } catch (_) {
        text = r.body;
      }
      if (mounted) {
        setState(() => result = 'HTTP ${r.statusCode}\nGET $p\n\n$text');
      }
    } catch (e) {
      if (mounted) setState(() => result = e.toString());
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
          mode = data['mode'] as String;
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

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Citadel Classroom',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      fontFamily: 'NotoSans',
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff099bdd)),
    ),
    home: Scaffold(
      appBar: AppBar(title: const Text('THE CITADEL / CLASSROOM')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1100),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                mode,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Watch the instructor: observe the request, inspect the code, then compare the repaired behavior. Five classroom flags; no grade or real student data.',
              ),
              const SizedBox(height: 14),
              const _HowTo(),
              const SizedBox(height: 18),
              Wrap(
                spacing: 12,
                children: [
                  FilledButton(
                    onPressed: login,
                    child: const Text('Load demo as Alice'),
                  ),
                  OutlinedButton(
                    onPressed: () => show('/lab-api/logs'),
                    child: const Text('Debug logs'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: note,
                      decoration: const InputDecoration(labelText: 'Note ID'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: () => show(
                      '/lab-api/notes/${Uri.encodeComponent(note.text)}',
                    ),
                    child: const Text('Read note'),
                  ),
                ],
              ),
              TextField(
                controller: search,
                decoration: const InputDecoration(
                  labelText: 'Search note titles',
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  onPressed: () => show(
                    '/lab-api/search?q=${Uri.encodeComponent(search.text)}',
                  ),
                  child: const Text('Search'),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Request console',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: path,
                decoration: const InputDecoration(labelText: 'GET path'),
              ),
              TextField(
                controller: role,
                decoration: const InputDecoration(
                  labelText: 'X-Lab-Role request header',
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  onPressed: () =>
                      show(path.text, headers: {'X-Lab-Role': role.text}),
                  child: const Text('Send request'),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xff12283d),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SelectableText(
                  result,
                  style: const TextStyle(
                    fontFamily: 'NotoSansMono',
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Classroom flags: ${captured.length} / 5',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextField(
                controller: flag,
                decoration: const InputDecoration(labelText: 'CLASSROOM{...}'),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton(
                  onPressed: capture,
                  child: const Text('Capture classroom flag'),
                ),
              ),
              const SizedBox(height: 16),
              ...captured.map((f) => SelectableText(f)),
            ],
          ),
        ),
      ),
    ),
  );
}

/// A short, always-visible guide for people who open the page without the instructor's walkthrough.
class _HowTo extends StatelessWidget {
  const _HowTo();
  @override
  Widget build(BuildContext context) {
    const bold = TextStyle(fontWeight: FontWeight.w700);
    Widget line(String n, List<InlineSpan> parts) => Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 22, child: Text('$n.', style: bold)),
          Expanded(child: Text.rich(TextSpan(children: parts))),
        ],
      ),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      decoration: const BoxDecoration(
        color: Color(0xffeaf6fc),
        border: Border(left: BorderSide(color: Color(0xff099bdd), width: 5)),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(fontSize: 14, height: 1.35),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How to use this page', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            line('1', const [
              TextSpan(text: 'Click '),
              TextSpan(text: 'Load demo as Alice', style: bold),
              TextSpan(text: ' first. Nothing else works before that.'),
            ]),
            line('2', const [
              TextSpan(text: 'Try the tools below one at a time and read the dark box: '),
              TextSpan(text: 'Debug logs', style: bold),
              TextSpan(text: ', '),
              TextSpan(text: 'Note ID', style: bold),
              TextSpan(text: ', '),
              TextSpan(text: 'Search note titles', style: bold),
              TextSpan(text: ', '),
              TextSpan(text: 'Request console', style: bold),
              TextSpan(text: ', and your browser DevTools (Application, Local storage).'),
            ]),
            line('3', const [
              TextSpan(text: 'Each weakness hides a flag shaped like '),
              TextSpan(text: 'CLASSROOM{...}', style: bold),
              TextSpan(text: '. Paste it in the box at the bottom and click '),
              TextSpan(text: 'Capture classroom flag', style: bold),
              TextSpan(text: '. Five flags in all.'),
            ]),
            line('4', const [
              TextSpan(text: 'If a click answers '),
              TextSpan(text: 'Select Load demo first', style: bold),
              TextSpan(text: ', your session ended or the instructor reset the class: click '),
              TextSpan(text: 'Load demo as Alice', style: bold),
              TextSpan(text: ' again.'),
            ]),
            const SizedBox(height: 8),
            const Text('Hints, no answers', style: bold),
            const Text('Debug logs: read every line.  Note ID: you own note 101; what about the next number?  Search: what does an apostrophe do?  Request console: who decides the role?  DevTools: what is stored for this site?'),
          ],
        ),
      ),
    );
  }
}
