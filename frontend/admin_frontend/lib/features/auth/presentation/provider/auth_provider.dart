import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();
  Timer? _expiryTimer;
  String? _sessionToken;
  VoidCallback? onSessionExpired;

  UserModel? _user;
  UserModel? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isInitializing = true;
  bool get isInitializing => _isInitializing;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _user != null;

  bool _hasAdminPermission(UserModel user) {
    return user.roles.any(
      (role) =>
          role == 'ADMIN' ||
          role == 'ROLE_ADMIN' ||
          role == 'EMPLOYEE' ||
          role == 'ROLE_EMPLOYEE',
    );
  }

  // Gọi hàm này từ màn hình Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await _authRepository.login(email, password);

      if (_user != null && !_hasAdminPermission(_user!)) {
        _errorMessage = 'Bạn không có quyền truy cập vào hệ thống Quản trị.';
        await _authRepository.logout();
        _user = null;
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _isLoading = false;
      await _scheduleExpiry();
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Gọi hàm này lúc khởi chạy app để check xem đã đăng nhập chưa
  Future<void> checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if ((token != null && token.isNotEmpty) ||
          prefs.getString('refresh_token')?.isNotEmpty == true) {
        _user = await _authRepository.getProfile();

        if (_user != null && !_hasAdminPermission(_user!)) {
          await _authRepository.logout();
          _user = null;
        }
        if (_user != null) await _scheduleExpiry();
      }
    } catch (e) {
      await _authRepository.logout();
      _user = null;
    }

    _isInitializing = false;
    notifyListeners();
  }

  // Hàm Đăng xuất
  Future<void> logout() async {
    _expiryTimer?.cancel();
    _sessionToken = null;
    _isLoading = true;
    notifyListeners();

    await _authRepository.logout();
    _user = null;

    _isLoading = false;
    notifyListeners();
  }

  DateTime? _expiresAt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      ) as Map<String, dynamic>;
      final seconds = payload['exp'];
      if (seconds is! num) return null;
      return DateTime.fromMillisecondsSinceEpoch(seconds.toInt() * 1000);
    } catch (_) {
      return null;
    }
  }

  Future<void> _scheduleExpiry() async {
    _expiryTimer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    _sessionToken = token;
    final expiresAt = token == null ? null : _expiresAt(token);
    if (expiresAt == null) return;
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining <= Duration.zero) {
      await _renewSession();
    } else {
      _expiryTimer = Timer(remaining, _renewSession);
    }
  }

  Future<void> _renewSession() async {
    if (_user == null) return;
    try {
      if (!await ApiClient().refreshSession()) {
        expireSession();
        return;
      }
      if (_user == null) return;
      _user = await _authRepository.getProfile();
      if (!_hasAdminPermission(_user!)) {
        await logout();
        return;
      }
      await _scheduleExpiry();
      notifyListeners();
    } catch (_) {
      if (_user != null) {
        _expiryTimer = Timer(const Duration(seconds: 30), _renewSession);
      }
    }
  }

  void expireSession() {
    if (_user == null) return;
    _expiryTimer?.cancel();
    final expiredToken = _sessionToken;
    _sessionToken = null;
    _user = null;
    _isLoading = false;
    _errorMessage = null;
    ApiClient().clearCsrfToken();
    onSessionExpired?.call();
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) async {
      if (prefs.getString('access_token') == expiredToken) {
        await prefs.remove('refresh_token');
        return prefs.remove('access_token');
      }
      return false;
    });
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    super.dispose();
  }
}
