import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';

class CheckInService {
  static String get _baseUrl => ApiService.baseUrl;


  /// Check-in işlemini gerçekleştirir
  /// [targetId]: İşletme veya Mekan ID'si
  /// [targetType]: 'place' veya 'business'
  /// [districtId]: İlçe ID'si
  static Future<Map<String, dynamic>> submitCheckIn({
    required int targetId,
    required int districtId,
    String targetType = 'place',
  }) async {
    try {
      // 1. Konum izni ve konum alma
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return {'status': 'error', 'message': 'Lütfen konum servisini açın.'};
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return {'status': 'error', 'message': 'Konum izni reddedildi.'};
        }
      }

      Position position = await Geolocator.getCurrentPosition();

      // 2. API'ye istek atma
      final response = await http.post(
        Uri.parse('$_baseUrl/check_in.php'),
        body: {
          'target_id': targetId.toString(),
          'target_type': targetType,
          'district_id': districtId.toString(),
          'lat': position.latitude.toString(),
          'lng': position.longitude.toString(),
        },
        // Not: Session yönetimi için web tarafındaki çerezleri/header'ları kullanıyor olmalıyız.
        // Eğer API token bazlı değilse, http.post otomatik olarak cookie'leri yönetmeyebilir.
        // Ancak bu aşamada yerel IP üzerinden test ediyoruz.
      );

      if (response.statusCode == 200 || response.statusCode == 401 || response.statusCode == 400) {
        return json.decode(utf8.decode(response.bodyBytes));
      } else {
        return {'status': 'error', 'message': 'Sunucu hatası: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Bağlantı hatası: $e'};
    }
  }
}
