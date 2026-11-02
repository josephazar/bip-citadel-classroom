import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:citadel_classroom/api.dart';
import 'package:citadel_classroom/crypto_lab.dart';
import 'package:citadel_classroom/demo_config.dart';
import 'package:citadel_classroom/insights.dart';
import 'package:citadel_classroom/main.dart';
import 'package:citadel_classroom/platform.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('native API, persistence, crypto and the mobile screens', (
    tester,
  ) async {
    final api = await LabApi.create();
    final store = SessionStore();
    await store.clear();
    final login = await api.request('/demo/login', body: {});
    expect(login.status, 200);
    api.token = login.data['sessionToken'] as String;
    await store.write(api.token!);
    expect(await SessionStore().read(), api.token);
    expect((await store.inspect()).contains(api.token!), !isFixed);
    expect((await api.request('/lab-api/notes/101')).status, 200);
    expect(
      (await api.request('/lab-api/notes/102')).status,
      isFixed ? 403 : 200,
    );
    expect(
      (await api.request(
        '/lab-api/admin',
        headers: {'X-Lab-Role': 'admin'},
      )).status,
      isFixed ? 403 : 200,
    );
    final search = await api.request(
      '/lab-api/search?q=${Uri.encodeQueryComponent("%' OR 1=1 --")}',
    );
    expect(
      (search.data['rows'] as List).any((r) => r['owner'] == 'bob'),
      !isFixed,
    );
    expect(
      (await api.request(
        '/lab-api/partner',
        headers: {'X-Partner-Key': 'fictional-partner-key-2026'},
      )).status,
      isFixed ? 403 : 200,
    );
    final insights = await api.request(
      '/lab-api/insights',
      body: collectInsights(api.token!),
    );
    expect(insights.data['flag'] != null, !isFixed);
    expect(
      (await api.request(
        '/lab-api/vault',
        headers: {'X-App-Verified': 'true'},
      )).status,
      isFixed ? 403 : 200,
    );
    final transport = await api.request('/lab-api/transport');
    expect(transport.data['encrypted'], isFixed);
    final logs = await api.request('/lab-api/logs');
    expect(jsonEncode(logs.data).contains(api.token!), !isFixed);
    final crypto = NoteCrypto();
    final a = await crypto.encrypt('fictional notebook');
    final b = await crypto.encrypt('fictional notebook');
    expect(a == b, !isFixed);
    expect(await crypto.decrypt(a), 'fictional notebook');
    final tampered = base64Decode(a);
    tampered[13] ^= 1;
    await expectLater(
      crypto.decrypt(base64Encode(tampered)),
      throwsA(isA<SecretBoxAuthenticationError>()),
    );
    final box = SecretBox.fromConcatenation(
      base64Decode(a),
      nonceLength: 12,
      macLength: 16,
    );
    final extracted = AesGcm.with256bits().decrypt(
      box,
      secretKey: SecretKey(utf8.encode('0123456789abcdef0123456789abcdef')),
    );
    if (isFixed) {
      await expectLater(
        extracted,
        throwsA(isA<SecretBoxAuthenticationError>()),
      );
    } else {
      expect(utf8.decode(await extracted), 'fictional notebook');
    }
    await api.request('/demo/logout', body: {});
    expect((await api.request('/lab-api/notes/101')).status, 401);
    await store.clear();
    api.close();
    await tester.pumpWidget(const ClassroomApp());
    for (
      var n = 0;
      n < 40 && find.text('Load demo as Alice').evaluate().isEmpty;
      n++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Load demo as Alice'), findsOneWidget);
    await tester.tap(find.text('Load demo as Alice'));
    for (
      var n = 0;
      n < 100 && find.text('Alice · Personal workspace').evaluate().isEmpty;
      n++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(find.text('Alice · Personal workspace'), findsOneWidget);
    await tester.tap(find.text('Security lab'));
    await tester.pumpAndSettle();
    expect(find.text('Behind the walls'), findsOneWidget);
    await tester.tap(find.text('A session left behind'));
    await tester.pumpAndSettle();
    expect(find.text('Inspect saved session'), findsOneWidget);
    await tester.tap(find.text('Inspect saved session'));
    await tester.pumpAndSettle(const Duration(milliseconds: 100));
    expect(find.text('Result · HTTP 200'), findsOneWidget);
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Flags'));
    await tester.pumpAndSettle();
    expect(find.text('0 / 11'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
