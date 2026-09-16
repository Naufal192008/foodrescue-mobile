import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
  static const _keyToken = 'auth_token';
  static const _keyUser = 'auth_user';
  static const _keyRole = 'auth_role';

  static Future<void> saveSession({
    required String token,
    required String role,
    String? userJson,
  }) async {
    await _storage.write(key: _keyToken, value: token);
    await _storage.write(key: _keyRole, value: role);
    if (userJson != null) {
      await _storage.write(key: _keyUser, value: userJson);
    }
  }

  static Future<String?> getToken() => _storage.read(key: _keyToken);

  static Future<String?> getRole() => _storage.read(key: _keyRole);

  static Future<String?> getUserJson() => _storage.read(key: _keyUser);

  static Future<void> clear() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyRole);
    await _storage.delete(key: _keyUser);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}