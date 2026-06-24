import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import '../../config/app_config.dart';
import '../home/home_screen.dart';

/// Bankacılık uygulamalarındaki gibi:
/// API'den özel gün resmi varsa → 2 saniye tam ekran gösterir → Ana Sayfa
/// Resim yoksa → Direkt Ana Sayfa
class SpecialDayScreen extends StatefulWidget {
  final String imageUrl;
  const SpecialDayScreen({super.key, required this.imageUrl});

  @override
  State<SpecialDayScreen> createState() => _SpecialDayScreenState();
}

class _SpecialDayScreenState extends State<SpecialDayScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    // Yumuşak fade-in animasyonu
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();

    // 2.5 saniye sonra Ana Sayfa'ya geç
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () {
          // Dokunarak da geçilebilir (kullanıcı dostu)
          Navigator.of(context).pushReplacement(
            CupertinoPageRoute(builder: (_) => const HomeScreen()),
          );
        },
        child: FadeTransition(
          opacity: _fadeIn,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Tam ekran özel gün görseli
              CachedNetworkImage(
                imageUrl: widget.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, __) => const ColoredBox(color: Colors.black),
                errorWidget: (_, __, ___) => const ColoredBox(color: Colors.black),
              ),
              // Alt kısımda "Devam etmek için dokun" ipucu
              Positioned(
                bottom: 60,
                left: 0,
                right: 0,
                child: Text(
                  'Devam etmek için dokunun',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Splash ekranından sonra API'yi çekip yönlendirmeyi belirleyen sınıf
class SpecialDayChecker extends StatefulWidget {
  const SpecialDayChecker({super.key});

  @override
  State<SpecialDayChecker> createState() => _SpecialDayCheckerState();
}

class _SpecialDayCheckerState extends State<SpecialDayChecker> {
  @override
  void initState() {
    super.initState();
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    String? bgImageUrl;

    try {
      final response = await Dio().get(
        "${AppConfig.baseMediaUrl}api/get_home_bg.php",
        options: Options(
          headers: {'Cache-Control': 'no-cache'},
          receiveTimeout: const Duration(seconds: 4),
          sendTimeout: const Duration(seconds: 4),
        ),
      );
      if (response.statusCode == 200 && response.data != null) {
        bgImageUrl = response.data['bg_image'];
      }
    } catch (e) {
      debugPrint("⚠️ Özel gün API hatası: $e");
    }

    if (!mounted) return;

    if (bgImageUrl != null && bgImageUrl.isNotEmpty) {
      // Özel gün resmi var → Tam ekran göster
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, __, ___) => SpecialDayScreen(imageUrl: bgImageUrl!),
          transitionsBuilder: (_, animation, __, child) =>
              FadeTransition(opacity: animation, child: child),
        ),
      );
    } else {
      // Özel gün yok → Direkt Ana Sayfa
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(builder: (_) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // API çekilirken siyah ekran (kısa süre)
    return const Scaffold(backgroundColor: Colors.black);
  }
}
