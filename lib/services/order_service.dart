import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'api_service.dart';

class OrderService {
  static final Dio _dio = Dio();

  static Future<Map<String, String>> _getHeaders() async {
    // Önce statik token'ı dene, yoksa SharedPreferences'tan oku
    String? token = ApiService.token;
    if (token == null || token.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      token = prefs.getString('access_token');
    }
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // Adresleri Getir
  static Future<List<dynamic>> getAddresses() async {
    try {
      final headers = await _getHeaders();
      final res = await _dio.get(
        '${AppConfig.apiBaseUrl}addresses',
        options: Options(headers: headers),
      );
      if (res.data['status'] == 'success') {
        return res.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // Adres Ekle
  static Future<Map<String, dynamic>> addAddress({
    required String title,
    required String fullAddress,
    String? district,
    String? city,
    bool isDefault = false,
  }) async {
    try {
      final headers = await _getHeaders();
      final res = await _dio.post(
        '${AppConfig.apiBaseUrl}addresses',
        data: {
          'title': title,
          'full_address': fullAddress,
          'district': district,
          'city': city,
          'is_default': isDefault ? 1 : 0,
        },
        options: Options(headers: headers),
      );
      return res.data;
    } catch (e) {
      if (e is DioException && e.response != null) {
        return e.response!.data;
      }
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Adres Sil
  static Future<Map<String, dynamic>> deleteAddress(int id) async {
    try {
      final headers = await _getHeaders();
      final res = await _dio.delete(
        '${AppConfig.apiBaseUrl}addresses/$id',
        options: Options(headers: headers),
      );
      return res.data;
    } catch (e) {
      if (e is DioException && e.response != null) return e.response!.data;
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Varsayılan Adres Yap
  static Future<Map<String, dynamic>> setDefaultAddress(int id) async {
    try {
      final headers = await _getHeaders();
      final res = await _dio.post(
        '${AppConfig.apiBaseUrl}addresses/$id/set-default',
        options: Options(headers: headers),
      );
      return res.data;
    } catch (e) {
      if (e is DioException && e.response != null) return e.response!.data;
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Sipariş Oluştur (OTP Tetikler)
  static Future<Map<String, dynamic>> createOrder({
    required int businessId,
    required int addressId,
    required List<Map<String, dynamic>> items,
    required double totalPrice,
    required String paymentMethod,
    String? note,
  }) async {
    try {
      final headers = await _getHeaders();
      final res = await _dio.post(
        '${AppConfig.apiBaseUrl}orders/create',
        data: {
          'business_id': businessId,
          'address_id': addressId,
          'items': items,
          'total_price': totalPrice,
          'payment_method': paymentMethod,
          'note': note,
        },
        options: Options(headers: headers),
      );
      return res.data;
    } catch (e) {
      if (e is DioException && e.response != null) return e.response!.data;
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Sipariş OTP Doğrula
  static Future<Map<String, dynamic>> verifyOrder(int orderId, String otpCode) async {
    try {
      final headers = await _getHeaders();
      final res = await _dio.post(
        '${AppConfig.apiBaseUrl}orders/verify',
        data: {
          'order_id': orderId,
          'otp_code': otpCode,
        },
        options: Options(headers: headers),
      );
      return res.data;
    } catch (e) {
      if (e is DioException && e.response != null) return e.response!.data;
      return {'status': 'error', 'message': e.toString()};
    }
  }

  // Kullanıcının Siparişlerini Getir
  static Future<List<dynamic>> getMyOrders() async {
    try {
      final headers = await _getHeaders();
      final res = await _dio.get(
        '${AppConfig.apiBaseUrl}orders/my', // Doğru route: /orders/my
        options: Options(headers: headers),
      );
      if (res.data['status'] == 'success') {
        return res.data['data'] as List<dynamic>;
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}
