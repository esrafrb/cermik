import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../../providers/language_provider.dart';
import 'package:rotarehber_flutter/providers/district_provider.dart';
import '../../models/business_model.dart';
import '../../config/app_config.dart';
import '../../services/api_service.dart';
import 'package:intl/intl.dart';
import '../../core/utils/translation_helper.dart';
import '../../widgets/web_360_view.dart';
import '../../widgets/panorama_viewer.dart';
import '../../widgets/location_traffic_widget.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/cart_provider.dart';
import '../cart/cart_screen.dart';
import '../../services/auth_service.dart';
import '../../screens/login_screen.dart';

class BusinessDetailScreen extends StatefulWidget {
  final String districtId;
  final String businessId;
  final String businessName;

  const BusinessDetailScreen({
    super.key,
    required this.districtId,
    required this.businessId,
    required this.businessName,
  });

  @override
  State<BusinessDetailScreen> createState() => _BusinessDetailScreenState();
}

class _BusinessDetailScreenState extends State<BusinessDetailScreen> {
  bool _isExpanded = false;
  int _selectedCategoryId = 0; // 0 means 'Tüm Ürünler' or Uncategorized
  final Map<int, GlobalKey> _categoryKeys = {};

  void _scrollToCategory(int id) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _categoryKeys[id];
      if (key != null && key.currentContext != null) {
        Scrollable.ensureVisible(
          key.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.5,
        );
      }
    });
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
      context.read<DistrictProvider>().fetchBusinessDetail(widget.businessId)
    );
    _trackUsage();
  }

  Future<void> _trackUsage() async {
    int bId = int.tryParse(widget.businessId) ?? 0;
    if (bId <= 0) return;

    // 24 saatlik cooldown kontrolü (hem view hem proximity için)
    final prefs = await SharedPreferences.getInstance();
    final String cacheKey = 'passive_v3_business_${widget.businessId}';
    final int lastTime = prefs.getInt(cacheKey) ?? 0;
    final int now = DateTime.now().millisecondsSinceEpoch;

    if (now - lastTime < 86400000) return; // 24 saat geçmediyse hiçbir şey yapma

    // 1. İşletme Görüntüleme Sinyali (24 saatte 1 kez)
    ApiService.trackAnalytics(targetId: bId, action: 'view');
    prefs.setInt(cacheKey, now); // Zaman damgasını hemen kaydet

    // 2. Pasif Yakınlık Kontrolü (Sadece GPS açıksa)
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

      Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

      int distId = int.tryParse(widget.districtId) ?? 1;
      ApiService.trackProximity(
        targetId: bId,
        targetType: 'business',
        districtId: distId,
        lat: pos.latitude,
        lng: pos.longitude,
      );
    } catch (e) {
      // Sessizce hatayı yoksay
    }
  }

  bool _checkIsOpen(Map<String, dynamic>? hours) {
    if (hours == null || hours.isEmpty) return true;
    // Türkiye saati (UTC+3)
    final now = DateTime.now().toUtc().add(const Duration(hours: 3));

    int parseTime(String t) {
      try {
        final p = t.split(':');
        if (p.length < 2) return 0;
        return (int.tryParse(p[0]) ?? 0) * 60 + (int.tryParse(p[1]) ?? 0);
      } catch (e) {
        return 0;
      }
    }

    // Format 1: Flat format — {"days": [1,2,3,4,5,6], "open": "09:00", "close": "22:00"}
    if (hours.containsKey('days') && hours.containsKey('open') && hours.containsKey('close')) {
      final List<int> whDays = (hours['days'] is List) 
          ? (hours['days'] as List).map((d) => int.tryParse(d.toString()) ?? 0).toList()
          : [];
      final int nowDay = now.weekday % 7; // DateTime.weekday: 1=Mon...7=Sun → %7: 1=Mon...0=Sun (PHP uyumu)
      final bool dayOpen = whDays.contains(nowDay);
      if (!dayOpen) return false;
      
      final openMin = parseTime(hours['open']?.toString() ?? '00:00');
      final closeMin = parseTime(hours['close']?.toString() ?? '00:00');
      final currentMin = now.hour * 60 + now.minute;
      
      if (closeMin < openMin) {
        return currentMin >= openMin || currentMin <= closeMin;
      }
      return currentMin >= openMin && currentMin < closeMin;
    }

    // Format 2: Per-day format — {"monday": {"open": "09:00", "close": "22:00"}, ...}
    final dayName = DateFormat('EEEE', 'en_US').format(now).toLowerCase();
    final dayData = hours[dayName];
    if (dayData == null || dayData['open'] == null || dayData['close'] == null) return true;
    if (dayData['is_closed'] == 1 || dayData['is_closed'] == true) return false;

    final openTime = parseTime(dayData['open']);
    final closeTime = parseTime(dayData['close']);
    final currentTime = now.hour * 60 + now.minute;
    
    if (closeTime < openTime) {
      return currentTime >= openTime || currentTime <= closeTime;
    }
    return currentTime >= openTime && currentTime <= closeTime;
  }

  @override
  Widget build(BuildContext context) {
    bool isEn = context.watch<LanguageProvider>().isEn;
    final provider = context.watch<DistrictProvider>();
    final biz = provider.currentBusiness;

    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // Geri butonu rengi
        actions: [
          if (biz != null && biz.hasOrder)
            Consumer<CartProvider>(
              builder: (context, cart, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CircleAvatar(
                        backgroundColor: Colors.black45,
                        child: IconButton(
                          icon: const Icon(Icons.shopping_basket_outlined, color: Colors.cyanAccent, size: 20),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const CartScreen()));
                          },
                        ),
                      ),
                    ),
                    if (cart.items.isNotEmpty)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                          child: Text(
                            cart.items.length.toString(),
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
        ],
      ),
      body: provider.isLoadingBusinessDetail
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : biz == null
              ? Center(child: Text(isEn ? "Not found" : "Bulunamadı", style: const TextStyle(color: Colors.white70)))
              : _buildMainContent(context, isEn, biz),
    );
  }

  Widget _buildMainContent(BuildContext context, bool isEn, Business biz) {
    String imagePath = (biz.imageMain != null && (biz.imageMain?.isNotEmpty ?? false))
        ? AppConfig.imageUrl(biz.imageMain ?? "")
        : (biz.image != null && (biz.image?.isNotEmpty ?? false) 
            ? AppConfig.imageUrl(biz.image ?? "") 
            : (biz.imageGallery.isNotEmpty ? AppConfig.imageUrl(biz.imageGallery.first) : "https://via.placeholder.com/800x450"));

    return Stack(
      children: [
        // --- Sticky Background Image ---
        Positioned(
          top: 0, left: 0, right: 0,
          height: MediaQuery.of(context).size.height * 0.45,
          child: Container(
            color: const Color(0xFF1e293b),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Static Background Image with Hero
                if (biz.panorama360 == null || biz.panorama360!.isEmpty)
                  Hero(
                    tag: "biz_img_${biz.id}",
                    child: imagePath.isEmpty 
                      ? const Icon(Icons.image, color: Colors.white10)
                      : CachedNetworkImage(imageUrl: imagePath, fit: BoxFit.cover, errorWidget: (c,u,e) => const Icon(Icons.image, color: Colors.white10)),
                  ),
                // Native Panorama Overlay (PRIORITY 1: 360)
                if (biz.panorama360 != null && (biz.panorama360?.trim().isNotEmpty ?? false))
                  Web360View(
                    panoramaUrl: biz.panorama360!,
                    isEmbedded: true,
                  ),
                // Gradient Overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.black26, const Color(0xFF0f172a)],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // --- Scrollable Content ---
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.35),
              
              // Premium Card
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1e293b).withOpacity(0.85),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    padding: const EdgeInsets.all(25),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStatusPill(_checkIsOpen(biz.workingHoursData), isEn),
                            if (biz.panorama360 != null && (biz.panorama360?.isNotEmpty ?? false))
                              _buildPanoramaBadge(context, biz.panorama360 ?? ""),
                          ],
                        ),
                        const SizedBox(height: 20),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                isEn ? (biz.nameEn ?? biz.name) : biz.name, 
                                style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(TranslationHelper.getCategoryLabel(biz.category, isEn), style: const TextStyle(color: Colors.cyanAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
                        
                        const SizedBox(height: 30),

                        _buildActionRow(biz, isEn),
                        const SizedBox(height: 25),

                        // --- Statistics Card (1:1 with Web) ---
                        _buildStatsCard(biz.stats, isEn),
                        const SizedBox(height: 35),

                        _buildSectionHeader(isEn ? "ABOUT" : "HAKKINDA"),
                        const SizedBox(height: 12),
                        _buildAboutSection(isEn ? (biz.descriptionEn ?? biz.description ?? "") : (biz.description ?? ""), isEn),
                        
                        if (biz.hasOrder && biz.orderLink != null && (biz.orderLink?.isNotEmpty ?? false))
                          _buildInlineOrderButton(biz.orderLink ?? "", isEn),
                          
                        const SizedBox(height: 35),

                        // Çalışma Saatleri listesi UI'dan gizlendi, ancak arka planda açık/kapalı durumu için kullanılıyor.
                        /*
                        if (biz.workingHoursData != null && biz.workingHoursData!.isNotEmpty) ...[
                          _buildSectionHeader(isEn ? "WORKING HOURS" : "ÇALIŞMA SAATLERİ"),
                          const SizedBox(height: 15),
                          _buildWorkingHoursList(biz.workingHoursData!, isEn),
                          const SizedBox(height: 35),
                        ],
                        */

                        // HİZMETLER / MENÜ
                        if (biz.products.isNotEmpty || biz.categories.isNotEmpty || biz.uncategorizedProducts.isNotEmpty) ...[
                          _buildSectionHeader(
                            biz.category.toLowerCase() == 'restaurant'
                              ? (isEn ? "MENU" : "MENÜ")
                              : (isEn ? "SERVICES / ROOMS" : "HİZMETLER / ODA TÜRLERİ")
                          ),
                          const SizedBox(height: 15),
                          _buildMenuSection(biz, isEn),
                          const SizedBox(height: 35),
                        ],

                        // OTEL BİLGİLERİ — web ile aynı: yalnızca Hotel kategorisi
                        if ((biz.category == 'Hotel' || biz.category.toLowerCase() == 'otel') &&
                            (biz.hotelInfo?.isNotEmpty ?? false)) ...[
                          _buildSectionHeader(isEn ? "HOTEL / PENSION INFO" : "OTEL / PANSİYON BİLGİLERİ"),
                          const SizedBox(height: 15),
                          _buildHotelInfoCards(biz.hotelInfo ?? {}, isEn),
                          const SizedBox(height: 35),
                        ],

                        if (biz.imageGallery.isNotEmpty) ...[
                          _buildSectionHeader(isEn ? "GALLERY" : "FOTOĞRAF GALERİSİ"),
                          const SizedBox(height: 15),
                          _buildGalleryList(biz.imageGallery),
                          const SizedBox(height: 35),
                        ],

                        if (biz.qrCodePath != null && (biz.qrCodePath?.isNotEmpty ?? false)) ...[
                          _buildSectionHeader(isEn ? "MEKAN QR KODU" : "MEKAN QR KODU"),
                          const SizedBox(height: 20),
                          _buildQRCode(biz.qrCodePath ?? ""),
                          const SizedBox(height: 50),
                        ],
                        
                        _buildTrafficAndCheckIn(biz, isEn),
                        const SizedBox(height: 120), 
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2));
  }

  Widget _buildStatusPill(bool isOpen, bool isEn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isOpen ? Colors.greenAccent.withOpacity(0.12) : Colors.redAccent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isOpen ? Colors.greenAccent.withOpacity(0.3) : Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, color: isOpen ? Colors.greenAccent : Colors.redAccent, size: 8),
          const SizedBox(width: 8),
          Text(
            isOpen ? (isEn ? "OPEN NOW" : "ŞU AN AÇIK") : (isEn ? "CLOSED" : "ŞU AN KAPALI"),
            style: TextStyle(color: isOpen ? Colors.greenAccent : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(Business biz, bool isEn) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionItem(FontAwesomeIcons.locationArrow, isEn ? "Map" : "Harita", () => _openMap(biz.lat, biz.lng)),
        _buildActionItem(FontAwesomeIcons.phone, isEn ? "Call" : "Ara", () => _callBusiness(biz.phone)),
        _buildActionItem(FontAwesomeIcons.shareNodes, isEn ? "Share" : "Paylaş", () {
          final String shareUrl = '${AppConfig.webBaseUrl}/business_detail.php?id=${biz.id}';
          final String businessName = isEn ? (biz.nameEn ?? biz.name) : biz.name;
          final String shareText = isEn 
              ? "Check out this amazing business on RotaRehber: $businessName\n\n$shareUrl"
              : "Bu harika işletmeyi RotaRehber'de keşfet: $businessName\n\n$shareUrl";
          
          Share.share(shareText);
        }),
      ],
    );
  }

  Widget _buildActionItem(dynamic icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle, border: Border.all(color: Colors.white12)),
            child: FaIcon(icon, color: Colors.cyanAccent, size: 20),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildAboutSection(String desc, bool isEn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          desc,
          maxLines: _isExpanded ? null : 4,
          overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.6),
        ),
        if (desc.length > 200)
          GestureDetector(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(
                _isExpanded ? (isEn ? "Show less" : "Daha az") : (isEn ? "Read more" : "Devamını oku"),
                style: const TextStyle(color: Colors.cyanAccent, fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWorkingHoursList(Map<String, dynamic> hours, bool isEn) {
    final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
    final dayNamesTr = {
      'monday': 'Pazartesi',
      'tuesday': 'Salı',
      'wednesday': 'Çarşamba',
      'thursday': 'Perşembe',
      'friday': 'Cuma',
      'saturday': 'Cumartesi',
      'sunday': 'Pazar',
    };
    final dayNamesEn = {
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
      'saturday': 'Saturday',
      'sunday': 'Sunday',
    };

    final today = DateFormat('EEEE', 'en_US').format(DateTime.now().toUtc().add(const Duration(hours: 3))).toLowerCase();

    return Column(
      children: days.map((day) {
        final data = hours[day] ?? {};
        final bool isToday = day == today;
        final displayName = isEn ? dayNamesEn[day] : dayNamesTr[day];
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Text(displayName?.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase() ?? day.substring(0, 3).replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase(), style: TextStyle(color: isToday ? Colors.cyanAccent : Colors.white12, fontSize: 13, fontWeight: FontWeight.w900)),
              const SizedBox(width: 15),
              Expanded(child: Container(height: 1, color: Colors.white.withOpacity(0.05))),
              const SizedBox(width: 15),
              Text(
                (data['is_closed'] == 1 || data['is_closed'] == true) ? (isEn ? "Closed" : "Kapalı") : "${data['open']} - ${data['close']}",
                style: TextStyle(color: isToday ? Colors.white : Colors.white10, fontSize: 13, fontWeight: isToday ? FontWeight.bold : FontWeight.normal),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Web ile birebir: hotel_info key-value çiftlerini kart olarak göster
  Widget _buildHotelInfoCards(Map<String, dynamic> facilities, bool isEn) {
    // Web PHP icon_map ile uyumlu ikon eşleme (Türkçe key adlarına göre)
    IconData _iconFor(String key) {
      final k = key.toLowerCase();
      if (k.contains('oda'))       return Icons.door_front_door_outlined;
      if (k.contains('havuz'))     return Icons.pool;
      if (k.contains('wi-fi') || k.contains('wifi') || k.contains('internet')) return Icons.wifi;
      if (k.contains('kahvaltı') || k.contains('kahvalti')) return Icons.free_breakfast_outlined;
      if (k.contains('öğle') || k.contains('ogle'))  return Icons.wb_sunny_outlined;
      if (k.contains('akşam') || k.contains('aksam')) return Icons.nights_stay_outlined;
      if (k.contains('klima') || k.contains('isıtma')) return Icons.ac_unit;
      if (k.contains('otopark') || k.contains('park')) return Icons.local_parking;
      if (k.contains('kasa') || k.contains('safe'))   return Icons.lock_outline;
      if (k.contains('resepsiyon') || k.contains('reception')) return Icons.support_agent;
      if (k.contains('spa') || k.contains('thermal') || k.contains('termal')) return Icons.spa_outlined;
      if (k.contains('engelli'))   return Icons.accessible;
      if (k.contains('çamaşır'))   return Icons.local_laundry_service;
      return Icons.check_circle_outline;
    }

    final entries = facilities.entries
        .where((e) => e.value != null && e.value.toString().isNotEmpty)
        .toList();

    if (entries.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: entries.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 2.4,
      ),
      itemBuilder: (context, index) {
        final label = entries[index].key;
        final value = entries[index].value.toString();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Row(
            children: [
              Icon(_iconFor(label), color: Colors.cyanAccent, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Emoji ve ASCII dışı bozuk karakterleri temizle
  String _cleanText(String? raw) {
    if (raw == null) return '';
    return raw
        .replaceAll(RegExp(r'[\uD800-\uDFFF]'), '')
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '')
        .replaceAll(RegExp(r'[^\u0000-\uFFFF]', unicode: true), '')
        // Bozuk multi-byte karakterleri temizle (├£ → Ü gibi)
        .replaceAll(RegExp(r'[├╠╚╔╦╣╗╝╜╛┐└┴┬├─┼╞╟╚╔╩╦╠═╬╧╨╤╥╙╘╒╓╫╪]'), '')
        .replaceAll(RegExp(r'[¯¡¼½¾°±²³µ¶·¸¹º»¿÷×]'), '')
        .replaceAll(RegExp(r'[òóôõö÷øùúûüý]'), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  /// Açıklamanın satır listesi (hizmet listesi) mi yoksa düz metin mi olduğunu tespit et
  List<String> _parseAmenities(String desc) {
    final lines = desc.split(RegExp(r'[\r\n]+')).map((l) {
      return _cleanText(l);
    }).where((l) => l.length >= 2).toList(); // En az 2 char uzun satırlar
    return lines;
  }

  Widget _buildMenuSection(Business biz, bool isEn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (biz.categories.isNotEmpty) _buildCategoryChips(biz.categories, isEn),
        const SizedBox(height: 15),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: (details) {
            if (details.primaryVelocity == null) return;
            List<int> catIds = [0, ...biz.categories.map((c) => c.id)];
            int currentIndex = catIds.indexOf(_selectedCategoryId);
            if (details.primaryVelocity! < -300) { // Swipe left -> next category
              if (currentIndex >= 0 && currentIndex < catIds.length - 1) {
                int nextId = catIds[currentIndex + 1];
                setState(() => _selectedCategoryId = nextId);
                _scrollToCategory(nextId);
              }
            } else if (details.primaryVelocity! > 300) { // Swipe right -> prev category
              if (currentIndex > 0) {
                int prevId = catIds[currentIndex - 1];
                setState(() => _selectedCategoryId = prevId);
                _scrollToCategory(prevId);
              }
            }
          },
          child: Stack(
            children: [
              // Invisible layer to force max height
              IgnorePointer(
                child: Visibility(
                  maintainState: true,
                  maintainAnimation: true,
                  maintainSize: true,
                  visible: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _getAllProducts(biz).map((p) => _buildProductItem(p, biz, isEn)).toList(),
                  ),
                ),
              ),
              // Visible layer with filtered items
              Container(
                width: double.infinity,
                color: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: _getFilteredProducts(biz).map((p) => _buildProductItem(p, biz, isEn)).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryChips(List<ProductCategory> categories, bool isEn) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _buildChip(isEn ? "All" : "Tüm Ürünler", 0),
          ...categories.map((c) => _buildChip(isEn ? (c.nameEn ?? c.name) : c.name, c.id)),
        ],
      ),
    );
  }

  Widget _buildChip(String label, int id) {
    if (!_categoryKeys.containsKey(id)) {
      _categoryKeys[id] = GlobalKey();
    }
    bool isSelected = _selectedCategoryId == id;
    return GestureDetector(
      key: _categoryKeys[id],
      onTap: () {
        setState(() => _selectedCategoryId = id);
        _scrollToCategory(id);
      },
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.cyanAccent : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.cyanAccent : Colors.white.withOpacity(0.1)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  List<Product> _getAllProducts(Business biz) {
    List<Product> all = [];
    for (var c in biz.categories) {
      all.addAll(c.products);
    }
    all.addAll(biz.uncategorizedProducts);
    // Fallback for old endpoints
    if (all.isEmpty && biz.products.isNotEmpty) {
      all.addAll(biz.products);
    }
    return all;
  }

  List<Product> _getFilteredProducts(Business biz) {
    if (_selectedCategoryId == 0) {
      return _getAllProducts(biz);
    } else {
      final category = biz.categories.firstWhere((c) => c.id == _selectedCategoryId, orElse: () => ProductCategory(id: 0, name: ''));
      return category.products;
    }
  }

  Widget _buildProductItem(Product p, Business biz, bool isEn) {
    final name = _cleanText(isEn ? (p.nameEn ?? p.name) : p.name);
    final rawDesc = (isEn ? (p.descriptionEn ?? p.description) : p.description) ?? '';
    final price = p.price?.toString() ?? '';
    final hasImage = p.image != null && (p.image as String).isNotEmpty;

    final amenities = _parseAmenities(rawDesc);
    final isAmenityList = amenities.length > 2;

    return GestureDetector(
      onTap: () {
        if (biz.hasOrder && biz.isActive) {
          _addToCart(p, biz, isEn);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasImage)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: AppConfig.imageUrl(p.image ?? ''),
                    width: 72, height: 72,
                    fit: BoxFit.cover,
                    errorWidget: (c, u, e) => Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.image_not_supported_outlined, color: Colors.white12, size: 24),
                    ),
                  ),
                ),
              if (hasImage) const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    if (price.isNotEmpty && price != '0' && price != '0.00')
                      Text('$price ₺', style: const TextStyle(color: Colors.cyanAccent, fontSize: 14, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
              if (biz.hasOrder && biz.isActive)
                IconButton(
                  onPressed: () => _addToCart(p, biz, isEn),
                  icon: const Icon(Icons.add_shopping_cart, color: Colors.cyanAccent),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.cyanAccent.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
            ],
          ),
          if (isAmenityList) ...[ 
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: amenities.map((amenity) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.cyanAccent, size: 12),
                    const SizedBox(width: 5),
                    Text(amenity, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 11, fontWeight: FontWeight.w500)),
                  ],
                ),
              )).toList(),
            ),
          ] else if (!isAmenityList && amenities.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              amenities.join(' '),
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12, height: 1.5),
            ),
          ],
        ],
      ),
    ),
  );
}

  Future<void> _addToCart(Product p, Business biz, bool isEn) async {
    final session = await AuthService.getSession();
    if (session['isLoggedIn'] != 'true') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isEn ? "Please login to place an order." : "Sipariş vermek için lütfen üye girişi yapınız."),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 3),
      ));
      Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
      return;
    }

    if (p.variants.isNotEmpty) {
      _showVariantSelector(p, biz, isEn);
    } else {
      _processAddToCart(p, null, biz, isEn);
    }
  }

  void _showVariantSelector(Product p, Business biz, bool isEn) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1e293b),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(isEn ? "Select Variant" : "Varyant Seçin", style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                ...p.variants.map((v) {
                  return ListTile(
                    title: Text(v.name, style: const TextStyle(color: Colors.white)),
                    trailing: Text("+${v.priceDiff} ₺", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
                    onTap: () {
                      Navigator.pop(context);
                      _processAddToCart(p, v, biz, isEn);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  void _processAddToCart(Product p, ProductVariant? variant, Business biz, bool isEn) {
    if (!_checkIsOpen(biz.workingHoursData)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isEn ? "Business is currently closed, cannot place order." : "İşletme şu anda hizmet saatleri dışındadır, sipariş alınamaz."),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ));
      return;
    }

    final cart = context.read<CartProvider>();
    try {
      cart.addItem(
        businessId: biz.id,
        businessName: isEn ? (biz.nameEn ?? biz.name) : biz.name,
        hasPosDevice: biz.hasPosDevice,
        item: CartItem(
          productId: p.id,
          name: isEn ? (p.nameEn ?? p.name) : p.name,
          basePrice: double.tryParse(p.price ?? '0') ?? 0.0,
          variantName: variant?.name,
          variantPriceDiff: variant?.priceDiff ?? 0.0,
          imageUrl: p.image != null ? AppConfig.imageUrl(p.image!) : '',
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isEn ? "Added to cart" : "Sepete Eklendi"),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString().replaceAll("Exception: ", "")),
        backgroundColor: Colors.redAccent,
        duration: const Duration(seconds: 3),
      ));
    }
  }

  Widget _buildGalleryList(List<String> images) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal, physics: const BouncingScrollPhysics(),
        itemCount: images.length,
        itemBuilder: (context, index) {
          return Container(
            width: 160, margin: const EdgeInsets.only(right: 15),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white.withOpacity(0.05)), image: DecorationImage(image: CachedNetworkImageProvider(AppConfig.imageUrl(images[index])), fit: BoxFit.cover)),
          );
        },
      ),
    );
  }

  Widget _buildQRCode(String path) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: CachedNetworkImage(imageUrl: AppConfig.imageUrl(path), width: 140, height: 140, errorWidget: (c,u,e)=>const Icon(Icons.qr_code, size: 100, color: Colors.black12)),
      ),
    );
  }

  Widget _buildCheckInButton(bool isEn) {
    return Container(); // Removed, merged into _buildTrafficAndCheckIn
  }

  Widget _buildTrafficAndCheckIn(Business biz, bool isEn) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (biz.lat != null && biz.lng != null)
          LocationTrafficWidget(
            lat: biz.lat!,
            lng: biz.lng!,
            title: isEn ? (biz.nameEn ?? biz.name) : biz.name,
            isEn: isEn,
          ),
        
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          margin: const EdgeInsets.only(bottom: 20, top: 20),
          child: InkWell(
            onTap: () => _handleCheckIn(context, biz.id, "business", biz.districtId),
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
        ),
      ],
    );
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen cihazınızın konum (GPS) servisini açın.")));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Konum izinleri reddedildi.")));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Konum izni kalıcı olarak reddedildi, ayarlardan açmalısınız.")));
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

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(res['message'] ?? (res['status'] == 'success' ? "Check-in Başarılı!" : "Bir hata oluştu")),
        backgroundColor: res['status'] == 'success' ? Colors.green : Colors.redAccent,
      ));

    } catch(e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sunucu bağlantı hatası.")));
    }
  }

  Widget _buildInlineOrderButton(String link, bool isEn) {
    return GestureDetector(
      onTap: () => launchUrl(Uri.parse(link), mode: LaunchMode.externalApplication),
      child: Container(
        margin: const EdgeInsets.only(top: 15),
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFff5722), Color(0xFFff9800)],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF5722).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(FontAwesomeIcons.basketShopping, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text(isEn ? "ORDER NOW" : "SİPARİŞ VER", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> stats, bool isEn) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.cyanAccent.withOpacity(0.05), Colors.greenAccent.withOpacity(0.05)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.chartSimple, color: Colors.cyanAccent, size: 16),
              const SizedBox(width: 10),
              Text(
                isEn ? "BUSINESS ANALYTICS" : "İŞLETME İSTATİSTİKLERİ",
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      stats['monthly_views'].toString(),
                      style: const TextStyle(color: Colors.cyanAccent, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEn ? "MONTHLY VIEWS" : "BU AY GÖRÜNTÜLENME",
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1)),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      stats['yearly_views'].toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEn ? "YEARLY VIEWS" : "BU YIL GÖRÜNTÜLENME",
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPanoramaBadge(BuildContext context, String url) {
    return GestureDetector(
      onTap: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => PanoramaViewerScreen(url: url))),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.orangeAccent.withOpacity(0.3))),
        child: Row(
          children: [
            const FaIcon(FontAwesomeIcons.streetView, color: Colors.orangeAccent, size: 14),
            const SizedBox(width: 8),
            const Text("360 TUR", style: TextStyle(color: Colors.orangeAccent, fontSize: 10, fontWeight: FontWeight.w900)),
          ],
        ),
      ),
    );
  }

  Future<void> _openMap(double? lat, double? lng) async {
    if (lat == null || lng == null) return;
    
    // Yol tarifi alındığında sayacı artır
    int bId = int.tryParse(widget.businessId) ?? 0;
    if (bId > 0) {
      ApiService.trackAnalytics(targetId: bId, action: 'direction');
    }
    
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  Future<void> _callBusiness(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    launchUrl(Uri(scheme: 'tel', path: phone));
  }
}
