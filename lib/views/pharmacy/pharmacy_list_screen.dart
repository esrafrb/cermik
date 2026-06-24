import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rotarehber_flutter/providers/district_provider.dart';
import '../../providers/language_provider.dart';
import '../../widgets/district_drawer.dart';
import '../../widgets/panorama_viewer.dart';
import 'hospital_detail_screen.dart';
import '../../config/app_config.dart';

class PharmacyListScreen extends StatefulWidget {
  final String districtId;
  final String districtName;

  const PharmacyListScreen({
    super.key,
    required this.districtId,
    required this.districtName,
  });

  @override
  State<PharmacyListScreen> createState() => _PharmacyListScreenState();
}

class _PharmacyListScreenState extends State<PharmacyListScreen> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(_pulseController);

    Future.microtask(() =>
      context.read<DistrictProvider>().fetchPharmacies(widget.districtId)
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isEn = context.watch<LanguageProvider>().isEn;
    final provider = context.watch<DistrictProvider>();
    final settings = provider.districtDetails['settings'] ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEn ? "PHARMACIES" : "ECZANELER", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white)),
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
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 28),
              onPressed: () => Scaffold.of(context).openEndDrawer(),
            ),
          ),
        ],
      ),
      endDrawer: DistrictDrawer(
        districtId: widget.districtId,
        districtSlug: widget.districtName.toLowerCase(),
        mayorName: provider.mayorInfo['name']?.toString() ?? settings['mayor_name']?.toString() ?? "Belediye Başkanı",
        mayorTitle: isEn 
           ? (provider.mayorInfo['title_en'] ?? settings['mayor_title_en']?.toString() ?? "Mayor")
           : (provider.mayorInfo['title'] ?? settings['mayor_title']?.toString() ?? "Başkan"),
        mayorImageUrl: provider.mayorInfo['image']?.toString() ?? settings['mayor_image']?.toString() ?? "",
        address: provider.contactInfo['address']?.toString() ?? settings['site_address']?.toString() ?? "Adres Bilgisi",
        phone: provider.contactInfo['phone']?.toString() ?? settings['site_phone']?.toString() ?? "Telefon No",
        email: provider.contactInfo['email']?.toString() ?? settings['site_email']?.toString() ?? "Email Adresi",
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
          
          if (provider.isLoadingPharmacies)
            const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          else
            _buildPharmacyList(provider, isEn),
        ],
      ),
    );
  }

  Widget _buildPharmacyList(DistrictProvider provider, bool isEn) {
    final duty = provider.dutyPharmacies;
    final normal = provider.pharmacies;
    final hospitals = provider.hospitals;

    if (duty.isEmpty && hospitals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_pharmacy_outlined, color: Colors.white12, size: 80),
            const SizedBox(height: 20),
            Text(isEn ? "No results found" : "Sonuç bulunamadı", style: const TextStyle(color: Colors.white38, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 100, 20, 40),
      children: [
        // === ECZANE ÖZEL: Kırmızı Nöbetçi Banner ===
        if (duty.isNotEmpty) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(25),
            margin: const EdgeInsets.only(bottom: 25),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFe53e3e), Color(0xFFb83232)],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFe53e3e).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              children: [
                Text(
                  isEn ? "ON DUTY TODAY" : "${widget.districtName} BUGÜN NÖBETÇİ",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  duty[0].name.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    shadows: [Shadow(color: Colors.black26, blurRadius: 10)],
                  ),
                ),
                const SizedBox(height: 12),
                // Telefon göster + tıklanabilir ARA butonu
                _buildDutyPhoneButton(duty[0].phone, isEn),
              ],
            ),
          ),
          _buildSectionTitle(isEn ? "ON DUTY NOW" : "ŞU AN NÖBETÇİ"),
          const SizedBox(height: 15),
          ...duty.map((p) => _buildPharmacyCard(p, isDuty: true, isEn: isEn)).toList(),
          const SizedBox(height: 35),
        ],

        // === HASTANELER SECTION ===
        if (hospitals.isNotEmpty) ...[
          _buildSectionTitle(isEn ? "HOSPITALS" : "HASTANELER"),
          const SizedBox(height: 15),
          ...hospitals.map((h) => _buildHospitalCard(h, isEn)).toList(),
        ],
      ],
    );
  }

  /// Büyük kırmızı banner içindeki telefon + ARA butonu
  Widget _buildDutyPhoneButton(String? phone, bool isEn) {
    final cleanPhone = _cleanPhone(phone);
    final bool hasPhone = cleanPhone.isNotEmpty;

    return GestureDetector(
      onTap: hasPhone ? () => _launchCaller(cleanPhone) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const FaIcon(FontAwesomeIcons.phone, color: Colors.white, size: 12),
            const SizedBox(width: 10),
            Text(
              hasPhone ? cleanPhone : (isEn ? "No phone" : "Telefon yok"),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (hasPhone) ...[
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isEn ? 'CALL' : 'ARA',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: Colors.cyanAccent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
      ],
    );
  }

  Widget _buildPharmacyCard(dynamic p, {required bool isDuty, required bool isEn}) {
    final cleanPhone = _cleanPhone(p.phone);
    final bool hasPhone = cleanPhone.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: isDuty ? Colors.redAccent.withOpacity(0.08) : Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: isDuty ? Colors.redAccent.withOpacity(0.3) : Colors.white.withOpacity(0.08)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900))),
                    if (isDuty)
                      FadeTransition(
                        opacity: _pulseAnimation,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(8)),
                          child: Text(isEn ? "LIVE" : "CANLI", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 5),
                Container(
                  height: 2, width: 40,
                  decoration: BoxDecoration(color: Colors.cyanAccent, borderRadius: BorderRadius.circular(1)),
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on_outlined, color: Colors.cyanAccent, size: 16),
                    const SizedBox(width: 8),
                    Expanded(child: Text(p.address ?? "", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.4))),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    // ARA butonu — sadece geçerli telefon varsa aktif
                    Expanded(
                      child: _buildCardAction(
                        icon: FontAwesomeIcons.phone,
                        label: isEn ? "CALL" : "ARA",
                        color: hasPhone ? Colors.cyanAccent : Colors.white24,
                        onTap: hasPhone ? () => _launchCaller(cleanPhone) : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCardAction(
                        icon: FontAwesomeIcons.mapLocationDot,
                        label: isEn ? "MAP" : "HARİTA",
                        color: Colors.cyanAccent,
                        onTap: () => _launchMaps(p.lat, p.lng, p.address),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHospitalCard(dynamic h, bool isEn) {
    bool hasPanorama = h.panorama360 != null && h.panorama360 != "";
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(builder: (context) => HospitalDetailScreen(hospital: h)),
      ),
      child: Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (h.imageMain != null && h.imageMain != "")
                SizedBox(
                  height: 140,
                  width: double.infinity,
                  child: Image.network(
                    AppConfig.imageUrl(h.imageMain),
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Container(color: Colors.black26),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      h.name,
                      style: const TextStyle(color: Colors.cyanAccent, fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on_outlined, color: Colors.white38, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(h.address ?? "", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.4))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        if (hasPanorama) ...[
                          Expanded(
                            child: _buildCardAction(
                              icon: FontAwesomeIcons.vrCardboard,
                              label: isEn ? "PANO 360" : "PANO 360",
                              color: Colors.orangeAccent,
                              onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => PanoramaViewerScreen(url: h.panorama360!))),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          child: _buildCardAction(
                            icon: FontAwesomeIcons.mapLocationDot,
                            label: isEn ? "MAP" : "HARİTA",
                            color: Colors.cyanAccent,
                            onTap: () => _launchMaps(h.lat, h.lng, h.address),
                          ),
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
  }

  Widget _buildCardAction({required dynamic icon, required String label, required Color color, required VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, color: color, size: 14),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  /// Telefon numarasını temizler. "No Phone" veya boş ise "" döner.
  String _cleanPhone(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    // Scraper "No Phone" kaydediyorsa temizle
    if (raw.toLowerCase().contains('no phone') || raw.toLowerCase().contains('telefon yok')) return '';
    final cleaned = raw.replaceAll(RegExp(r'[^\d+]'), '');
    return cleaned;
  }

  void _launchCaller(String cleanPhone) async {
    if (cleanPhone.isEmpty) return;
    final Uri launchUri = Uri(scheme: 'tel', path: cleanPhone);
    // canLaunchUrl bazı Android cihazlarda false dönebiliyor,
    // doğrudan launchUrl ile dene
    try {
      await launchUrl(launchUri);
    } catch (_) {
      if (await canLaunchUrl(launchUri)) {
        await launchUrl(launchUri);
      }
    }
  }

  void _launchMaps(dynamic lat, dynamic lng, String? address) async {
    String url = "";
    if (lat != null && lng != null) {
      url = "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    } else if (address != null) {
      url = "https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}";
    }
    if (url.isNotEmpty && await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }
}
