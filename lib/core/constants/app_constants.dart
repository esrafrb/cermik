import '../../config/app_config.dart';

class AppConstants {
  static const String appName = 'RotaRehber';

  // API Bağlantı Ayarları - AppConfig üzerinden dinamik (kIsWeb destekli)
  static String get baseUrl => AppConfig.apiBaseUrl;
  static String get baseMediaUrl => AppConfig.baseMediaUrl;

  // Renkler - Web ile Tam Senkronize
  static const int primaryColorHex = 0xFF00c9ff;   // Turkuaz
  static const int secondaryColorHex = 0xFF92fe9d; // Neon Yeşil
  static const int darkColorHex = 0xFF0f172a;      // Koyu Arkaplan
  static const int accentColorHex = 0xFFf6ad55;
  static const int backgroundColorHex = 0xFF0a0e14;
  
  // İlçe Özel Gradyanları (Web Senkron)
  static const List<int> cermikGrad = [0xFFFF512F, 0xFFDD2476]; // Kırmızı-Pembe
  static const List<int> cungusGrad = [0xFF1d976c, 0xFF93f9b9]; // Yeşil-Neon

  // Timeout - 30 Saniye (Sunucu Gecikmelerini Önlemek İçin)
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 30000;
}
