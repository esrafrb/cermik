import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'api_service.dart';
import '../screens/district_container_screen.dart';
import '../widgets/bottom_nav_bar.dart';
import '../config/app_config.dart';
import 'lang_service.dart';


// DEPRECATED: Bu dosya artık kullanılmıyor. Lütfen lib/views/home/home_screen.dart kullanın.
class OldHomeScreen extends StatefulWidget {
  const OldHomeScreen({super.key});

  @override
  State<OldHomeScreen> createState() => _OldHomeScreenState();
}

class _OldHomeScreenState extends State<OldHomeScreen> {
  late Future<List<dynamic>> _districtsFuture;
  late Future<List<dynamic>> _eventsFuture;
  late Future<Map<String, dynamic>?> _weatherFuture;
  Position? _userPosition;

  @override
  void initState() {
    super.initState();
    _districtsFuture = ApiService.getDistricts();
    _eventsFuture = ApiService.getEvents();
    _weatherFuture = ApiService.getWeather();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        Position pos = await Geolocator.getCurrentPosition();
        if (mounted) setState(() { _userPosition = pos; });
      }
    } catch (e) {
      debugPrint('Konum alınamadı: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topRight,
                radius: 1.5,
                colors: [Color(0xFF1e293b), Color(0xFF0f172a)],
              ),
            ),
            child: CustomScrollView(
              slivers: [
                // 1. Header Main (Web: .header-main)
                SliverAppBar(
                  pinned: true,
                  backgroundColor: const Color(0xFF0f172a).withOpacity(0.4),
                  elevation: 0,
                  flexibleSpace: ClipRect(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(color: Colors.transparent),
                    ),
                  ),
                  title: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.route, color: Color(0xFF00c9ff), size: 28),
                      SizedBox(width: 10),
                      Text('ROTAREHBER', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 24, letterSpacing: 1.2)),
                    ],
                  ),
                  actions: [
                    IconButton(onPressed: () {}, icon: const Icon(Icons.search, color: Colors.white70)),
                  ],
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 50),
                        // 2. Hero Section (Web: header.hero)
                        const Text('DİYARBAKIR YEREL REHBER PLATFORMU', 
                          style: TextStyle(color: Color(0xFF00c9ff), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2)),
                        const SizedBox(height: 8),
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(colors: [Color(0xFF00c9ff), Color(0xFF92fe9d)]).createShader(bounds),
                          child: const Text('ROTAREHBER', style: TextStyle(fontSize: 45, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -1)),
                        ),
                        const Text('İlçeleri Keşfetmeye Başlayın', style: TextStyle(color: Colors.white70, fontSize: 18, fontWeight: FontWeight.w300)),
                        const SizedBox(height: 35),
                        
                        // QR Button (Web: .qr-scan-btn)
                        Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF00c9ff), Color(0xFF92fe9d)]),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [BoxShadow(color: const Color(0xFF00c9ff).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 5))],
                          ),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            ),
                            onPressed: () {}, 
                            icon: const Icon(Icons.qr_code_scanner, color: Colors.black, size: 24),
                            label: const Text('KAREKOD OKUT', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, letterSpacing: 1, fontSize: 15)),
                          ),
                        ),
                        const SizedBox(height: 50),

                        // 3. Districts Section (Web: .section-header + .district-grid)
                        const Row(
                          children: [
                            Text('İlçeler', style: TextStyle(color: Color(0xFF00c9ff), fontSize: 22, fontWeight: FontWeight.bold)),
                            SizedBox(width: 15),
                            Expanded(child: Divider(color: Colors.white10, thickness: 1)),
                          ],
                        ),
                        const SizedBox(height: 25),
                        _buildDistrictsGrid(),

                        const SizedBox(height: 50),

                        // 4. Events Section (Web: .events-strip)
                        const Row(
                          children: [
                            Text('Etkinlikler', style: TextStyle(color: Color(0xFF00c9ff), fontSize: 22, fontWeight: FontWeight.bold)),
                            SizedBox(width: 15),
                            Expanded(child: Divider(color: Colors.white10, thickness: 1)),
                          ],
                        ),
                        const SizedBox(height: 25),
                        _buildEventsList(),
                        const SizedBox(height: 50),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistrictsGrid() {
    return FutureBuilder<List<dynamic>>(
      future: _districtsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator(color: Color(0xFF00c9ff));
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox();

        final districts = snapshot.data!;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.82,
            crossAxisSpacing: 15,
            mainAxisSpacing: 15,
          ),
          itemCount: districts.length,
          itemBuilder: (context, index) {
            var dist = districts[index];
            bool isCermik = dist['id'] == 3 || dist['id'] == '3';
            
            return _buildDistrictCard(dist, isCermik);
          },
        );
      },
    );
  }

  Widget _buildDistrictCard(dynamic dist, bool isCermik) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: () {
            // Tam veriyi (Map) geçiyoruz
            Navigator.push(context, CupertinoPageRoute(builder: (c) => DistrictContainerScreen(district: dist)));
          },
          child: Stack(
            children: [
              // District Image (Webdeki gibi gerçek resimler)
              Container(
                height: 100,
                width: double.infinity,
                child: Image.network(
                  AppConfig.imageUrl(
                    isCermik ? 'assets/img/categories/kaplica.jpg' : 'assets/img/categories/historical.jpg'
                  ),
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => _buildPlaceholderIcon(isCermik),
                ),
              ),
              // Hava Durumu ve KM (Geri bildirim doğrultusunda eklendi)
              Positioned(
                top: 10, left: 15,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<Map<String, dynamic>?>(
                      future: _weatherFuture,
                      builder: (context, weatherSnap) {
                        String temp = isCermik ? '24°C' : '21°C'; // Fallback
                        IconData icon = Icons.wb_sunny_outlined;

                        if (weatherSnap.hasData && weatherSnap.data != null) {
                          final w = weatherSnap.data!;
                          if (isCermik) { // Sadece Çermik için canlı veriyi göster (veya hepsi için)
                             temp = '${w['temp']}°C';
                             icon = _getWeatherIcon(w['icon']);
                          }
                        }

                        return Row(
                          children: [
                            Icon(icon, color: Colors.white70, size: 12),
                            const SizedBox(width: 4),
                            Text(temp, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        );
                      }
                    ),
                    Text(
                      _calculateDistance(dist['lat'], dist['lng']), 
                      style: const TextStyle(color: Colors.white54, fontSize: 8)
                    ),
                  ],
                ),
              ),
              // Overlay for text
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [const Color(0xFF0f172a).withOpacity(0.95), Colors.transparent]),
                  ),
                ),
              ),
              Positioned(
                bottom: 12, left: 15, right: 15,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dist['name'].toString().replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase(), 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text(langService.t('DETAYLARI GÖR', en: 'VIEW DETAILS'), style: TextStyle(color: const Color(0xFF00c9ff).withOpacity(0.7), fontSize: 9, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon(bool isCermik) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCermik ? [const Color(0xFFFF512F), const Color(0xFFDD2476)] : [const Color(0xFF1d976c), const Color(0xFF93f9b9)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Center(child: Icon(isCermik ? Icons.castle : Icons.landscape, color: Colors.white.withOpacity(0.8), size: 40)),
    );
  }


  Widget _buildEventsList() {
    return FutureBuilder<List<dynamic>>(
      future: _eventsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text("Yaklaşan etkinlik yok.", style: TextStyle(color: Colors.white54));

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            var ev = snapshot.data![index];
            String desc = ev['description']?.toString().replaceAll(RegExp(r'<[^>]*>'), '') ?? '';
            // RangeError önlemek için uzunluk kontrolü
            String shortDesc = desc.length > 50 ? desc.substring(0, 50) + "..." : desc;

            return Container(
              margin: const EdgeInsets.only(bottom: 15),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                   // Event Date Box
                    Container(
                      width: 60, height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF00c9ff), Color(0xFF92fe9d)]),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            ev['event_date'] != null ? DateTime.parse(ev['event_date']).day.toString() : '?',
                            style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 24),
                          ),
                          Text(
                            _getMonthName(ev['event_date']),
                            style: const TextStyle(color: Colors.black87, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ev['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
                        const SizedBox(height: 6),
                        Text(shortDesc, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13, height: 1.4)),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getMonthName(dynamic date) {
    if (date == null) return '???';
    try {
      final dt = DateTime.parse(date.toString());
      if (langService.isEn) {
        const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
        return months[dt.month - 1];
      }
      const months = ['OCA', 'ŞUB', 'MAR', 'NİS', 'MAY', 'HAZ', 'TEM', 'AĞU', 'EYL', 'EKİ', 'KAS', 'ARA'];
      return months[dt.month - 1];
    } catch (e) { return '???'; }
  }

  IconData _getWeatherIcon(String? iconCode) {
    switch (iconCode) {
      case 'fa-sun': return Icons.wb_sunny;
      case 'fa-cloud-sun': return Icons.wb_cloudy_outlined;
      case 'fa-cloud': return Icons.cloud;
      case 'fa-cloud-rain': return Icons.umbrella;
      case 'fa-cloud-showers-heavy': return Icons.thunderstorm; // lowercase t
      case 'fa-snowflake': return Icons.ac_unit;
      case 'fa-bolt': return Icons.flash_on;
      case 'fa-smog': return Icons.foggy;
      default: return Icons.wb_sunny_outlined;
    }
  }

  String _calculateDistance(dynamic lat, dynamic lng) {
    if (_userPosition == null || lat == null || lng == null) return '-- KM';
    
    try {
      double dLat = double.parse(lat.toString());
      double dLng = double.parse(lng.toString());
      
      double distanceInMeters = Geolocator.distanceBetween(
        _userPosition!.latitude, 
        _userPosition!.longitude, 
        dLat, 
        dLng
      );
      
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} KM';
    } catch (e) {
      return '-- KM';
    }
  }
}
