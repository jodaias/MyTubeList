import 'dart:convert';
import 'package:crypto/crypto.dart';

class PasswordUtils {
  /// 🔐 Gera hash SHA-256 da senha
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 🔍 Verifica se a senha está correta
  static bool verifyPassword(String password, String hashedPassword) {
    final hashedInput = hashPassword(password);
    return hashedInput == hashedPassword;
  }
}
