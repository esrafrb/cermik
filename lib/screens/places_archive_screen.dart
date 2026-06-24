import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/check_in_service.dart';

import '../config/app_config.dart';
import '../services/lang_service.dart';
import '../views/place/place_detail_screen.dart';
import '../../core/utils/translation_helper.dart';

import 'package:provider/provider.dart';
import '../providers/district_provider.dart';
import '../providers/language_provider.dart';

class PlacesArchiveScreen extends StatefulWidget {
  final String category;
  final String categoryName;
  final int districtId;

  const PlacesArchiveScreen({
    super.key, 
    required this.category, 
    required this.categoryName, 
    required this.districtId
  });

  @override
  State<PlacesArchiveScreen> createState() => _PlacesArchiveScreenState();
}

class _PlacesArchiveScreenState extends State<PlacesArchiveScreen> {
  late Future<List<dynamic>> _placesFuture;

  @override
  void initState() {
    super.initState();
    _placesFuture = ApiService.getPlaces(category: widget.category, districtId: widget.districtId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0f172a).withOpacity(0.4),
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.transparent),
          ),
        ),
        title: Text(widget.categoryName.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase(), 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
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
            child: FutureBuilder<List<dynamic>>(
              future: _placesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF00c9ff)));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, color: Colors.white.withOpacity(0.3), size: 64),
                        const SizedBox(height: 16),
                        Text(langService.t('Bu kategoride henüz kayıt bulunmuyor.', en: 'No listings found in this category.'), 
                          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16)),
                      ],
                    ),
                  );
                }

                final places = List<dynamic>.from(snapshot.data!);
                
                final provider = context.watch<DistrictProvider>();
                final bool isEn = context.watch<LanguageProvider>().isEn;
                places.sort((a, b) {
                  String? distAStr = provider.getDistanceTo(
                    a['lat'] != null ? double.tryParse(a['lat'].toString()) : null,
                    a['lng'] != null ? double.tryParse(a['lng'].toString()) : null,
                  );
                  String? distBStr = provider.getDistanceTo(
                    b['lat'] != null ? double.tryParse(b['lat'].toString()) : null,
                    b['lng'] != null ? double.tryParse(b['lng'].toString()) : null,
                  );
                  
                  if (distAStr == null && distBStr == null) return 0;
                  if (distAStr == null) return 1;
                  if (distBStr == null) return -1;
                  
                  double distA = double.tryParse(distAStr.replaceAll(' KM', '')) ?? 999999;
                  double distB = double.tryParse(distBStr.replaceAll(' KM', '')) ?? 999999;
                  return distA.compareTo(distB);
                });

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 120, 20, 20),
                  itemCount: places.length,
                  itemBuilder: (context, index) {
                    final place = places[index];
                    return _buildPlaceCard(place, isEn);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(dynamic place, bool isEn) {
    String? imageUrl = place['image_main'] != null ? AppConfig.imageUrl(place['image_main']) : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              CupertinoPageRoute(
                builder: (c) => PlaceDetailScreen(
                  placeId: int.parse(place['id'].toString()),
                ),
              ),
            );
          },
          child: Row(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  image: imageUrl != null 
                    ? DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover)
                    : null,
                  color: Colors.white.withOpacity(0.05),
                ),
                child: imageUrl == null ? const Icon(Icons.image, color: Colors.white10) : null,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (isEn ? (place['name_en'] ?? place['name']) : place['name']) ?? '', 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                      const SizedBox(height: 5),
                      Builder(builder: (context) {
                        final provider = context.watch<DistrictProvider>();
                        final double? lat = place['lat'] != null ? double.tryParse(place['lat'].toString()) : null;
                        final double? lng = place['lng'] != null ? double.tryParse(place['lng'].toString()) : null;
                        final String? distanceLabel = provider.getDistanceTo(lat, lng);
                        if (distanceLabel == null) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.location_on, color: Colors.cyanAccent, size: 10),
                              const SizedBox(width: 4),
                              Text(distanceLabel, style: TextStyle(color: const Color(0xFF00c9ff).withOpacity(0.9), fontSize: 11, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        );
                      }),
                      if (place['address'] != null) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.location_on, color: Colors.white30, size: 12),
                            const SizedBox(width: 4),
                            Expanded(child: Text(place['address'], 
                              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
                              maxLines: 1, overflow: TextOverflow.ellipsis)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.location_on_outlined, color: Color(0xFF00c9ff)),
                      onPressed: () async {
                        // Check-in işlemi (Web: check_in.php)
                        final result = await CheckInService.submitCheckIn(
                          targetId: int.parse(place['id'].toString()),
                          districtId: widget.districtId,
                          targetType: 'place', // Veya business (API'ye göre)
                        );
                        
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message'] ?? langService.t('Bir hata oluştu.', en: 'An error occurred.')),
                              backgroundColor: result['status'] == 'success' ? Colors.green : Colors.redAccent,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                    ),
                    const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

