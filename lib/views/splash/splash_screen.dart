import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../config/app_config.dart';
import '../home/home_screen.dart';
import 'special_day_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.85, end: 1.05).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // Splash bittikten sonra özel gün kontrolü yap
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (_, __, ___) => const SpecialDayChecker(),
            transitionsBuilder: (_, animation, __, child) =>
                FadeTransition(opacity: animation, child: child),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const bgColor = Color(0xFF0b0f19); // Match HomeScreen

    return Scaffold(
      backgroundColor: bgColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _animation,
              child: Image.network(
                "${AppConfig.baseMediaUrl}splash_logo.png",
                width: 150,
                errorBuilder: (c, e, s) => Image.network(
                  "${AppConfig.baseMediaUrl}assets/img/logo/logo.png",
                  width: 150,
                  errorBuilder: (c, e, s) => const FaIcon(FontAwesomeIcons.route, size: 80, color: Color(0xFF06b6d4)),
                ),
              ),
            ),
            const SizedBox(height: 40),
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(
                color: Color(0xFF06b6d4),
                strokeWidth: 3,
                backgroundColor: Colors.white10,
              ),
            ),
            const SizedBox(height: 25),
            Text(
              "YÜKLENİYOR",
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 3.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
