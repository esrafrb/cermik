import 'package:flutter/material.dart';
import '../services/lang_service.dart';

class MunicipalGuideScreen extends StatelessWidget {
  final Map<String, dynamic> item;

  const MunicipalGuideScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final bool isEn = langService.isEn;
    final String title = isEn ? (item['title_en'] ?? item['title']) : item['title'];
    final String content = isEn ? (item['content_en'] ?? item['content']) : item['content'];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(title.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase(), 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: 1)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topRight,
            radius: 1.5,
            colors: [Color(0xFF1e293b), Color(0xFF0f172a)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(25, 130, 25, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Decoration
              Container(
                height: 4, width: 60,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF00c9ff), Color(0xFF92fe9d)]),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 25),
              
              // Content (Web: .guide-content)
              Text(
                content.replaceAll(RegExp(r'<[^>]*>'), ''), // Basit HTML temizleme (Zengin içerik için flutter_html eklenebilir)
                style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 16,
                  height: 1.8,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                ),
              ),
              
              const SizedBox(height: 50),
              
              // Footer Logo (Web mirror)
              Center(
                child: Opacity(
                  opacity: 0.1,
                  child: Image.asset('assets/img/logo/logo.png', height: 80, errorBuilder: (c,e,s) => const Icon(Icons.location_on, size: 80, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
