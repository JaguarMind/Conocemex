import 'package:shared_preferences/shared_preferences.dart';

class SecureStorageService {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveToken(String token) async {
    await _prefs.setString('access_token', token);
  }

  String? getToken() {
    return _prefs.getString('access_token');
  }

  Future<void> saveRefreshToken(String refreshToken) async {
    await _prefs.setString('refresh_token', refreshToken);
  }

  String? getRefreshToken() {
    return _prefs.getString('refresh_token');
  }

  Future<void> saveUser(String userJson) async {
    await _prefs.setString('user', userJson);
  }

  String? getUser() {
    return _prefs.getString('user');
  }

  Future<void> saveBiometricEnabled(bool enabled) async {
    await _prefs.setBool('biometric_enabled', enabled);
  }

  bool? isBiometricEnabled() {
    return _prefs.getBool('biometric_enabled');
  }

  Future<void> clearAll() async {
    await _prefs.clear();
  }

  Future<void> removeToken() async {
    await _prefs.remove('access_token');
  }
}
