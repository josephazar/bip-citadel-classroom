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
