import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:app_links/app_links.dart';
import 'views/place/place_detail_screen.dart';
import 'views/business/business_detail_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'providers/district_provider.dart';
import 'providers/language_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/cart_provider.dart';
import 'services/api_service.dart';
import 'views/splash/splash_screen.dart';

// --- flutter_local_notifications: Bildirim gösterici (görsel destekli) ---
// Aynı bildirimin tekrar gösterilmesini önleyen ID seti
final Set<String> _shownNotificationIds = {};
final FlutterLocalNotificationsPlugin _localNotif = FlutterLocalNotificationsPlugin();

const AndroidNotificationChannel _androidChannel = AndroidNotificationChannel(
  'high_importance_channel',           // FCM payload'daki channel_id ile aynı
  'Yüksek Öncelikli Bildirimler',
  description: 'RotaRehber uygulama bildirimleri.',
  importance: Importance.max,
);

/// FCM görsel URL'sini indirir; başarısızsa null döner
Future<Uint8List?> _downloadImageBytes(String url) async {
  try {
    final res = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
    if (res.statusCode == 200) return res.bodyBytes;
  } catch (e) {
    debugPrint('[FCM] Görsel indirilemedi: $e');
  }
  return null;
}

// Uygulama KAPALI iken gelen bildirimler için gerekli (top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyBAqa--GNH_3QSXzgTncnTS1d-LcjwNWeU',
        appId: '1:24354283713:ios:36de4bae5024f60014f440',
        messagingSenderId: '24354283713',
        projectId: 'yahyailesosyalgiris-84f11',
        storageBucket: 'yahyailesosyalgiris-84f11.firebasestorage.app',
        iosBundleId: 'com.rotarehber.app',
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  
  // Arka planda gelen bildirimleri zil ikonuna (Hive'a) kaydet
  try {
    await Hive.initFlutter();
    await Hive.openBox('rotarehber_cache');
    final box = Hive.box('rotarehber_cache');
    
    final String msgId = message.messageId ?? message.sentTime?.millisecondsSinceEpoch.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
    final notif = message.notification;
    if (notif == null) return;
    
    final imageUrl = message.data['image']?.toString().isNotEmpty == true
        ? message.data['image']
        : message.notification?.android?.imageUrl;
        
    final newNotif = {
      'id': msgId,
      'title': notif.title ?? '',
      'body': notif.body ?? '',
      'imageUrl': imageUrl,
      'receivedAt': DateTime.now().toIso8601String(),
      'isRead': false,
    };
    
    List<dynamic> existing = box.get('push_notifications') ?? [];
    // Duplicate check
    if (!existing.any((e) => e is Map && e['id'] == msgId)) {
      existing.insert(0, newNotif);
      if (existing.length > 100) existing = existing.sublist(0, 100);
      await box.put('push_notifications', existing);
    }
  } catch (e) {
    debugPrint('[Background FCM] Hive save error: $e');
  }
}

void _handleNotificationLink(RemoteMessage message) async {
  if (message.data.containsKey('link')) {
    final String link = message.data['link'] ?? '';
    if (link.isNotEmpty) {
      final Uri url = Uri.parse(!link.startsWith('http') ? 'https://$link' : link);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load saved auth token
  await ApiService.loadToken();
  
  // Initialize date formatting for Turkish locale
  await initializeDateFormatting('tr_TR', null);
  
  // Hive Offline Cache Initialization
  try {
    await Hive.initFlutter();
    await Hive.openBox('rotarehber_cache');
  } catch (e) {
    debugPrint("Hive initialization error: $e");
  }
  
  // Initialize Firebase and Notifications before runApp to prevent APNs registration issues
  await _initializeFirebaseAndNotifications();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DistrictProvider()..fetchDistricts()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()..loadFromCache()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // 1. Kapalıyken (Terminated) gelen linki yakala
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint("AppLinks getInitialLink error: $e");
    }

    // 2. Arka plandayken (Background) gelen linkleri dinle
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    }, onError: (err) {
      debugPrint("AppLinks uriLinkStream error: $err");
    });
  }

  void _handleDeepLink(Uri uri) {
    debugPrint("🔗 Gelen Deep Link Yakalandı: $uri");
    
    // Yönlendirme senaryoları (Örn: /qr.php?target=place&id=15 veya /qr.php?target=web&url=cermik/kaplica.php)
    final target = uri.queryParameters['target'];
    final idStr = uri.queryParameters['id'];
    final urlPath = uri.queryParameters['url'];
    
    if (target != null) {
      // 1. Senaryo: Web sayfasına yönlendirme (İç tarayıcıda açılır)
      if (target == 'web' && urlPath != null) {
        Future.delayed(const Duration(milliseconds: 500), () async {
          final webUri = Uri.parse("https://rotarehber.com/$urlPath");
          if (await canLaunchUrl(webUri)) {
            await launchUrl(webUri, mode: LaunchMode.inAppWebView);
          }
        });
        return;
      }

      // 2. Senaryo: Mekan veya İşletme (ID gerektirir)
      if (idStr != null) {
        final intId = int.tryParse(idStr);
        if (intId != null) {
          // Küçük bir gecikme ekleyelim ki context tam oluşsun
          Future.delayed(const Duration(milliseconds: 500), () {
            if (target == 'place') {
              navigatorKey.currentState?.push(
                MaterialPageRoute(builder: (_) => PlaceDetailScreen(placeId: intId)),
              );
            } else if (target == 'business') {
              navigatorKey.currentState?.push(
                MaterialPageRoute(builder: (_) => BusinessDetailScreen(
                  districtId: "0", 
                  businessId: intId.toString(), 
                  businessName: "İşletme"
                )),
              );
            }
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'RotaRehber',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF00c9ff),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF00c9ff),
          secondary: const Color(0xFF92fe9d),
        ),
      ),
      // Web ile tam uyumlu açılış (Yükleniyor) ekranı başlatılıyor
      home: const SplashScreen(),
    );
  }
}

