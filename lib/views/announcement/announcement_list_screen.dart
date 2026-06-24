import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:rotarehber_flutter/providers/district_provider.dart';
import '../../providers/language_provider.dart';
import '../../config/app_config.dart';
import 'package:rotarehber_flutter/models/extra_models.dart';

class AnnouncementListScreen extends StatefulWidget {
  final String? districtId;
  final String districtName;

  const AnnouncementListScreen({
    super.key, 
    this.districtId,
    required this.districtName,
  });

  @override
  State<AnnouncementListScreen> createState() => _AnnouncementListScreenState();
}

class _AnnouncementListScreenState extends State<AnnouncementListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<DistrictProvider>().fetchAnnouncements(widget.districtId ?? ""));
  }

  @override
  Widget build(BuildContext context) {
    final isEn = context.watch<LanguageProvider>().isEn;
    final provider = context.watch<DistrictProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEn ? "ANNOUNCEMENTS" : "DUYURULAR", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white)),
            Text(widget.districtName.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
          ],
        ),
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
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0f172a), Color(0xFF1e293b), Color(0xFF0f172a)],
                ),
              ),
            ),
          ),
          
          if (provider.isLoadingAnnouncements)
            const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          else if (provider.announcements.isEmpty)
            _buildEmptyState(isEn)
          else
            _buildAnnouncementList(provider.announcements, isEn),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isEn) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.campaign_outlined, color: Colors.white12, size: 80),
          const SizedBox(height: 20),
          Text(isEn ? "No announcements found" : "Güncel duyuru bulunamadı", style: const TextStyle(color: Colors.white38, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildAnnouncementList(List<Announcement> announcements, bool isEn) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 140, 20, 40),
      itemCount: announcements.length,
      itemBuilder: (context, index) => _buildAnnouncementCard(announcements[index], isEn),
    );
  }

  Widget _buildAnnouncementCard(Announcement item, bool isEn) {
    final String? imgUrl = item.image != null && item.image!.isNotEmpty
        ? AppConfig.imageUrl(item.image!)
        : null;

    final dateStr = item.createdAt != null 
        ? DateFormat('dd MMMM yyyy', isEn ? 'en_US' : 'tr_TR').format(DateTime.parse(item.createdAt!))
        : "";

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (imgUrl != null)
                  GestureDetector(
                    onTap: () => _showFullScreenImage(context, imgUrl),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                          child: Image.network(
                            imgUrl,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => const SizedBox.shrink(),
                          ),
                        ),
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, color: Colors.cyanAccent, size: 14),
                          const SizedBox(width: 8),
                          Text(dateStr, style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.w900)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        (isEn ? (item.titleEn ?? item.title) : item.title),
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, height: 1.3)
                      ),
                      const SizedBox(height: 5),
                      Container(
                        height: 2, width: 40,
                        decoration: BoxDecoration(color: Colors.cyanAccent, borderRadius: BorderRadius.circular(1)),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        (isEn ? (item.contentEn ?? item.content) : item.content) ?? "",
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14, height: 1.6),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, _, __) => Scaffold(
          backgroundColor: Colors.black.withOpacity(0.9),
          body: Stack(
            children: [
              Center(child: InteractiveViewer(child: Image.network(imageUrl, fit: BoxFit.contain))),
              Positioned(
                top: 50, right: 20,
                child: IconButton(icon: const Icon(Icons.close, color: Colors.white, size: 30), onPressed: () => Navigator.pop(context)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
