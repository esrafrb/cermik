import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final DateTime receivedAt;
  bool isRead;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    required this.receivedAt,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'imageUrl': imageUrl,
        'receivedAt': receivedAt.toIso8601String(),
        'isRead': isRead,
      };

  factory AppNotification.fromMap(Map map) => AppNotification(
        id: map['id']?.toString() ?? '',
        title: map['title']?.toString() ?? '',
        body: map['body']?.toString() ?? '',
        imageUrl: map['imageUrl']?.toString(),
        receivedAt: DateTime.tryParse(map['receivedAt']?.toString() ?? '') ?? DateTime.now(),
        isRead: map['isRead'] == true,
      );
}

class NotificationProvider extends ChangeNotifier {
  static const _boxKey = 'push_notifications';
  List<AppNotification> _notifications = [];

  List<AppNotification> get notifications => _notifications;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  /// Hive'dan yükle (uygulama başlarken çağrılır)
  Future<void> loadFromCache() async {
    try {
      final box = Hive.box('rotarehber_cache');
      final raw = box.get(_boxKey);
      if (raw != null && raw is List) {
        _notifications = raw
            .whereType<Map>()
            .map((m) => AppNotification.fromMap(m))
            .toList()
          ..sort((a, b) => b.receivedAt.compareTo(a.receivedAt));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[NotificationProvider] loadFromCache error: $e');
    }
  }

  /// Yeni bildirim ekle ve Hive'a kaydet
  Future<void> addNotification({
    required String id,
    required String title,
    required String body,
    String? imageUrl,
  }) async {
    // Aynı ID'den tekrar eklemeyi önle
    if (_notifications.any((n) => n.id == id)) return;

    final notif = AppNotification(
      id: id,
      title: title,
      body: body,
      imageUrl: imageUrl,
      receivedAt: DateTime.now(),
    );

    _notifications.insert(0, notif);

    // En fazla 100 bildirim tut
    if (_notifications.length > 100) {
      _notifications = _notifications.sublist(0, 100);
    }

    await _saveToCache();
    notifyListeners();
  }

  /// Hepsini okundu işaretle
  Future<void> markAllAsRead() async {
    for (final n in _notifications) {
      n.isRead = true;
    }
    await _saveToCache();
    notifyListeners();
  }

  /// Tek bildirimi okundu yap
  Future<void> markAsRead(String id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      _notifications[idx].isRead = true;
      await _saveToCache();
      notifyListeners();
    }
  }

  /// Tüm bildirimleri temizle
  Future<void> clearAll() async {
    _notifications.clear();
    await _saveToCache();
    notifyListeners();
  }

  Future<void> _saveToCache() async {
    try {
      final box = Hive.box('rotarehber_cache');
      box.put(_boxKey, _notifications.map((n) => n.toMap()).toList());
    } catch (e) {
      debugPrint('[NotificationProvider] _saveToCache error: $e');
    }
  }
}
