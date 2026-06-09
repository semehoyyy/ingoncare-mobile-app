import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart' as user_model;

class AuthProvider extends ChangeNotifier {
  user_model.User? _user;
  bool _isLoading = false;
  String? _error;
  bool _isAuthenticated = false;

  user_model.User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> checkAuth() async {
    final token = await ApiService.getToken();
    if (token != null) {
      try {
        final response = await ApiService.getProfile();
        if (response['user'] != null) {
          _user = user_model.User.fromJson(response['user']);
          _isAuthenticated = true;
        } else {
          await ApiService.removeToken();
          _isAuthenticated = false;
        }
      } catch (e) {
        _isAuthenticated = false;
      }
    }
    notifyListeners();
  }

  Future<bool> login(String login, String password) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.login(login, password);
      if (response['token'] != null) {
        await ApiService.setToken(response['token']);
        _user = user_model.User.fromJson(response['user']);
        _isAuthenticated = true;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = response['message'] ?? 'Login gagal';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Koneksi gagal. Periksa jaringan Anda.';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await ApiService.register(data);
      _isLoading = false;
      notifyListeners();
      return response;
    } catch (e) {
      _error = 'Koneksi gagal. Periksa jaringan Anda.';
      _isLoading = false;
      notifyListeners();
      return {'success': false, 'message': _error};
    }
  }

  Future<void> logout() async {
    try {
      await ApiService.logout();
    } catch (_) {}
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
