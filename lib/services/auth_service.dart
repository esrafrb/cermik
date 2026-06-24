import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'api_service.dart';

class AuthService {
  static String get _baseUrl => AppConfig.apiBaseUrl;

  // ─────────────────────────────────────────────
  // Local Session Persistence
  // ─────────────────────────────────────────────
  static Future<void> saveSession(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setInt('userId', user['id'] ?? 0);
    await prefs.setString('userName', '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim());
    await prefs.setString('userEmail', user['email'] ?? '');
    await prefs.setString('userPhone', user['phone'] ?? '');
    await prefs.setString('userImage', user['profile_image'] ?? '');
    await prefs.setString('userRole', user['role'] ?? 'USER');
    await prefs.setInt('userDistrictId', user['district_id'] ?? 0);
  }

  static Future<Map<String, String?>> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'isLoggedIn': prefs.getBool('isLoggedIn') == true ? 'true' : null,
      'userId': prefs.getInt('userId')?.toString(),
      'userName': prefs.getString('userName'),
      'userEmail': prefs.getString('userEmail'),
      'userPhone': prefs.getString('userPhone'),
      'userImage': prefs.getString('userImage'),
      'userRole': prefs.getString('userRole'),
      'userDistrictId': prefs.getInt('userDistrictId')?.toString(),
    };
  }

  static Future<bool> isAdmin() async {
    final session = await getSession();
    final role = session['userRole'];
    return role == 'SUPER_ADMIN' || role == 'DISTRICT_ADMIN';
  }

  static Future<bool> isSuperAdmin() async {
    final session = await getSession();
    return session['userRole'] == 'SUPER_ADMIN';
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  static Future<Map<String, dynamic>> login({
    required String identity, 
    required String password,
  }) async {
    try {
      final res = await ApiService.login(identity, password);
      if (res['status'] == 'success' && res['user'] != null) {
        if (res['access_token'] != null) {
          await ApiService.setToken(res['access_token']);
        }
        await saveSession(res['user']);
      }
      return res;
    } catch (e) {
      return _error(e.toString());
    }
  }

  // ─────────────────────────────────────────────
  // Register: POST /api/v1/register
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    try {
      final res = await ApiService.register(data);
      if (res['status'] == 'success' && res['user'] != null) {
        if (res['access_token'] != null) {
          await ApiService.setToken(res['access_token']);
        }
        await saveSession(res['user']);
      }
      return res;
    } catch (e) {
      return _error(e.toString());
    }
  }

  // ─────────────────────────────────────────────
  // Reset Password: POST /api/v1/reset-password
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> resetPassword({
    required String phone,
    required String otp,
    required String newPass,
  }) async {
    try {
      return await ApiService.resetPassword(phone, otp, newPass);
    } catch (e) {
      return _error(e.toString());
    }
  }

  // ─────────────────────────────────────────────
  // Quick Login: POST /api/v1/quick-login
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> quickLogin(String phone) async {
    try {
      return await ApiService.quickLogin(phone);
    } catch (e) {
      return _error(e.toString());
    }
  }

  // ─────────────────────────────────────────────
  // Verify OTP: POST /api/v1/verify-otp
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> verifyOtp({
    required String otpCode,
    required int tempUserId,
  }) async {
    try {
      final res = await ApiService.verifyOtp(otpCode, tempUserId);
      if (res['status'] == 'success' && res['user'] != null) {
        if (res['access_token'] != null) {
          await ApiService.setToken(res['access_token']);
        }
        await saveSession(res['user']);
      }
      return res;
    } catch (e) {
      return _error(e.toString());
    }
  }

  // ─────────────────────────────────────────────
  // Get User Summary (for Profile)
  // ─────────────────────────────────────────────
  // ─────────────────────────────────────────────
  // Get Full Profile: GET /api/v1/profile
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      return await ApiService.getProfile();
    } catch (e) {
      return _error(e.toString());
    }
  }

  static Future<Map<String, dynamic>> getUserSummary() async {
    try {
      final session = await getSession();
      final userId = session['userId'];
      if (userId == null) return _error('Oturum bulunamadı.');
      return await ApiService.getUserSummary(userId);
    } catch (e) {
      return _error(e.toString());
    }
  }

  // ─────────────────────────────────────────────
  // Delete Account (Apple App Store Requirement)
  // DELETE /api/v1/delete-account
  // ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final res = await ApiService.deleteAccount();
      if (res['status'] == 'success') {
        await clearSession();
        await ApiService.setToken(null);
      }
      return res;
    } catch (e) {
      return _error(e.toString());
    }
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────
  static Map<String, dynamic> _error(String msg) {
    return {'status': 'error', 'message': msg};
  }
}

