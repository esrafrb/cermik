import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import 'lang_service.dart';

class ApiService {
  static String get baseUrl => AppConfig.apiBaseUrl;
  static String get _lang => langService.lang;
  static String? _token;
  static String? _sessionCookie;

  static bool get isAuthenticated => _token != null;
  static String? get token => _token;

  static Future<void> setToken(String? token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      await prefs.setString('access_token', token);
    } else {
      await prefs.remove('access_token');
    }
  }

  static Future<void> loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('access_token');
    } catch (e) {
      _token = null;
    }
  }

  static Map<String, String> _getHeaders() {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (_token != null) headers['Authorization'] = 'Bearer $_token';
    if (_sessionCookie != null) headers['Cookie'] = _sessionCookie!;
    return headers;
  }

  // 1. WEB PARITY: İlçe Detayları ve Kategoriler
  static Future<Map<String, dynamic>?> getDistrictDetails(dynamic id) async {
    try {
      final response = await http.get(Uri.parse('${baseUrl}districts/$id?lang=$_lang'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> res = json.decode(utf8.decode(response.bodyBytes));
        if (res['status'] == 'success' && res['data'] != null) return res['data'];
        return res;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // 2. Tüm İlçeleri Getir
  static Future<List<dynamic>> getDistricts() async {
    try {
      final response = await http.get(Uri.parse('${baseUrl}districts?lang=$_lang'))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      throw Exception('Bağlantı Hatası: Sunucuya ulaşılamadı. IP: $baseUrl');
    }
  }

  // 3. Mekanlar & Kategori Arşivi
  static Future<List<dynamic>> getPlaces({int? districtId, String? category}) async {
    final queryParams = <String, String>{};
    if (districtId != null) queryParams['district_id'] = districtId.toString();
    if (category != null) queryParams['category'] = mapCategorySlug(category);
    queryParams['lang'] = _lang;
    final response = await http.get(
      Uri.parse('${baseUrl}places').replace(queryParameters: queryParams),
    );
    if (response.statusCode == 200) {
      final data = json.decode(utf8.decode(response.bodyBytes));
      return data['data'] ?? [];
    }
    return [];
  }

  // 4. Diğer Modüller (Duyuru, Etkinlik, Hizmet)
  static Future<List<dynamic>> getEvents({int? districtId, String? globalStatus}) async {
    final queryParams = <String, String>{};
    if (districtId != null) queryParams['district_id'] = districtId.toString();
    if (globalStatus != null) queryParams['global_status'] = globalStatus;
    queryParams['lang'] = _lang;

    try {
      final uri = Uri.parse('${baseUrl}events').replace(queryParameters: queryParams);
      final res = await http.get(uri).timeout(const Duration(seconds: 30));
      if (res.statusCode == 200) return json.decode(utf8.decode(res.bodyBytes))['data'] ?? [];
      return [];
    } catch (e) {
      throw Exception('Bağlantı Hatası: Sunucuya ulaşılamadı. IP: $baseUrl');
    }
  }

  static Future<List<dynamic>> getAnnouncements({int? districtId}) async {
    final queryParams = <String, String>{};
    if (districtId != null) queryParams['district_id'] = districtId.toString();
    queryParams['lang'] = _lang;

    final uri = Uri.parse('${baseUrl}announcements').replace(queryParameters: queryParams);
    final res = await http.get(uri);
    if (res.statusCode == 200) return json.decode(utf8.decode(res.bodyBytes))['data'] ?? [];
    return [];
  }

  static Future<List<dynamic>> getServices({int? districtId, int? status}) async {
    final queryParams = <String, String>{};
    if (districtId != null) queryParams['district_id'] = districtId.toString();
    if (status != null) queryParams['status'] = status.toString();
    queryParams['lang'] = _lang;

    final uri = Uri.parse('${baseUrl}services').replace(queryParameters: queryParams);
    final res = await http.get(uri);
    if (res.statusCode == 200) return json.decode(utf8.decode(res.bodyBytes))['data'] ?? [];
    return [];
  }

  static Future<Map<String, dynamic>> getMuhtarlar({required int districtId}) async {
    try {
      final uri = Uri.parse('${AppConfig.webBaseUrl}/api/muhtarlar.php')
          .replace(queryParameters: {'district_id': districtId.toString()});
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        return json.decode(utf8.decode(res.bodyBytes));
      }
      return {'status': 'error', 'data': {'merkez': [], 'koy': []}};
    } catch (e) {
      return {'status': 'error', 'data': {'merkez': [], 'koy': []}};
    }
  }

  static Future<Map<String, dynamic>?> getWeather({double? lat, double? lng}) async {
    String url = '${baseUrl}weather?lang=$_lang';
    if (lat != null && lng != null) {
      url += '&lat=$lat&lng=$lng';
    }
    final res = await http.get(Uri.parse(url));
    if (res.statusCode == 200) {
       final data = json.decode(utf8.decode(res.bodyBytes));
       return data['data'];
    }
    return null;
  }

  // Detay Metodları
  static Future<Map<String, dynamic>?> getPlaceDetails(int id) async {
    final res = await http.get(Uri.parse('${baseUrl}places/$id'));
    if (res.statusCode == 200) {
      final data = json.decode(utf8.decode(res.bodyBytes));
      return data['status'] == 'success' ? data['data'] : null;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getEventDetails(dynamic id) async {
    final res = await http.get(Uri.parse('${baseUrl}events/$id?lang=$_lang'));
    if (res.statusCode == 200) {
      final data = json.decode(utf8.decode(res.bodyBytes));
      return data['status'] == 'success' ? data['data'] : null;
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getAnnouncementDetails(dynamic id) async {
    final res = await http.get(Uri.parse('${baseUrl}announcements/$id?lang=$_lang'));
    if (res.statusCode == 200) {
      final data = json.decode(utf8.decode(res.bodyBytes));
      return data['status'] == 'success' ? data['data'] : null;
    }
    return null;
  }

  // Kullanıcı ve Auth İşlemleri
  static Future<Map<String, dynamic>> login(String identity, String password) async {
    final res = await http.post(Uri.parse('${baseUrl}login'), body: jsonEncode({'email': identity, 'password': password}), headers: _getHeaders());
    return json.decode(utf8.decode(res.bodyBytes));
  }

  static Future<Map<String, dynamic>> quickLogin(String phone) async {
    final res = await http.post(Uri.parse('${baseUrl}quick-login'), body: jsonEncode({'phone': phone}), headers: _getHeaders());
    return json.decode(utf8.decode(res.bodyBytes));
  }

  static Future<Map<String, dynamic>> verifyOtp(String code, int tempUserId) async {
    final res = await http.post(
      Uri.parse('${baseUrl}verify-otp'), 
      body: jsonEncode({'otp_code': code, 'temp_user_id': tempUserId}), 
      headers: _getHeaders()
    );
    return json.decode(utf8.decode(res.bodyBytes));
  }

  static Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse('${baseUrl}register'), 
      body: jsonEncode(data), 
      headers: _getHeaders()
    );
    return json.decode(utf8.decode(res.bodyBytes));
  }

  static Future<Map<String, dynamic>> resetPassword(String phone, String otp, String newPass) async {
    final res = await http.post(
      Uri.parse('${baseUrl}reset-password'), 
      body: jsonEncode({'phone': phone, 'otp': otp, 'otp_code': otp, 'password': newPass}), 
      headers: _getHeaders()
    );
    return json.decode(utf8.decode(res.bodyBytes));
  }

  static Future<Map<String, dynamic>> googleLogin(String credential) async {
    final res = await http.post(Uri.parse('${baseUrl}user_auth.php?action=google_login'), body: {'credential': credential});
    return json.decode(utf8.decode(res.bodyBytes));
  }


  /// 6. Profil Verilerini Getir (Stats + Lists)
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final res = await http.get(Uri.parse('${baseUrl}profile'), headers: _getHeaders());
      if (res.statusCode == 200) {
        return json.decode(utf8.decode(res.bodyBytes));
      }
      return {'status': 'error', 'message': 'Profil verileri alınamadı. (Hata: ${res.statusCode})'};
    } catch (e) {
      return {'status': 'error', 'message': 'Bağlantı hatası: $e'};
    }
  }

  static Future<Map<String, dynamic>> getUserSummary(String userId) async {
    final res = await http.get(Uri.parse('${baseUrl}user-summary?user_id=$userId'));
    return json.decode(utf8.decode(res.bodyBytes));
  }

  /// Hesap Silme (Apple App Store Zorunluluğu)
  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final res = await http.delete(
        Uri.parse('${baseUrl}delete-account'),
        headers: _getHeaders(),
      );
      return json.decode(utf8.decode(res.bodyBytes));
    } catch (e) {
      return {'status': 'error', 'message': 'Bağlantı hatası: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateProfileImage({required String imagePath, String? sessionCookie}) async {
    var req = http.MultipartRequest('POST', Uri.parse('${baseUrl}user_auth.php?action=update_image'));
    req.files.add(await http.MultipartFile.fromPath('profile_image', imagePath));
    var res = await req.send();
    return json.decode(await res.stream.bytesToString());
  }

  static Future<Map<String, dynamic>> updateFcmToken(String fcmToken) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId'); // null ise anonim kullanıcı

      final res = await http.post(
        Uri.parse('${AppConfig.webBaseUrl}/api/update_fcm.php'),
        headers: _getHeaders(),
        body: jsonEncode({
          'fcm_token': fcmToken,
          'user_id': userId ?? 0, // 0 = anonim (giriş yapmamış)
        }),
      );
      if (res.statusCode == 200) {
        return json.decode(utf8.decode(res.bodyBytes));
      }
      return {'status': 'error', 'message': 'HTTP ${res.statusCode}'};
    } catch (e) {
      return {'status': 'error', 'message': e.toString()};
    }
  }


  static Future<Map<String, dynamic>> saveCekGonder({required Map<String, String> fields, required Map<String, String> imagePaths}) async {
    var req = http.MultipartRequest('POST', Uri.parse('${baseUrl}cek-gonder'));
    req.fields.addAll(fields);
    for (var e in imagePaths.entries) {
      req.files.add(await http.MultipartFile.fromPath(e.key, e.value));
    }
    var res = await req.send();
    return json.decode(await res.stream.bytesToString());
  }

  static Future<Map<String, dynamic>> checkIn({
    required int targetId,
    required String targetType,
    required int districtId,
    required double lat,
    required double lng,
  }) async {
    final res = await http.post(
      Uri.parse('${baseUrl}check-in'),
      headers: _getHeaders(),
      body: jsonEncode({
        'target_id': targetId.toString(),
        'target_type': targetType,
        'district_id': districtId.toString(),
        'lat': lat.toString(),
        'lng': lng.toString(),
      }),
    );
    return json.decode(utf8.decode(res.bodyBytes));
  }

  static Future<void> trackAnalytics({
    required int targetId,
    required String action,
  }) async {
    try {
      await http.post(
        Uri.parse('${baseUrl}track-business'),
        headers: _getHeaders(),
        body: jsonEncode({
          'business_id': targetId.toString(),
          'action': action,
        }),
      );
    } catch (e) {
      // Sessizce hatayı yoksay (Kullanıcı deneyimini bölmemek için)
    }
  }

  static Future<void> trackProximity({
    required int targetId,
    required String targetType,
    required int districtId,
    required double lat,
    required double lng,
  }) async {
    try {
      await http.post(
        Uri.parse('${baseUrl}track-proximity'),
        headers: _getHeaders(),
        body: jsonEncode({
          'target_id': targetId.toString(),
          'target_type': targetType,
          'district_id': districtId.toString(),
          'lat': lat.toString(),
          'lng': lng.toString(),
        }),
      );
    } catch (e) {
      // Sessizce hatayı yoksay
    }
  }

  // Kategori Eşleme
  static String mapCategorySlug(String? slug) {
    if (slug == null) return 'Historical';
    final s = slug.toLowerCase();
    
    if (s.contains('historical') || s.contains('tarihi')) return 'Historical';
    if (s.contains('nature') || s.contains('doga')) return 'Nature';
    if (s.contains('pharmacy') || s.contains('ecza')) return 'Pharmacy';
    if (s.contains('hotel') || s.contains('otel') || s.contains('accommodation') || s.contains('konaklama')) return 'Hotel';
    if (s.contains('restaurant') || s.contains('lokanta') || s.contains('dining') || s.contains('yemek')) return 'Restaurant';
    if (s.contains('hotspring') || s.contains('kaplica') || s.contains('thermal') || s.contains('thermal-places')) return 'HotSpring';
    if (s.contains('parks') || s.contains('park_bahce') || s.contains('parkandgarden') || s.contains('parks-gardens')) return 'ParkAndGarden';
    if (s.contains('kuruyemis')) return 'Kuruyemis';
    
    // Add variations for specific slugs used in UI
    if (s == 'historical-places') return 'Historical';
    if (s == 'nature-places') return 'Nature';
    if (s == 'parks-gardens') return 'ParkAndGarden';
    if (s == 'thermal-places') return 'HotSpring';
    
    return slug;
  }
}
