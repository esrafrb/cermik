import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rotarehber_flutter/providers/district_provider.dart';
import '../../providers/language_provider.dart';
import '../../config/app_config.dart';
import 'place_detail_screen.dart';

class PlaceListScreen extends StatefulWidget {
  final String districtId;
  final String categoryId;
  final String categoryName;

  const PlaceListScreen({
    super.key,
    required this.districtId,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<PlaceListScreen> createState() => _PlaceListScreenState();
}

class _PlaceListScreenState extends State<PlaceListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      final provider = context.read<DistrictProvider>();
      await provider.fetchPlaces(widget.districtId, category: widget.categoryId);
      
      // Auto-Navigation: If there is ONLY ONE place in this category, go directly to detail.
      // This matches Web-Parity for single-entry categories like 'Kaplıca'.
      if (mounted && provider.places.length == 1) {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
            builder: (context) => PlaceDetailScreen(placeId: provider.places.first.id),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isEn = context.watch<LanguageProvider>().isEn;
    final provider = context.watch<DistrictProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(widget.categoryName.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Colors.transparent],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Visual Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1e293b), Color(0xFF0f172a)],
              ),
            ),
          ),
          provider.isLoadingPlaces
              ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
              : provider.places.isEmpty
                  ? _buildEmptyState(isEn)
                  : _buildPlaceListView(provider, isEn),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isEn) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(FontAwesomeIcons.mapLocationDot, size: 60, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 20),
          Text(
            isEn ? "No places found in this category" : "Bu kategoride henüz mekan bulunamadı",
            style: const TextStyle(color: Colors.white38, fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceListView(DistrictProvider provider, bool isEn) {
    List<dynamic> sortedPlaces = List.from(provider.places);
    sortedPlaces.sort((a, b) {
      String? distAStr = provider.getDistanceTo(a.lat, a.lng);
      String? distBStr = provider.getDistanceTo(b.lat, b.lng);
      
      if (distAStr == null && distBStr == null) return 0;
      if (distAStr == null) return 1;
      if (distBStr == null) return -1;
      
      double distA = double.tryParse(distAStr.replaceAll(' KM', '')) ?? 999999;
      double distB = double.tryParse(distBStr.replaceAll(' KM', '')) ?? 999999;
      return distA.compareTo(distB);
    });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 110, 20, 50),
      physics: const BouncingScrollPhysics(),
      itemCount: sortedPlaces.length,
      itemBuilder: (context, index) {
        final place = sortedPlaces[index];
        return _buildPlaceCard(place, isEn, provider);
      },
    );
  }

  Widget _buildPlaceCard(dynamic place, bool isEn, DistrictProvider provider) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(builder: (context) => PlaceDetailScreen(placeId: place.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        height: 150, // Web Parity: Compact Archive height
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (place.imageMain != null && place.imageMain != "" && !place.imageMain!.contains('placeholder'))
                Image.network(
                  AppConfig.imageUrl(place.imageMain!),
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => _buildFallbackGradient(place.category),
                )
              else
                _buildFallbackGradient(place.category),
              
              // Web Parity: menu-card-overlay (Gradient from bottom)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withOpacity(0.85),
                      Colors.black.withOpacity(0.4),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6, 1.0],
                  ),
                ),
              ),

              // Content Layout (Bottom labels) - Matches web places_archive.php
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            (isEn ? (place.nameEn ?? place.name) : place.name).replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 18, 
                              fontWeight: FontWeight.w900, 
                              letterSpacing: 0.5, 
                              shadows: [Shadow(color: Colors.black, blurRadius: 10, offset: Offset(0, 2))]
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              // Distance Info
                              const FaIcon(FontAwesomeIcons.locationArrow, color: Colors.cyanAccent, size: 10),
                              const SizedBox(width: 6),
                              Text(
                                provider.getDistanceTo(place.lat, place.lng) ?? (isEn ? "Measuring..." : "Ölçülüyor..."),
                                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(width: 15),
                              // Details Link
                              const FaIcon(FontAwesomeIcons.circleInfo, color: Colors.white70, size: 10),
                              const SizedBox(width: 6),
                              Text(
                                isEn ? "DETAILS" : "DETAYLAR",
                                style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const FaIcon(
                      FontAwesomeIcons.chevronRight, 
                      color: Colors.cyanAccent, 
                      size: 20,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackGradient(String category) {
    Gradient grad;
    // Web Parity: Category specific gradients from places_archive.php
    switch (category.toLowerCase()) {
      case 'historical':
      case 'tarihi':
        grad = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF5c3a21), Color(0xFF8b4513)]);
        break;
      case 'nature':
      case 'doga':
        grad = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF228B22), Color(0xFF006400)]);
        break;
      case 'park_bahce':
      case 'parks':
      case 'parkandgarden':
      case 'parks-gardens':
        grad = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2E8B57), Color(0xFF1e5631)]);
        break;
      case 'businesses':
        grad = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2c3e50), Color(0xFF000000)]);
        break;
      default:
        grad = const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF1e293b), Color(0xFF0f172a)]);
    }
    return Container(
      decoration: BoxDecoration(gradient: grad),
      child: Center(child: FaIcon(FontAwesomeIcons.landmark, color: Colors.white.withOpacity(0.05), size: 40)),
    );
  }
}