Future<void> _initializeFirebaseAndNotifications() async {
  try {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyBAqa--GNH_3QSXzgTncnTS1d-LcjwNWeU',
          appId: '1:24354283713:ios:36de4bae5024f60014f440',
          messagingSenderId: '24354283713',
          projectId: 'yahyailesosyalgiris-84f11',
          storageBucket: 'yahyailesosyalgiris-84f11.firebasestorage.app',
          iosBundleId: 'com.rotarehber.app',
        ),
      );
    } else {
      await Firebase.initializeApp();
    }
    // Geri kalan API istekleri ve izin pencereleri runApp'i (UI çizimini) 
    // engellemesin diye asenkron olarak arka planda çalıştırıyoruz.
    Future.microtask(() async {
      try {
        final messaging = FirebaseMessaging.instance;

        // Flutter Local Notifications — Android & iOS başlatma
    await _localNotif
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_androidChannel);
        
    await _localNotif.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        ),
      ),
    );

    // İzin iste (iOS için zorunlu, Android 13+ için de gerekli)
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // FCM Token'ı al ve sunucuya gönder (Giriş yapılmışsa ApiService bunu otomatik profile bağlar)
    try {
      final token = await messaging.getToken();
      if (token != null) {
        debugPrint('[FCM] Token alındı ve sunucuya iletiliyor: $token');
        await ApiService.updateFcmToken(token);
      }
    } catch (e) {
      debugPrint('[FCM] Token alınamadı veya gönderilemedi: $e');
    }

    // iOS'ta uygulama açıkken bildirimin üstten düşmesini sağla (Foreground Notification)
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      alert: true, 
      badge: true, 
      sound: true,
    );

    // Tüm kullanıcıları 'all_users' topic'ine abone et
    await messaging.subscribeToTopic('all_users');

    // Uygulama KAPALI iken gelen bildirime tıklayınca açılış
    RemoteMessage? initialMessage = await messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationLink(initialMessage);
      Future.delayed(const Duration(seconds: 1), () {
        navigatorKey.currentContext?.read<NotificationProvider>().loadFromCache();
      });
    }

    // Uygulama ARKA PLANDA iken gelen bildirime tıklayınca açılış
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationLink(message);
      try {
        navigatorKey.currentContext?.read<NotificationProvider>().loadFromCache();
      } catch (e) {}
    });

    // Uygulama AÇIK iken gelen bildirimleri dinle (görsel destekli)
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // --- Duplicate önleme (debug hot reload veya çoklu listener durumu) ---
      final String msgId = message.messageId ?? message.sentTime?.millisecondsSinceEpoch.toString() ?? '';
      if (msgId.isNotEmpty && _shownNotificationIds.contains(msgId)) {
        debugPrint('[FCM] Duplicate bildirim engellendi: $msgId');
        return;
      }
      if (msgId.isNotEmpty) _shownNotificationIds.add(msgId);
      // 100'den fazla ID birikirse temizle (bellek yönetimi)
      if (_shownNotificationIds.length > 100) _shownNotificationIds.clear();

      debugPrint('[FCM] Bildirim alındı: ${message.notification?.title}');

      final notif = message.notification;
      if (notif == null) return;

      final String? imageUrl = message.data['image']?.toString().isNotEmpty == true
          ? message.data['image']
          : message.notification?.android?.imageUrl;

      // Bildirimi provider'a kaydet (Uygulama içi liste için)
      try {
        final context = navigatorKey.currentContext;
        if (context != null) {
          context.read<NotificationProvider>().addNotification(
                id: msgId.isNotEmpty ? msgId : DateTime.now().millisecondsSinceEpoch.toString(),
                title: notif.title ?? '',
                body: notif.body ?? '',
                imageUrl: imageUrl,
              );
        }
      } catch (e) {
        debugPrint('Provider notification add error: $e');
      }

      AndroidNotificationDetails androidDetails;

      if (imageUrl != null && imageUrl.isNotEmpty) {
        final imageBytes = await _downloadImageBytes(imageUrl);
        if (imageBytes != null) {
          androidDetails = AndroidNotificationDetails(
            _androidChannel.id,
            _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.max,
            priority: Priority.high,
            styleInformation: BigPictureStyleInformation(
              ByteArrayAndroidBitmap(imageBytes),
              contentTitle: notif.title,
              summaryText: notif.body,
              hideExpandedLargeIcon: false,
            ),
          );
        } else {
          androidDetails = AndroidNotificationDetails(
            _androidChannel.id, _androidChannel.name,
            channelDescription: _androidChannel.description,
            importance: Importance.max, priority: Priority.high,
          );
        }
      } else {
        androidDetails = AndroidNotificationDetails(
          _androidChannel.id, _androidChannel.name,
          channelDescription: _androidChannel.description,
          importance: Importance.max, priority: Priority.high,
        );
      }

      if (Platform.isAndroid) {
        await _localNotif.show(
          notif.hashCode,
          notif.title,
          notif.body,
          NotificationDetails(android: androidDetails),
        );
      }
    });

      } catch (e) {
        debugPrint("Background FCM setup error: $e");
      }
    });

  } catch (e) {
    debugPrint("Firebase initialization error: $e");
  }
}

