import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class LanguageProvider extends ChangeNotifier {
  bool _isEn = ui.PlatformDispatcher.instance.locale.languageCode == 'en'; // Müşteri talebi: Telefon dili İngilizceyse otomatik İngilizce açılsın

  bool get isEn => _isEn;

  void setEnglish(bool value) {
    _isEn = value;
    notifyListeners();
  }
}
