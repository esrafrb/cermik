import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../models/business_model.dart';
import '../../config/app_config.dart';
import '../../widgets/web_360_view.dart';

class HospitalDetailScreen extends StatelessWidget {
  final Hospital hospital;

  const HospitalDetailScreen({super.key, required this.hospital});

  @override
  Widget build(BuildContext context) {
    final bool isEn = context.watch<LanguageProvider>().isEn;
    final String displayName = (isEn && hospital.nameEn != null && hospital.nameEn!.isNotEmpty) 
        ? hospital.nameEn! 
        : hospital.name;
    final String displayDesc = (isEn && hospital.descriptionEn != null && hospital.descriptionEn!.isNotEmpty) 
        ? hospital.descriptionEn! 
        : (hospital.description ?? '');
    final bool hasPanorama = hospital.panorama360 != null && hospital.panorama360!.isNotEmpty;
    final bool hasImage = hospital.imageMain != null && hospital.imageMain!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
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
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // === HEADER: 360 Panorama veya Resim (Web parity: hospital_detail.php L65-91) ===
            SizedBox(
              height: hasPanorama ? 400 : 280,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (hasPanorama)
                    Web360View(panoramaUrl: hospital.panorama360!, isEmbedded: true)
                  else if (hasImage)
                    Image.network(
                      AppConfig.imageUrl(hospital.imageMain!),
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(
                        color: const Color(0xFF1e293b),
                        child: const Icon(Icons.local_hospital, color: Colors.white10, size: 80),
                      ),
                    )
                  else
                    Container(
                      color: const Color(0xFF1e293b),
                      child: const Icon(Icons.local_hospital, color: Colors.white10, size: 80),
                    ),
                  // Gradient overlay + başlık (web parity: hospital_detail.php L80-82)
                  Positioned(
                    bottom: 0, left: 0, right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black.withOpacity(0.9)],
                        ),
                      ),
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          shadows: [Shadow(color: Colors.black87, blurRadius: 10)],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // === HAKKINDA BÖLÜMÜ (Web parity: hospital_detail.php L94-98) ===
            if (displayDesc.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.white.withOpacity(0.08)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEn ? "ABOUT" : "HAKKINDA",
                            style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            displayDesc,
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // === KONUM BİLGİSİ (Web parity: hospital_detail.php L100-108) ===
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.04),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(color: Colors.white.withOpacity(0.08)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const FaIcon(FontAwesomeIcons.locationDot, color: Colors.cyanAccent, size: 16),
                            const SizedBox(width: 10),
                            Text(
                              isEn ? "LOCATION" : "KONUM BİLGİSİ",
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),

                        if (hospital.lat != null && hospital.lng != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(15),
                            child: SizedBox(
                              height: 200,
                              width: double.infinity,
                              child: GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(hospital.lat!, hospital.lng!),
                                  zoom: 15,
                                ),
                                liteModeEnabled: false,
                                scrollGesturesEnabled: false,
                                zoomGesturesEnabled: false,
                                tiltGesturesEnabled: false,
                                rotateGesturesEnabled: false,
                                mapToolbarEnabled: false,
                                myLocationButtonEnabled: false,
                                zoomControlsEnabled: false,
                                markers: {
                                  Marker(
                                    markerId: const MarkerId('hospital'),
                                    position: LatLng(hospital.lat!, hospital.lng!),
                                    infoWindow: InfoWindow(title: displayName),
                                  ),
                                },
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),
                        ],

                        // Yol Tarifi Butonu (web parity: hospital_detail.php L108)
                        GestureDetector(
                          onTap: () => _openMaps(hospital.lat, hospital.lng),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFF00c9ff), Color(0xFF92fe9d)]),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const FaIcon(FontAwesomeIcons.locationArrow, color: Colors.black, size: 16),
                                const SizedBox(width: 10),
                                Text(
                                  isEn ? "GET DIRECTIONS" : "YOL TARİFİ AL",
                                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // === TELEFON BUTONU ===
            if (hospital.phone != null && hospital.phone!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(20),
                child: GestureDetector(
                  onTap: () => _callPhone(hospital.phone!),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.cyanAccent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.cyanAccent.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const FaIcon(FontAwesomeIcons.phone, color: Colors.cyanAccent, size: 16),
                        const SizedBox(width: 10),
                        Text(
                          hospital.phone!,
                          style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  void _openMaps(double? lat, double? lng) {
    if (lat == null || lng == null) return;
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  void _callPhone(String phone) {
    final Uri uri = Uri(scheme: 'tel', path: phone.replaceAll(' ', ''));
    launchUrl(uri);
  }
}
