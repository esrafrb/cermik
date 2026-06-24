class AppConfig {
  static const String appName = 'Çermik Belediyesi';
  
  // Canlı sunucu erişimi için
  static String get apiBaseUrl {
    return 'https://cermik.rotarehber.com/laravel_api/public/api/v1/';
  }

  /// Web sitesi ana URL'si — Paylaş linkleri için kullan (API URL'si değil!)
  static String get webBaseUrl => 'https://cermik.rotarehber.com';

  static String get baseUrl => webBaseUrl;
  
  static String get baseMediaUrl {
    return 'https://cermik.rotarehber.com/';
  }




  static String imageUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    if (path.startsWith('http')) return path;
    
    String cleanBase = baseMediaUrl;
    if (!cleanBase.endsWith('/')) cleanBase += '/';
    
    String cleanPath = path;
    // Web'e özgü göreli yolları temizle: "../uploads/..." → "uploads/..."
    while (cleanPath.startsWith('../')) cleanPath = cleanPath.substring(3);
    while (cleanPath.startsWith('./')) cleanPath = cleanPath.substring(2);
    if (cleanPath.startsWith('/')) cleanPath = cleanPath.substring(1);
    
    return '$cleanBase$cleanPath';
  }
}
