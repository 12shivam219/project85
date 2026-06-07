import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SecurityHelper {
  static const _secureStorage = FlutterSecureStorage();
  static const _encryptionKeyName = 'hive_encryption_key';

  /// Generates or retrieves a secure encryption key for Hive boxes
  static Future<Uint8List> getEncryptionKey() async {
    final containsKey = await _secureStorage.containsKey(key: _encryptionKeyName);
    if (!containsKey) {
      final key = Hive.generateSecureKey();
      await _secureStorage.write(key: _encryptionKeyName, value: base64UrlEncode(key));
    }

    final keyString = await _secureStorage.read(key: _encryptionKeyName);
    return base64Url.decode(keyString!);
  }

  /// Securely stores a sensitive string (like an API key)
  static Future<void> saveSecureString(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  /// Retrieves a securely stored string
  static Future<String?> getSecureString(String key) async {
    return await _secureStorage.read(key: key);
  }

  /// Deletes a securely stored string
  static Future<void> deleteSecureString(String key) async {
    await _secureStorage.delete(key: key);
  }
}
