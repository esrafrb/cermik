
class TranslationHelper {
  static String getCategoryLabel(String? category, bool isEn) {
    if (category == null || category.isEmpty) return isEn ? 'CATEGORY' : 'KATEGORİ';
    
    final cFilter = category.toLowerCase();
    
    // Web parity translations
    if (cFilter.contains('historical') || cFilter.contains('tarihi')) {
      return isEn ? 'HISTORICAL' : 'TARİHİ MEKAN';
    }
    if (cFilter.contains('thermal') || cFilter.contains('hotspring') || cFilter.contains('kaplica')) {
      return isEn ? 'THERMAL SPA' : 'KAPLICA';
    }
    if (cFilter.contains('nature') || cFilter.contains('doga')) {
      return isEn ? 'NATURE' : 'DOĞA';
    }
    if (cFilter.contains('park')) {
      return isEn ? 'PARK & GARDEN' : 'PARK & BAHÇE';
    }
    if (cFilter.contains('kuruyemis') || cFilter.contains('local')) {
      return isEn ? 'LOCAL PRODUCTS' : 'KURUYEMİŞ & YEREL';
    }
    if (cFilter.contains('hotel') || cFilter.contains('otel')) {
      return isEn ? 'HOTELS' : 'OTELLER';
    }
    if (cFilter.contains('restaurant') || cFilter.contains('restoran')) {
      return isEn ? 'RESTAURANTS' : 'RESTORANLAR';
    }
    if (cFilter.contains('pharmacy') || cFilter.contains('eczane')) {
      return isEn ? 'PHARMACY' : 'ECZANE';
    }

    return category.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
  }
}
