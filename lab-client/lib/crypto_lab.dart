import 'dart:convert';
import 'package:cryptography/cryptography.dart';

class NoteCrypto {
  final algorithm = AesGcm.with256bits();
  // C11 / M10: the key is extractable and every encryption repeats the nonce.
  // C11: A bundled key is extractable; reusing a GCM nonce breaks security.
  Future<SecretKey> key() async =>
      SecretKey(utf8.encode('0123456789abcdef0123456789abcdef'));
  Future<String> encrypt(String text) async {
    final box = await algorithm.encrypt(
      utf8.encode(text),
      secretKey: await key(),
      nonce: List.filled(12, 0),
    );
    return base64Encode(box.concatenation());
  }

  Future<String> decrypt(String encoded) async => utf8.decode(
    await algorithm.decrypt(
      SecretBox.fromConcatenation(
        base64Decode(encoded),
        nonceLength: 12,
        macLength: 16,
      ),
      secretKey: await key(),
    ),
  );
}
