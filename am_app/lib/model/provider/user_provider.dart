import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UserProvider with ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  bool isLoaded = false;
  bool _isLoginExpired = false;
  String? _username;
  String? _email;
  String? _role;
  String? _accessToken;
  String? _refreshToken;
  String? _profileImageUrl;

  bool get isLoading => isLoaded;
  bool get isLoginExpired => _isLoginExpired;
  String? get username => _username;
  String? get email => _email;
  String? get role => _role;
  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  String? get profileImageUrl => _profileImageUrl;

  Future<void> setState(String? username, String? email, String? role,
      String? accessToken, String? refreshToken, bool isLoginExpired) async {
    _username = username;
    _email = email;
    _role = role;
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    _isLoginExpired = isLoginExpired;
    await _storage.write(key: 'username', value: username);
    await _storage.write(key: 'email', value: email);
    await _storage.write(key: 'role', value: role);
    await _storage.write(key: 'accessToken', value: accessToken);
    await _storage.write(key: 'refreshToken', value: refreshToken);
    notifyListeners();
  }

  Future<void> updateState(
      String? username,
      String? email,
      String? role,
      String? accessToken,
      String? refreshToken,
      String? profileImageUrl) async {
    if (username != null) {
      _username = username;
      await _storage.write(key: 'username', value: username);
    }

    if (email != null) {
      _email = email;
      await _storage.write(key: 'email', value: email);
    }

    if (profileImageUrl != null) {
      _profileImageUrl = profileImageUrl;
      await _storage.write(key: 'profileImageUrl', value: profileImageUrl);
    }

    if (role != null) {
      _role = role;
      await _storage.write(key: 'role', value: role);
    }

    if (accessToken != null) {
      _accessToken = accessToken;
      await _storage.write(key: 'accessToken', value: accessToken);
    }

    if (refreshToken != null) {
      _refreshToken = refreshToken;
      await _storage.write(key: 'refreshToken', value: refreshToken);
    }
    notifyListeners();
  }

  Future<void> updateTokens(String? accessToken, String? refreshToken) async {
    if (accessToken != null) {
      _accessToken = accessToken;
      await _storage.write(key: 'accessToken', value: accessToken);
    }

    if (refreshToken != null) {
      _refreshToken = refreshToken;
      await _storage.write(key: 'refreshToken', value: refreshToken);
    }
  }

  Future<void> updateProfileImage(String? profileImageUrl) async {
    if (profileImageUrl != null) {
      _profileImageUrl = profileImageUrl;
      await _storage.write(key: 'profileImageUrl', value: profileImageUrl);
    }
    notifyListeners();
  }

  Future<void> updateUsername(String? newUsername) async {
    if (newUsername != null) {
      _username = newUsername;
      await _storage.write(key: 'username', value: newUsername);
    }
    notifyListeners();
  }

  void updateLoginExpired(bool isExpired, bool notify) {
    _isLoginExpired = isExpired;
    if (notify) notifyListeners();
  }

  Future<void> deleteState(bool isLoginExpired) async {
    _username = null;
    _email = null;
    _role = null;
    _accessToken = null;
    _refreshToken = null;
    _profileImageUrl = null;
    _isLoginExpired = isLoginExpired;
    await _storage.deleteAll();
    notifyListeners();
  }

  Future<void> initState() async {
    debugPrint("initState");
    _username = await _storage.read(key: 'username');
    _email = await _storage.read(key: 'email');
    _role = await _storage.read(key: 'role');
    _accessToken = await _storage.read(key: 'accessToken');
    _refreshToken = await _storage.read(key: 'refreshToken');
    isLoaded = true;
    notifyListeners();
  }
}
