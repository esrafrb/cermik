import 'package:flutter/cupertino.dart';
import '../providers/language_provider.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../core/constants/app_constants.dart';
import '../views/cek_gonder/cek_gonder_screen.dart';
import '../views/announcement/announcement_list_screen.dart';
import '../views/event/event_list_screen.dart';
import '../views/service/service_list_screen.dart';
import '../views/guide/guide_list_screen.dart';

class SidebarMenu extends StatelessWidget {
  final Map<String, dynamic>? districtSettings;
  final Function(int)? onTabSelected;

  const SidebarMenu({
    super.key,
    this.districtSettings,
    this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bool isEn = context.watch<LanguageProvider>().isEn;
    
    // Belediye Başkanı Verisi
    final String mayorName = districtSettings?['mayor_name'] ?? (isEn ? 'Mayor' : 'Belediye Başkanı');
    final String mayorTitle = isEn 
        ? (districtSettings?['mayor_title_en'] ?? 'Mayor') 
        : (districtSettings?['mayor_title'] ?? 'Belediye Başkanı');
    final String mayorImageUrl = AppConfig.imageUrl(districtSettings?['mayor_image']);

    return Drawer(
      backgroundColor: const Color(0xFF0f172a).withOpacity(0.98),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Column(children: [
          // HEADER: Belediye Başkanı Bölümü
          _buildMayorHeader(mayorImageUrl, mayorName, mayorTitle),

          Expanded(
            child: ListView(padding: const EdgeInsets.symmetric(vertical: 10), children: [
              _buildMenuItem(Icons.home_outlined, isEn ? 'HOME' : 'ANA SAYFA', () {
                Navigator.pop(context);
                onTabSelected?.call(0);
              }),
              
              _Divider(label: isEn ? 'CORPORATE' : 'KURUMSAL'),
              _buildMenuItem(Icons.campaign_outlined, isEn ? 'ANNOUNCEMENTS' : 'DUYURULAR', () {
                Navigator.pop(context);
                Navigator.push(context, CupertinoPageRoute(builder: (c) => AnnouncementListScreen(
                  districtId: (districtSettings?['id'] ?? 0).toString(),
                  districtName: districtSettings?['name'] ?? '',
                )));
              }),
              _buildMenuItem(Icons.event_note_outlined, isEn ? 'EVENTS' : 'ETKİNLİKLER', () {
                Navigator.pop(context);
                Navigator.push(context, CupertinoPageRoute(builder: (c) => EventListScreen(
                  districtId: (districtSettings?['id'] ?? 0).toString(),
                  districtName: districtSettings?['name'] ?? '',
                )));
              }),
              _buildMenuItem(Icons.auto_awesome_outlined, isEn ? 'SERVICES' : 'HİZMETLER', () {
                Navigator.pop(context);
                Navigator.push(context, CupertinoPageRoute(builder: (c) => ServiceListScreen(
                  districtId: (districtSettings?['id'] ?? 0).toString(),
                  districtName: districtSettings?['name'] ?? '',
                )));
              }),
              _buildMenuItem(Icons.camera_alt_outlined, isEn ? 'SNAP & SEND' : 'ÇEK GÖNDER', () {
                Navigator.pop(context);
                Navigator.push(context, CupertinoPageRoute(builder: (c) => CekGonderScreen(
                  districtId: (districtSettings?['id'] ?? 0).toString(),
                  districtName: districtSettings?['name'] ?? '',
                )));
              }),

              _Divider(label: isEn ? 'CITY GUIDE' : 'ŞEHİR REHBERİ'),
              _buildMenuItem(Icons.map_outlined, isEn ? 'GUIDE' : 'REHBER', () {
                Navigator.pop(context);
                Navigator.push(context, CupertinoPageRoute(builder: (c) => const GuideListScreen()));
              }),

              _Divider(label: isEn ? 'CONTACT' : 'İLETİŞİM'),
              if (districtSettings?['phone'] != null) _buildContact(Icons.phone, districtSettings!['phone']),
              if (districtSettings?['email'] != null) _buildContact(Icons.email, districtSettings!['email']),
              
              const SizedBox(height: 30),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _buildMayorHeader(String img, String name, String title) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 25),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.03)),
      child: Row(children: [
        CircleAvatar(
          radius: 30, 
          backgroundImage: img.startsWith('http') ? NetworkImage(img) : null, 
          backgroundColor: Colors.white10,
          child: !img.startsWith('http') ? const Icon(Icons.person, color: Colors.white24) : null,
        ),
        const SizedBox(width: 15),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          Text(title, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
        ])),
      ]),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: const Color(AppConstants.primaryColorHex), size: 20),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      onTap: onTap,
      dense: true,
    );
  }

  Widget _buildContact(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(children: [
        Icon(icon, color: Colors.white24, size: 16),
        const SizedBox(width: 10),
        Text(text, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
      ]),
    );
  }
}

class _Divider extends StatelessWidget {
  final String label;
  const _Divider({required this.label});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Row(children: [
        Text(label, style: const TextStyle(color: Color(AppConstants.secondaryColorHex), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(width: 10),
        const Expanded(child: Divider(color: Colors.white10, thickness: 1)),
      ]),
    );
  }
}
