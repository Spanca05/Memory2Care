import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

String generateSalt() {
  Random random;
  try {
    random = Random.secure();
  } catch (_) {
    random = Random();
  }
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  return base64Url.encode(bytes);
}

String hashPassword({required String password, required String salt}) {
  final payload = '$salt::$password';
  return sha256.convert(utf8.encode(payload)).toString();
}

bool verifyPassword({
  required String password,
  required String salt,
  required String expectedHash,
}) {
  return hashPassword(password: password, salt: salt) == expectedHash;
}
