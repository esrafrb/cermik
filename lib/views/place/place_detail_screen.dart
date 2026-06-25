import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../widgets/web_360_view.dart';
import '../../widgets/panorama_viewer.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rotarehber_flutter/providers/district_provider.dart';
import '../../providers/language_provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../widgets/location_traffic_widget.dart';
import 'package:geolocator/geolocator.dart';
import '../../services/api_service.dart';
import '../../config/app_config.dart';
import '../../core/utils/translation_helper.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PlaceDetailScreen extends StatefulWidget {
  final int placeId;

  const PlaceDetailScreen({
    super.key,
    required this.placeId,
  });

  @override
  State<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends State<PlaceDetailScreen> {
  bool _isDescExpanded = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<DistrictProvider>().fetchPlaceDetail(widget.placeId);
    });
    _trackUsage();
  }

  Future<void> _trackUsage() async {
    // Sadece Pasif Yakınlık Kontrolü (Görünüm sayacı mekanlar için backend'de yok, sadece işletmeler için var)
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      
      final prefs = await SharedPreferences.getInstance();
      final String cacheKey = 'passive_v3_place_${widget.placeId}';
      final int lastTime = prefs.getInt(cacheKey) ?? 0;
      final int now = DateTime.now().millisecondsSinceEpoch;

      if (now - lastTime > 86400000) { // 24 saat cooldown
        // İlçe kimliğini bilmediğimiz için provider yüklendiğinde districtId oradan alınabilir,
        // ancak track_proximity'e district_id'yi 0 yollayarak (veya api de district_id'ye varsayılan atayarak) çözebiliriz.
        // Aslında api de `district_id` zorunlu olduğu için 1 varsayabiliriz. (Web'deki gibi)
        ApiService.trackProximity(
          targetId: widget.placeId,
          targetType: 'place',
          districtId: 1, // Varsayılan, backend bunu place ID üzerinden düzeltebilir ama id yeterli.
          lat: pos.latitude,
          lng: pos.longitude,
        );
        prefs.setInt(cacheKey, now);
      }
    } catch (e) {
      // Sessizce hatayı yoksay
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isEn = context.watch<LanguageProvider>().isEn;
    final provider = context.watch<DistrictProvider>();
    final place = provider.currentPlace;

    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: provider.isLoadingPlaceDetail
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : place == null
              ? _buildErrorState(isEn)
              : _buildDetailContent(context, isEn, place),
    );
  }

  Widget _buildErrorState(bool isEn) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(FontAwesomeIcons.circleExclamation, size: 60, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 20),
          Text(isEn ? "Place not found" : "Mekan bulunamadı", style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.cyan, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            onPressed: () => Navigator.pop(context),
            child: Text(isEn ? "Go Back" : "Geri Dön"),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailContent(BuildContext context, bool isEn, dynamic place) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // App Bar with Hero Image
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          backgroundColor: const Color(0xFF0f172a),
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              _toTurkishUpperCase(isEn ? (place.nameEn ?? place.name) : place.name),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1, shadows: [Shadow(color: Colors.black87, blurRadius: 10)]),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                if (place.panorama360 != null && place.panorama360!.isNotEmpty) ...[
                  Web360View(
                    panoramaUrl: place.panorama360!,
                    isEmbedded: true,
                  )
                ] else ...[
                  if (place.imageMain != null && place.imageMain!.isNotEmpty)
                    Image.network(
                      AppConfig.imageUrl(place.imageMain!),
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(color: const Color(0xFF1e293b), child: const Icon(Icons.image, color: Colors.white10)),
                    )
                  else
                    Container(color: const Color(0xFF1e293b), child: const Icon(Icons.image, color: Colors.white10)),
                ],
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black38, Colors.transparent, Colors.black.withOpacity(0.9)],
                    ),
                  ),
                ),
                if (place.panorama360 != null && place.panorama360!.isNotEmpty)
                  Positioned(
                    bottom: 60,
                    right: 20,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(builder: (context) => PanoramaViewerScreen(url: place.panorama360!))
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.cyanAccent,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.4), blurRadius: 10)],
                        ),
                        child: Row(
                          children: [
                            const FaIcon(FontAwesomeIcons.vrCardboard, color: Colors.black, size: 14),
                            const SizedBox(width: 8),
                            Text(
                              isEn ? "360° VR VIEW" : "360° VR GÖRÜNÜM",
                              style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([


              // === KAPLICA (THERMAL) PREMIUM UI: Beneficial for Diseases ===
              if ((place.category.toLowerCase() == 'hotspring' || 
                   place.category.toLowerCase() == 'thermal-places' ||
                   place.category.toLowerCase() == 'kaplica' ||
                   place.category.toLowerCase() == 'thermal') &&
                  place.hastaliklar != null &&
                  place.hastaliklar!.isNotEmpty) ...[
                _buildSectionTitle(isEn 
                  ? ((place.headingHastaliklarEn != null && place.headingHastaliklarEn!.isNotEmpty) ? place.headingHastaliklarEn! : "DISEASES IT IS GOOD FOR") 
                  : ((place.headingHastaliklarTr != null && place.headingHastaliklarTr!.isNotEmpty) ? place.headingHastaliklarTr! : "İYİ GELDİĞİ HASTALIKLAR")
                ),
                const SizedBox(height: 15),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFef4444).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFef4444).withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tıbbi endikasyonlar başlığı kaldırıldı
                      Padding(
                        padding: const EdgeInsets.all(15),
                        child: Text(
                          isEn ? (place.hastaliklarEn ?? place.hastaliklar ?? "") : (place.hastaliklar ?? ""),
                          style: const TextStyle(color: Color(0xFFfecaca), fontSize: 14, height: 1.6),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],

              // About Section
              _buildSectionTitle(isEn ? "About" : "Hakkında"),
              const SizedBox(height: 12),
              AnimatedCrossFade(
                firstChild: Text(
                  isEn ? (place.descriptionEn ?? place.description ?? "") : (place.description ?? ""),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15, height: 1.6, fontWeight: FontWeight.w400),
                ),
                secondChild: Text(
                  isEn ? (place.descriptionEn ?? place.description ?? "") : (place.description ?? ""),
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15, height: 1.6, fontWeight: FontWeight.w400),
                ),
                crossFadeState: _isDescExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 300),
              ),
              if ((isEn ? (place.descriptionEn ?? place.description ?? "") : (place.description ?? "")).length > 150)
                Align(
                  alignment: Alignment.center,
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isDescExpanded = !_isDescExpanded;
                      });
                    },
                    icon: Icon(_isDescExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: Colors.cyanAccent, size: 16),
                    label: Text(_isDescExpanded ? (isEn ? "SHOW LESS" : "DARALT") : (isEn ? "READ MORE" : "TAMAMINI GÖSTER"), style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              const SizedBox(height: 20),

              // Interaction Buttons
              Row(
                children: [
                  Expanded(
                    child: _buildGradientButton(
                      label: isEn ? "GET DIRECTIONS" : "YOL TARİFİ AL",
                      icon: FontAwesomeIcons.locationArrow,
                      onTap: () => _openMap(place.lat, place.lng),
                      primary: true,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildGradientButton(
                      label: isEn ? "SHARE" : "PAYLAŞ",
                      icon: FontAwesomeIcons.shareNodes,
                      onTap: () {
                        final String shareUrl = '${AppConfig.webBaseUrl}/place_detail.php?id=${place.id}';
                        final String placeName = isEn ? (place.nameEn ?? place.name) : place.name;
                        final String shareText = isEn 
                            ? "Check out this amazing place on RotaRehber: $placeName\n\n$shareUrl"
                            : "Bu harika mekanı RotaRehber'de keşfet: $placeName\n\n$shareUrl";
                        
                        Share.share(shareText);
                      },
                      primary: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              
              // Trafik ve Yoğunluk (WebView tabanlı)
              _buildLocationAndStats(place, isEn),
              const SizedBox(height: 30),
              const SizedBox(height: 30),


              // Gallery
              if (place.imageGallery != null && place.imageGallery.isNotEmpty) ...[
                _buildSectionTitle(isEn ? "Gallery" : "Fotoğraf Galerisi"),
                const SizedBox(height: 15),
                SizedBox(
                  height: 160,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: place.imageGallery.length,
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () {}, // Optional: Open Fullscreen
                        child: Container(
                          margin: const EdgeInsets.only(right: 15),
                          width: 240,
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.05))),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.network(
                              AppConfig.imageUrl(place.imageGallery[index]),
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => Container(color: const Color(0xFF1e293b), child: const Icon(Icons.image, color: Colors.white10)),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 30),
              ],


            ]),
          ),
        ),
      ],
    );
  }

  String _toTurkishUpperCase(String text) {
    return text
        .replaceAll('i', 'İ')
        .replaceAll('ı', 'I')
        .replaceAll('ğ', 'Ğ')
        .replaceAll('ü', 'Ü')
        .replaceAll('ş', 'Ş')
        .replaceAll('ö', 'Ö')
        .replaceAll('ç', 'Ç')
        .toUpperCase();
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      _toTurkishUpperCase(title),
      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2),
    );
  }

  Widget _buildGradientButton({required String label, required dynamic icon, required VoidCallback onTap, bool primary = true}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: primary 
            ? const LinearGradient(colors: [Color(0xFF06b6d4), Color(0xFF0891b2)])
            : LinearGradient(colors: [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.1)]),
          borderRadius: BorderRadius.circular(18),
          border: primary ? null : Border.all(color: Colors.white10),
          boxShadow: primary ? [BoxShadow(color: Colors.cyan.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(icon, color: primary ? Colors.white : Colors.white70, size: 16),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: primary ? Colors.white : Colors.white, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  String _getCategoryLabel(String category, bool isEn) {
    return TranslationHelper.getCategoryLabel(category, isEn);
  }

  Widget _buildGlassCard({required Widget child, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 20),
          const SizedBox(width: 15),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildStatBox(String count, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(count, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildLocationAndStats(dynamic place, bool isEn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (place.lat != null && place.lng != null)
          LocationTrafficWidget(
            lat: place.lat!,
            lng: place.lng!,
            title: isEn ? (place.nameEn ?? place.name) : place.name,
            isEn: isEn,
          ),
        
        const SizedBox(height: 20),

        // Check-in Button
        InkWell(
          onTap: () => _handleCheckIn(context, place.id, "place", place.districtId),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF00c9ff), Color(0xFF92fe9d)]),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const FaIcon(FontAwesomeIcons.locationCrosshairs, color: Colors.black, size: 16),
                const SizedBox(width: 8),
                Text(isEn ? "I am Here! (Check-in)" : "Ben Buradayım! (Check-in)", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14)),
              ],
            ),
          ),
        ),

      ],
    );
  }

  Future<void> _launchURL(String urlString) async {
    final bool isEn = context.read<LanguageProvider>().isEn;
    const String trErr = "Bağlantı açılamıyor";
    const String enErr = "Could not open link";
    final Uri url = Uri.parse(!urlString.startsWith('http') ? 'https://$urlString' : urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEn ? enErr : trErr)),
        );
      }
    }
  }

  Future<void> _openMap(double? lat, double? lng) async {
    if (lat == null || lng == null) return;
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _handleCheckIn(BuildContext context, int targetId, String type, int districtId) async {
    final bool isEn = context.read<LanguageProvider>().isEn;

    // Giriş Kontrolü
    if (!ApiService.isAuthenticated) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isEn ? "Please login to check-in." : "Check-in yapmak için lütfen giriş yapın."),
          backgroundColor: Colors.orangeAccent,
        )
      );
      return;
    }

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEn ? "Please turn on your GPS." : "Lütfen cihazınızın konum (GPS) servisini açın.")));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEn ? "Location permissions denied." : "Konum izinleri reddedildi.")));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEn ? "Location permissions permanently denied." : "Konum izni kalıcı olarak reddedildi, ayarlardan açmalısınız.")));
      return;
    }

    try {
      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
      final res = await ApiService.checkIn(
        targetId: targetId,
        targetType: type,
        districtId: districtId,
        lat: pos.latitude,
        lng: pos.longitude,
      );

      final String defaultMsg = res['status'] == 'success' ? (isEn ? "Check-in Successful!" : "Check-in Başarılı!") : (isEn ? "An error occurred" : "Bir hata oluştu");
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message'] ?? defaultMsg),
        backgroundColor: res['status'] == 'success' ? Colors.green : Colors.redAccent,
      ));

    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEn ? "Server connection error." : "Sunucu bağlantı hatası.")) );
    }
  }
}
