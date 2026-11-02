import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:web/web.dart' as web;

final defaultApi = Uri.base.origin;
const nativeApp = false;
Future<http.Client> buildClient(Uri endpoint) async => http.Client();

class SessionStore {
  Future<void> write(String token) async =>
      web.window.localStorage.setItem('citadel_classroom_session', token);
  Future<String?> read() async =>
      web.window.localStorage.getItem('citadel_classroom_session');
  Future<String> inspect() async => await read() ?? 'No saved session.';
  Future<void> clear() async =>
      web.window.localStorage.removeItem('citadel_classroom_session');
}

void logSession(String token) =>
    debugPrint('CITADEL_LOGIN email=fictional.alice@example.test token=$token');
Widget frameApp(Widget app) => Center(
  child: ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 480),
    child: app,
  ),
);
