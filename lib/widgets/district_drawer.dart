import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../providers/language_provider.dart';
import '../providers/district_provider.dart';
import '../views/guide/guide_detail_screen.dart';
import '../config/app_config.dart';

class DistrictDrawer extends StatelessWidget {
  final String districtId;
  final String districtSlug;
  final String mayorName;
  final String mayorTitle;
  final String mayorImageUrl;
  final String address;
  final String phone;
  final String email;

  // Navigation Callbacks
  final VoidCallback? onHomeTap;
  final VoidCallback? onServicesTap;
  final VoidCallback? onAnnouncementsTap;
  final VoidCallback? onEventsTap;
  final VoidCallback? onGuideTap;
  final VoidCallback? onPharmaciesTap;
  final VoidCallback? onLiveTap;

  const DistrictDrawer({
    super.key,
    required this.districtId,
    required this.districtSlug,
    required this.mayorName,
    required this.mayorTitle,
    required this.mayorImageUrl,
    required this.address,
    required this.phone,
    required this.email,
    this.onHomeTap,
    this.onServicesTap,
    this.onAnnouncementsTap,
    this.onEventsTap,
    this.onGuideTap,
    this.onPharmaciesTap,
    this.onLiveTap,
  });

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final provider = context.watch<DistrictProvider>();
    final bool isEn = languageProvider.isEn;
    final topLevel = provider.districtDetails; // Top level settings
    final settings = topLevel['settings'] ?? {};

