import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../models/extra_models.dart';
import '../../config/app_config.dart';

class GuideDetailScreen extends StatelessWidget {
  final MunicipalGuide guide;

  const GuideDetailScreen({super.key, required this.guide});

  @override
  Widget build(BuildContext context) {
    bool isEn = context.watch<LanguageProvider>().isEn;
    String title = isEn ? (guide.titleEn ?? guide.title) : guide.title;
    String? content = isEn ? (guide.contentEn ?? guide.content) : guide.content;

    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF1e293b),
            leading: Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                backgroundColor: Colors.black26,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                   if (guide.image != null)
                      Image.network(AppConfig.imageUrl(guide.image!), fit: BoxFit.cover)
                   else
                      Container(color: const Color(0xFF334155)),
                   Container(
                     decoration: BoxDecoration(
                       gradient: LinearGradient(
                         begin: Alignment.topCenter,
                         end: Alignment.bottomCenter,
                         colors: [Colors.black.withOpacity(0.3), const Color(0xFF0f172a)],
                       ),
                     ),
                   ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1e293b).withOpacity(0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: Text(
                  content ?? (isEn ? "No content available." : "İçerik bulunmamaktadır."),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.8,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }
}
