import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/district_provider.dart';
import '../providers/language_provider.dart';
import '../config/app_config.dart';
import '../views/announcement/announcement_list_screen.dart';
import '../views/event/event_list_screen.dart';
import '../views/service/service_list_screen.dart';
import '../views/guide/guide_list_screen.dart';
import '../views/cek_gonder/cek_gonder_screen.dart';
import '../views/live/live_broadcast_screen.dart';
import '../views/business/business_list_screen.dart';
import '../views/pharmacy/pharmacy_list_screen.dart';

class AppDrawer extends StatelessWidget {
  final bool isEn;
  const AppDrawer({super.key, required this.isEn});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DistrictProvider>();
    final details = provider.districtDetails;
    final districtId = details['id']?.toString() ?? "";
    final districtName = details['name'] ?? "";
    final liveBroadcasts = details['live_broadcasts'] as List? ?? [];

    return Drawer(
      backgroundColor: Colors.transparent,
      elevation: 0,
      width: MediaQuery.of(context).size.width * 0.85,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0f172a).withOpacity(0.98),
          border: const Border(left: BorderSide(color: Colors.white10)),
        ),
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 35, 
                    backgroundColor: Colors.white10, 
                    backgroundImage: provider.mayorInfo['image'] != null 
                        ? NetworkImage(AppConfig.imageUrl(provider.mayorInfo['image'])) 
                        : null,
                    child: provider.mayorInfo['image'] == null 
                        ? const Icon(Icons.person_rounded, size: 40, color: Colors.cyan) 
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    provider.mayorInfo['name'] ?? (isEn ? "Visitor" : "Ziyaretçi"), 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                  ),
                  Text(
                    provider.mayorInfo['title'] ?? (isEn ? "Local Guide" : "Yerel Rehber"), 
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _buildSectionTitle(isEn ? "Municipal" : "Belediyemiz"),
                  _buildMenuItem(
                    icon: Icons.volunteer_activism_outlined, 
                    title: isEn ? "Services & Projects" : "Hizmetler ve Projeler", 
                    onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => ServiceListScreen(districtId: districtId, districtName: districtName)))
                  ),
                  _buildMenuItem(
                    icon: Icons.campaign_outlined, 
                    title: isEn ? "Announcements" : "Duyurular", 
                    onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => AnnouncementListScreen(districtId: districtId, districtName: districtName)))
                  ),
                  _buildMenuItem(
                    icon: Icons.event_outlined, 
                    title: isEn ? "Events" : "Etkinlikler", 
                    onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => EventListScreen(districtId: districtId, districtName: districtName)))
                  ),
                  // Dynamic Municipal Guide
                  ...provider.municipalGuide.map((item) => _buildMenuItem(
                    icon: Icons.info_outline,
                    title: isEn ? (item.titleEn ?? item.title) : item.title,
                    onTap: () {
                      // Custom action for guide item
                    }
                  )),

                  _buildMenuItem(
                    icon: Icons.menu_book_outlined, 
                    title: isEn ? "Municipal Guide" : "Belediye Rehberi", 
                    onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => const GuideListScreen()))
                  ),
                  if (liveBroadcasts.isNotEmpty)
                    _buildMenuItem(
                      icon: Icons.videocam_outlined, 
                      title: isEn ? "Live Broadcasts" : "Canlı Yayınlar", 
                      onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => LiveBroadcastScreen(broadcasts: liveBroadcasts)))
                    ),
                  _buildMenuItem(
                    icon: Icons.send_rounded, 
                    title: isEn ? "Capture & Send" : "Çek Gönder", 
                    color: Colors.greenAccent,
                    onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => CekGonderScreen(districtId: districtId, districtName: districtName)))
                  ),
                  
                  const Divider(color: Colors.white10, height: 30),
                  _buildSectionTitle(isEn ? "City Guide" : "Kent Rehberi"),
                  _buildMenuItem(
                    icon: Icons.account_balance_outlined, 
                    title: isEn ? "Historical Places" : "Tarihi Mekanlar", 
                    onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => BusinessListScreen(districtId: districtId, categoryId: "historical", categoryName: isEn ? "Historical" : "Tarihi Mekanlar")))
                  ),
                  _buildMenuItem(
                    icon: Icons.park_outlined, 
                    title: isEn ? "Parks & Nature" : "Park ve Doğa", 
                    onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => BusinessListScreen(districtId: districtId, categoryId: "nature", categoryName: isEn ? "Nature" : "Doğa ve Parklar")))
                  ),
                  _buildMenuItem(
                    icon: Icons.local_hospital_outlined, 
                    title: isEn ? "Pharmacies" : "Eczaneler", 
                    onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => PharmacyListScreen(districtId: districtId, districtName: districtName)))
                  ),
                  _buildMenuItem(
                    icon: Icons.restaurant_menu_rounded, 
                    title: isEn ? "Restaurants" : "Restoranlar", 
                    onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => BusinessListScreen(districtId: districtId, categoryId: "restaurants", categoryName: isEn ? "Restaurants" : "Restoranlar")))
                  ),
                  _buildMenuItem(
                    icon: Icons.hotel_rounded, 
                    title: isEn ? "Hotels" : "Oteller", 
                    onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => BusinessListScreen(districtId: districtId, categoryId: "hotels", categoryName: isEn ? "Hotels" : "Oteller")))
                  ),
                  const Divider(color: Colors.white10, height: 30),
                  _buildSectionTitle(isEn ? "Contact & Social" : "İletişim ve Sosyal"),
                  if (provider.contactInfo['phone'] != null)
                    _buildMenuItem(
                      icon: Icons.phone_android,
                      title: provider.contactInfo['phone'],
                      onTap: () {}
                    ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSocialIcon(Icons.facebook, Colors.blue),
                        _buildSocialIcon(Icons.camera_alt, Colors.pink),
                        _buildSocialIcon(Icons.alternate_email, Colors.lightBlue),
                        _buildSocialIcon(Icons.play_circle_filled, Colors.red),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white10, height: 1),
            _buildMenuItem(
              icon: Icons.language_rounded, 
              title: isEn ? "Türkçe'ye Geç" : "Switch to English", 
              onTap: () {
                context.read<LanguageProvider>().setEnglish(!isEn);
                Navigator.pop(context);
              }
            ),
            _buildMenuItem(icon: Icons.settings_rounded, title: isEn ? "Settings" : "Ayarlar", onTap: () {}),
            _buildMenuItem(icon: Icons.logout_rounded, title: isEn ? "Exit" : "Çıkış Yap", onTap: () {}, color: Colors.redAccent.withOpacity(0.8)),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 10, bottom: 10),
      child: Text(title.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase(), style: const TextStyle(color: Colors.cyan, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  Widget _buildMenuItem({required IconData icon, required String title, required VoidCallback onTap, Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.cyan.withOpacity(0.8), size: 22),
      title: Text(title, style: TextStyle(color: color ?? Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500, fontSize: 14)),
      onTap: onTap,
    );
  }
}

