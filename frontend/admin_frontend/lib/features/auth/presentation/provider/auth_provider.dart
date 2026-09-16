import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class AuthProvider with ChangeNotifier {
  final AuthRepository _authRepository = AuthRepository();

  UserModel? _user;
  UserModel? get user => _user;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

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
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');

      if (token != null && token.isNotEmpty) {
        _user = await _authRepository.getProfile();

        if (_user != null && !_hasAdminPermission(_user!)) {
          await _authRepository.logout();
          _user = null;
        }
      }
    } catch (e) {
      await _authRepository.logout();
      _user = null;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Hàm Đăng xuất
  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await _authRepository.logout();
    _user = null;

    _isLoading = false;
    notifyListeners();
  }
}