    return Drawer(
      backgroundColor: const Color(0xFF0f172a),
      child: Column(
        children: [
          // Header (Mayor Info) - Web Parity District-Specific
          Material(
            color: const Color(0xFF1e293b),
            child: InkWell(
              onTap: () {
                final String bio = isEn 
                    ? (provider.mayorInfo['bio_en']?.toString().isNotEmpty == true ? provider.mayorInfo['bio_en']!.toString() : provider.mayorInfo['bio']?.toString() ?? "")
                    : provider.mayorInfo['bio']?.toString() ?? "";
                if (bio.isNotEmpty) {
                  showDialog(
                    context: context,
                    builder: (BuildContext ctx) {
                      return AlertDialog(
                        backgroundColor: const Color(0xFF1e293b),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        contentPadding: const EdgeInsets.all(20),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white10,
                              backgroundImage: (mayorImageUrl != "" && !mayorImageUrl.startsWith('http')) 
                                ? NetworkImage(AppConfig.imageUrl(mayorImageUrl))
                                : (mayorImageUrl != "" ? NetworkImage(mayorImageUrl) : null),
                              child: (mayorImageUrl == "") ? const Icon(Icons.person, color: Colors.white24, size: 40) : null,
                            ),
                            const SizedBox(height: 15),
                            Text(
                              mayorName,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              mayorTitle,
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Color(0xFF00c9ff), fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 15),
                            const Divider(color: Colors.white10),
                            const SizedBox(height: 10),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxHeight: MediaQuery.of(ctx).size.height * 0.4,
                              ),
                              child: SingleChildScrollView(
                                child: Text(
                                  bio,
                                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                                  textAlign: TextAlign.justify,
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF00c9ff),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: Text(isEn ? "Close" : "Kapat", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            )
                          ],
                        ),
                      );
                    }
                  );
                }
              },
              child: Container(
                padding: const EdgeInsets.only(top: 60, bottom: 25),
                width: double.infinity,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: const Color(0xFF00c9ff),
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: Colors.white10,
                        backgroundImage: (mayorImageUrl != "" && !mayorImageUrl.startsWith('http')) 
                           ? NetworkImage(AppConfig.imageUrl(mayorImageUrl))
                           : (mayorImageUrl != "" ? NetworkImage(mayorImageUrl) : null),
                        child: (mayorImageUrl == "") ? const Icon(Icons.person, color: Colors.white24, size: 40) : null,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Text(
                        mayorName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      child: Text(
                        mayorTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF00c9ff), fontSize: 11, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: [
                _buildMenuItem(context, FontAwesomeIcons.house, isEn ? "Home" : "Ana Sayfa", onTap: onHomeTap ?? () => Navigator.of(context).popUntil((r) => r.isFirst)),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20),
                  child: Divider(color: Colors.white10),
                ),
                _buildMenuItem(context, FontAwesomeIcons.handHoldingHeart, isEn ? "Services" : "Hizmetler", onTap: onServicesTap),
                _buildMenuItem(context, FontAwesomeIcons.bullhorn, isEn ? "Announcements" : "Duyurular", onTap: onAnnouncementsTap),
                _buildMenuItem(context, FontAwesomeIcons.calendarDay, isEn ? "Events" : "Etkinlikler", onTap: onEventsTap),
                
                // Municipal Guide (Belediye Rehberi)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 25, 20, 10),
                  child: Text(
                    (isEn ? "MUNICIPAL GUIDE" : "BELEDİYE REHBERİ").replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase(),
                    style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1.5),
                  ),
                ),
                
                // Dynamic Guide Items (Web Sync)
                ...provider.municipalGuide.map((guide) {
                   return _buildMenuItem(
                     context, 
                     FontAwesomeIcons.bookAtlas, 
                     isEn ? (guide.titleEn ?? guide.title) : guide.title,
                     onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => GuideDetailScreen(guide: guide)))
                   );
                }),
                
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  child: Divider(color: Colors.white10),
                ),
                
                _buildMenuItem(context, FontAwesomeIcons.kitMedical, isEn ? "Health Guide" : "Sağlık Rehberi", onTap: onPharmaciesTap),
                _buildMenuItem(context, FontAwesomeIcons.tv, isEn ? "Live" : "Canlı Yayın", onTap: onLiveTap),
              ],
            ),
          ),
          
          // Contact Info (Web Style)
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.black.withOpacity(0.2),
            child: Column(
              children: [
                _buildContactItem(FontAwesomeIcons.locationDot, address),
                const SizedBox(height: 10),
                _buildContactItem(FontAwesomeIcons.phone, phone, onTap: () async {
                  final Uri url = Uri.parse('tel:$phone');
                  if (await canLaunchUrl(url)) await launchUrl(url);
                }),
                const SizedBox(height: 10),
                _buildContactItem(FontAwesomeIcons.envelope, email, onTap: () async {
                  final Uri url = Uri.parse('mailto:$email');
                  if (await canLaunchUrl(url)) await launchUrl(url);
                }),
              ],
            ),
          ),

          // Social Media
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (settings['facebook_link'] != null && settings['facebook_link'].toString().isNotEmpty) _buildSocialBtn(settings['facebook_link'], FontAwesomeIcons.facebook),
                if (settings['instagram_link'] != null && settings['instagram_link'].toString().isNotEmpty) _buildSocialBtn(settings['instagram_link'], FontAwesomeIcons.instagram),
                if (settings['twitter_link'] != null && settings['twitter_link'].toString().isNotEmpty) _buildSocialBtn(settings['twitter_link'], FontAwesomeIcons.xTwitter),
                if (settings['youtube_link'] != null && settings['youtube_link'].toString().isNotEmpty) _buildSocialBtn(settings['youtube_link'], FontAwesomeIcons.youtube),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context, dynamic icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: FaIcon(icon, color: const Color(0xFF94a3b8), size: 18),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
      dense: true,
      onTap: onTap,
    );
  }

  Widget _buildContactItem(dynamic icon, String text, {VoidCallback? onTap}) {
    Widget child = Row(
      children: [
        FaIcon(icon, color: const Color(0xFF00c9ff), size: 14),
        const SizedBox(width: 12),
        Expanded(child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xFF94a3b8), fontSize: 11))),
      ],
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: child,
        ),
      );
    }
    return child;
  }

  Widget _buildSocialBtn(String url, dynamic icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: GestureDetector(
        onTap: () async => await launchUrl(Uri.parse(url)),
        child: FaIcon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
