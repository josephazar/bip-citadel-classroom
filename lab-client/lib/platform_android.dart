import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:path_provider/path_provider.dart';

const defaultApi = 'http://10.0.2.2:3260';
const nativeApp = true;

Future<http.Client> buildClient(Uri endpoint) async {
  // C8 / M5: accepting every certificate defeats TLS authentication.
  // C8: Accepting invalid certificates also trusts an impostor server.
  return IOClient(
    HttpClient()..badCertificateCallback = (cert, host, port) => true,
  );
}

class SessionStore {
  Future<File> get _file async =>
      File('${(await getApplicationDocumentsDirectory()).path}/session.json');
  // C1 / M9: token and personal data persisted without encryption.
  // C1: Plaintext JSON exposes a reusable token to anyone who reads the file.
  Future<void> write(String token) async => (await _file).writeAsString(
    jsonEncode({'token': token, 'email': 'fictional.alice@example.test'}),
  );
  Future<String?> read() async {
    final file = await _file;
    return await file.exists()
        ? (jsonDecode(await file.readAsString()) as Map)['token'] as String?
        : null;
  }

  Future<String> inspect() async => (await _file).readAsString();
  Future<void> clear() async {
    final file = await _file;
    if (await file.exists()) await file.delete();
  }
}

void logSession(String token) {
  // C2 / M6: these values reach Android logcat, even in release builds.
  debugPrint('CITADEL_LOGIN email=fictional.alice@example.test token=$token');
}

Widget frameApp(Widget app) => app;
