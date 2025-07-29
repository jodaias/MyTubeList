import 'dart:convert';
import 'package:crypto/crypto.dart';

/// 🔐 Utilitários para gerenciamento de senhas
///
/// ⚠️ ATENÇÃO: Este arquivo é usado apenas para armazenamento local (Hive).
/// As senhas NÃO são mais armazenadas no Firestore por questões de segurança.
/// A autenticação é feita exclusivamente via Firebase Auth.
class PasswordUtils {
  /// 🔐 Gera hash SHA-256 da senha (apenas para armazenamento local)
  static String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 🔍 Verifica se a senha está correta (apenas para armazenamento local)
  static bool verifyPassword(String password, String hashedPassword) {
    final hashedInput = hashPassword(password);
    return hashedInput == hashedPassword;
  }
}
