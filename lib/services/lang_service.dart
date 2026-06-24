import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Uygulama geneli dil yönetim sistemi.
/// Admin panelindeki TR/EN mantığıyla birebir aynı çalışır.
class LangService extends ChangeNotifier {
  static final LangService _instance = LangService._internal();
  factory LangService() => _instance;
  LangService._internal();

  String _lang = 'tr';
  String get lang => _lang;
  bool get isEn => _lang == 'en';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _lang = prefs.getString('app_lang') ?? 'tr';
    notifyListeners();
  }

  Future<void> setLang(String lang) async {
    _lang = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_lang', lang);
    notifyListeners();
  }

  /// Admin panelindeki __() fonksiyonunun Flutter karşılığı.
  /// [key] mevcut değilse Türkçe değer döner.
  String t(String tr, {String? en}) {
    if (_lang == 'en' && en != null) return en;
    return tr;
  }

  /// Aynı anda iki değer geçirildiğinde dile göre seçer.
  String pick({required String tr, required String en}) {
    return _lang == 'en' ? en : tr;
  }
}

/// Tek erişim noktası
final langService = LangService();
