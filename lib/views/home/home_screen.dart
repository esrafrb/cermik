import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:rotarehber_flutter/providers/district_provider.dart';
import '../../providers/language_provider.dart';
import '../../config/app_config.dart';
import '../district/district_details_screen.dart';
import 'qr_scanner_screen.dart';
import '../../providers/notification_provider.dart';
import '../../screens/notification_screen.dart';
import '../../widgets/ramadan_timer_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final provider = context.read<DistrictProvider>();
      provider.fetchDistricts();
      provider.fetchGlobalEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isEn = context.watch<LanguageProvider>().isEn;
    const bgColor = Color(0xFF0b0f19); // Rich dark blue from image

    return Scaffold(
      backgroundColor: bgColor,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF111827), Color(0xFF0b0f19)],
          ),
        ),
        child: Consumer<DistrictProvider>(
              builder: (context, provider, child) {
            if (provider.isLoadingDistricts) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFF06b6d4)));
            }

            final districts = provider.districts;
            final globalEvents = provider.globalEvents;

            return RefreshIndicator(
              onRefresh: () async {
                await provider.fetchDistricts();
                await provider.fetchGlobalEvents();
              },
              color: const Color(0xFF06b6d4),
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // --- 1. Top Navigation Bar (Logo Centered, Lang Right) ---
                  SliverToBoxAdapter(
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        child: Row(
                          children: [
                            // Spacer to balance right side
                            const SizedBox(width: 72),
                            // Logo centered
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                   if (districts.isNotEmpty && districts.first.logo != null && districts.first.logo!.isNotEmpty)
                                    Image.network(
                                      AppConfig.imageUrl(districts.first.logo),
                                      height: 140,
                                      fit: BoxFit.contain,
                                      errorBuilder: (context, error, stack) => Image.network(
                                        "${AppConfig.baseMediaUrl}splash_logo.png",
                                        height: 140,
                                        fit: BoxFit.contain,
                                        errorBuilder: (c, e, s) => const FaIcon(FontAwesomeIcons.route, color: Color(0xFF06b6d4), size: 48),
                                      ),
                                    )
                                  else
                                    Image.network(
                                      "${AppConfig.baseMediaUrl}splash_logo.png",
                                      height: 140,
                                      fit: BoxFit.contain,
                                      errorBuilder: (c, e, s) => const FaIcon(FontAwesomeIcons.route, color: Color(0xFF06b6d4), size: 48),
                                    ),
                                ],
                              ),
                            ),
                            // Language Toggle
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => context.read<LanguageProvider>().setEnglish(false),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: !isEn ? const Color(0xFF06b6d4) : Colors.white.withOpacity(0.07),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "TR",
                                      style: TextStyle(
                                        color: !isEn ? Colors.black : Colors.white54,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                GestureDetector(
                                  onTap: () => context.read<LanguageProvider>().setEnglish(true),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                    decoration: BoxDecoration(
                                      color: isEn ? const Color(0xFF06b6d4) : Colors.white.withOpacity(0.07),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      "EN",
                                      style: TextStyle(
                                        color: isEn ? Colors.black : Colors.white54,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // --- 2. Hero Section (Centered Content) ---
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, bottom: 10, left: 30, right: 30),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (districts.isNotEmpty)
                            RamadanTimerWidget(districtId: districts.first.id),
                          _buildQrButton(context, isEn),
                        ],
                      ),
                    ),
                  ),

                  // --- 3. Districts Section ---
                  
                  if (provider.error != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.redAccent.withOpacity(0.3))),
                          child: Text(provider.error!, style: const TextStyle(color: Colors.redAccent, fontSize: 12), textAlign: TextAlign.center),
                        ),
                      ),
                    )
                  else if (districts.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Container(
                          padding: const EdgeInsets.all(40),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.02), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.04))),
                          child: Column(
                            children: [
                              FaIcon(FontAwesomeIcons.circleExclamation, color: Colors.white.withOpacity(0.1), size: 30),
                              const SizedBox(height: 15),
                              Text(
                                isEn ? "No districts found." : "Henüz ilçe verisi bulunmuyor.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildDistrictCard(context, districts[index], isEn, provider),
                          childCount: districts.length,
                        ),
                      ),
                    ),

                  // --- 4. Global Events Section ---
                  SliverToBoxAdapter(
                    child: _buildSectionHeader(isEn ? "Events" : "Etkinlikler"),
                  ),
                  _buildEventsList(globalEvents, isEn, districts),

                  // --- 5. Footer ---
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 50),
                      child: Column(
                        children: [
                          Text(
                            "Çermik Belediyesi",
                            style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 9, fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildFooterLink(isEn ? "Privacy Policy" : "Gizlilik Politikası", "privacy.php"),
                              _buildFooterDot(),
                              _buildFooterLink(isEn ? "Admin Login" : "Yönetim Girişi", "admin/"),
                              _buildFooterDot(),
                              _buildFooterLink(isEn ? "Business Login" : "İşletme Girişi", "business/"),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }



  Widget _buildQrButton(BuildContext context, bool isEn) {
    return GestureDetector(
      onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => const QRScannerScreen())),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF06b6d4), Color(0xFF10b981)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF10b981).withOpacity(0.2),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FaIcon(FontAwesomeIcons.hashtag, color: Colors.white, size: 16),
            const SizedBox(width: 10),
            Text(
              isEn ? "SCAN QR CODE" : "KAREKOD OKUT",
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 40, 25, 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Color(0xFF06b6d4), fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
          const SizedBox(height: 8),
          Container(height: 1, width: 60, color: const Color(0xFF06b6d4).withOpacity(0.3)),
        ],
      ),
    );
  }

  Widget _buildDistrictCard(BuildContext context, dynamic district, bool isEn, DistrictProvider provider) {
    final weather = provider.districtsWeather[district.id.toString()];
    final temp = weather != null ? "${weather['temperature']}°C" : null;

    return GestureDetector(
      onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => DistrictDetailsScreen(districtId: district.id.toString(), districtName: district.name))),
      child: Container(
        height: 180,
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Background Image - API'den gelen district.image kullan (web parity)
              // district.image null ise hero_image'a bak, o da yoksa slug bazlı varsayılan
              Positioned.fill(
                child: () {
                  // 1. district.image varsa kullan (admin'in yüklediği ilçe resmi)
                  String? imgPath = district.image;
                  // 2. Null ise slug'a göre varsayılan statik resim
                  if (imgPath == null || imgPath.isEmpty) {
                    if (district.slug == 'cermik') {
                      imgPath = 'assets/img/categories/kaplica.jpg';
                    } else if (district.slug == 'cungus') {
                      imgPath = 'assets/img/categories/historical.jpg';
                    } else {
                      imgPath = 'assets/img/categories/historical.jpg';
                    }
                  }
                  return CachedNetworkImage(
                    imageUrl: AppConfig.imageUrl(imgPath),
                    fit: BoxFit.cover,
                    errorWidget: (c, u, e) => Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [const Color(0xFF1e3a5f), const Color(0xFF0b1a2e)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  );
                }(),
              ),
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.5), Colors.black.withOpacity(0.9)],
                    ),
                  ),
                ),
              ),
              // Info Overlay as per Image1
              Positioned(
                bottom: 20,
                left: 20,
                right: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEn ? (district.nameEn ?? district.name) : district.name,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              const FaIcon(FontAwesomeIcons.cloud, color: Colors.white70, size: 10),
                              const SizedBox(width: 8),
                              Text(
                                temp ?? (isEn ? "Loading..." : "Yükleniyor..."),
                                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              if (provider.districtDistances[district.id.toString()] != null) ...[
                                const SizedBox(width: 15),
                                const FaIcon(FontAwesomeIcons.locationDot, color: Colors.cyanAccent, size: 10),
                                const SizedBox(width: 6),
                                Text(
                                  provider.districtDistances[district.id.toString()]!,
                                  style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    _buildNotificationBell(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventsList(List<dynamic> events, bool isEn, List<dynamic> districts) {
    if (events.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.04)),
            ),
            child: Text(
              isEn ? "No general events published yet." : "Henüz yayınlanmış bir genel etkinlik bulunmuyor.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      );
    }

    final now = DateTime.now();

    // Gelecek etkinlikler
    final upcoming = events
        .where((e) => e['event_date'] != null && DateTime.tryParse(e['event_date'].toString()) != null
            && DateTime.parse(e['event_date'].toString()).isAfter(now))
        .toList()
      ..sort((a, b) => DateTime.parse(a['event_date'].toString()).compareTo(DateTime.parse(b['event_date'].toString())));

    // Geçmiş etkinlikler
    final past = events
        .where((e) => e['event_date'] != null && DateTime.tryParse(e['event_date'].toString()) != null
            && !DateTime.parse(e['event_date'].toString()).isAfter(now))
        .toList()
      ..sort((a, b) => DateTime.parse(b['event_date'].toString()).compareTo(DateTime.parse(a['event_date'].toString())));

    // Tarihi olmayanlar
    final noDate = events.where((e) => e['event_date'] == null || DateTime.tryParse(e['event_date'].toString()) == null).toList();

    final sortedEvents = [...upcoming, ...past, ...noDate];

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 160,
        child: Stack(
          children: [
            ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: sortedEvents.length,
              itemBuilder: (context, index) {
                final ev = sortedEvents[index];
                final String imgUrl = (ev['image'] != null && ev['image'] != "")
                    ? AppConfig.imageUrl(ev['image'])
                    : "https://via.placeholder.com/400x250?text=Etkinlik";
                final DateTime date = DateTime.tryParse(ev['event_date'] ?? "") ?? DateTime.now();
                final bool isPast = date.isBefore(DateTime(
                  DateTime.now().year, DateTime.now().month, DateTime.now().day));

                String districtName = isEn ? "General" : "Genel";
                if (ev['district_id'] != null) {
                  final dId = ev['district_id'].toString();
                  // DistrictModel ile çalıştıysa type casting gerekir, isimlendirmeyi District class'tan çekelim
                  try {
                    final matchingDistrict = districts.firstWhere((d) => d.id.toString() == dId);
                    districtName = isEn ? (matchingDistrict.nameEn ?? matchingDistrict.name) : matchingDistrict.name;
                  } catch(e) {
                    // Match not found
                  }
                }

                return Opacity(
                  opacity: isPast ? 0.42 : 1.0,
                  child: GestureDetector(
                    onTap: () => _showEnlargedImage(context, imgUrl),
                    child: Container(
                    width: 220,
                    margin: const EdgeInsets.only(right: 15),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.03),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.06)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Hero(
                            tag: 'home_event_$index',
                            child: CachedNetworkImage(
                              imageUrl: imgUrl,
                              fit: BoxFit.cover,
                              placeholder: (c, u) => Container(color: Colors.white.withOpacity(0.05)),
                              errorWidget: (c, u, e) => const Icon(Icons.broken_image, color: Colors.white12),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 15,
                            left: 15,
                            right: 15,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  ev['title'] ?? "",
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, shadows: [Shadow(color: Colors.black, blurRadius: 8)]),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const FaIcon(FontAwesomeIcons.calendarDay, color: Color(0xFF06b6d4), size: 10),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat('dd.MM.yyyy').format(date),
                                      style: const TextStyle(color: Color(0xFF06b6d4), fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(width: 10),
                                    const FaIcon(FontAwesomeIcons.locationDot, color: Color(0xFF10b981), size: 10),
                                    const SizedBox(width: 4),
                                    Text(
                                      districtName.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase(),
                                      style: const TextStyle(color: Color(0xFF10b981), fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                  ],
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
              },
            ),
            // Scroll Indicator
            Positioned(
              right: 10,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle, border: Border.all(color: Colors.white24)),
                  child: const Icon(Icons.chevron_right, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEnlargedImage(BuildContext context, String imageUrl) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.black.withOpacity(0.9),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (c, a1, a2) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(icon: const Icon(Icons.close, color: Colors.white), onPressed: () => Navigator.pop(context)),
          ),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 0.5,
              maxScale: 4.0,
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                width: double.infinity,
                placeholder: (c, u) => Container(color: Colors.white.withOpacity(0.05)),
                errorWidget: (c, u, e) => const Icon(Icons.broken_image, color: Colors.white12),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildFooterLink(String label, String path) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse("${AppConfig.baseMediaUrl}$path")),
      child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 9, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildFooterDot() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Text("•", style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 10)),
    );
  }

  Widget _buildNotificationBell(BuildContext context) {
    return Consumer<NotificationProvider>(
      builder: (context, provider, child) {
        return GestureDetector(
          onTap: () {
            Navigator.push(context, CupertinoPageRoute(builder: (_) => const NotificationScreen()));
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const FaIcon(FontAwesomeIcons.solidBell, color: Colors.white, size: 18),
              ),
              if (provider.unreadCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${provider.unreadCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
