import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:citadel_classroom/crypto_lab.dart';
import 'package:citadel_classroom/demo_config.dart';
import 'package:citadel_classroom/insights.dart';

void main() {
  test('SDK payload contains only the expected fields for this branch', () {
    final event = collectInsights('fixture-token');
    expect(event.containsKey('token'), !isFixed);
    expect(event.containsKey('email'), !isFixed);
    expect(event['event'], 'notebook_opened');
  });
  // Native secure storage requires an Android device; crypto is checked in native_test.dart.
  test('the classroom catalog has eleven exercises', () {
    expect(totalFlags, 11);
  });
  if (!isFixed) {
    test(
      'repeated GCM nonce and extracted key reproduce the vulnerable export',
      () async {
        final crypto = NoteCrypto();
        final a = await crypto.encrypt('fictional notebook');
        expect(await crypto.encrypt('fictional notebook'), a);
        final box = SecretBox.fromConcatenation(
          base64Decode(a),
          nonceLength: 12,
          macLength: 16,
        );
        final plain = await AesGcm.with256bits().decrypt(
          box,
          secretKey: SecretKey(utf8.encode('0123456789abcdef0123456789abcdef')),
        );
        expect(utf8.decode(plain), 'fictional notebook');
      },
    );
  }
}
