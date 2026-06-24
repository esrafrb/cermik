import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import 'package:rotarehber_flutter/providers/district_provider.dart';
import '../../models/extra_models.dart';
import 'guide_detail_screen.dart';

class GuideListScreen extends StatefulWidget {
  const GuideListScreen({super.key});

  @override
  State<GuideListScreen> createState() => _GuideListScreenState();
}

class _GuideListScreenState extends State<GuideListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<DistrictProvider>().fetchGuide());
  }

  @override
  Widget build(BuildContext context) {
    bool isEn = context.watch<LanguageProvider>().isEn;
    final provider = context.watch<DistrictProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(isEn ? "MUNICIPAL GUIDE" : "BELEDİYE REHBERİ", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Colors.transparent],
            ),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black26,
            child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
          ),
        ),
      ),
      body: provider.isLoadingGuide 
        ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
        : provider.guideItems.isEmpty
          ? Center(child: Text(isEn ? "No items found." : "İçerik bulunamadı.", style: const TextStyle(color: Colors.white70)))
          : Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFF0f172a), Color(0xFF1e293b), Color(0xFF0f172a)],
                    ),
                  ),
                ),
                ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 110, 20, 40),
                  physics: const BouncingScrollPhysics(),
                  itemCount: provider.guideItems.length,
                  itemBuilder: (context, index) {
                    final guide = MunicipalGuide.fromJson(Map<String, dynamic>.from(provider.guideItems[index]));
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        leading: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.cyan.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.menu_book, color: Colors.cyanAccent, size: 22),
                        ),
                        title: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isEn ? (guide.titleEn ?? guide.title) : guide.title,
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 5),
                            Container(height: 2, width: 30, decoration: BoxDecoration(color: Colors.cyanAccent, borderRadius: BorderRadius.circular(1))),
                          ],
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
                        onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideDetailScreen(guide: guide))),
                      ),
                    );
                  },
                ),
              ],
            ),
    );
  }
}
