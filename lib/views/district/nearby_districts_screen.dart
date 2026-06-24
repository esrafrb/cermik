import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rotarehber_flutter/providers/district_provider.dart';
import '../../providers/language_provider.dart';
import '../../config/app_config.dart';
import 'district_details_screen.dart';

class NearbyDistrictsScreen extends StatefulWidget {
  final String currentDistrictId;

  const NearbyDistrictsScreen({
    super.key,
    required this.currentDistrictId,
  });

  @override
  State<NearbyDistrictsScreen> createState() => _NearbyDistrictsScreenState();
}

class _NearbyDistrictsScreenState extends State<NearbyDistrictsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<DistrictProvider>().fetchDistricts();
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isEn = context.watch<LanguageProvider>().isEn;
    final provider = context.watch<DistrictProvider>();
    
    // Geçerli ilçe hariç diğerlerini filtrele
    final otherDistricts = provider.districts.where((d) => d.id.toString() != widget.currentDistrictId).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      appBar: AppBar(
        title: Text(
          isEn ? "Nearby Districts" : "Yakındaki İlçeler",
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: provider.isLoadingDistricts
          ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: otherDistricts.length,
              itemBuilder: (context, index) {
                final d = otherDistricts[index];
                return _buildDistrictItem(context, d, isEn);
              },
            ),
    );
  }

  Widget _buildDistrictItem(BuildContext context, dynamic district, bool isEn) {
    return GestureDetector(
      onTap: () {
        Navigator.pushReplacement(
          context,
          CupertinoPageRoute(
            builder: (context) => DistrictDetailsScreen(
              districtId: district.id.toString(),
              districtName: isEn ? (district.nameEn ?? district.name) : district.name,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: AppConfig.imageUrl(district.image ?? ""),
                fit: BoxFit.cover,
                errorWidget: (c, u, e) => Container(color: const Color(0xFF1e293b)),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (isEn ? (district.nameEn ?? district.name) : district.name).replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      isEn ? "Explore district details" : "İlçe detaylarını keşfedin",
                      style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Positioned(
                right: 20,
                top: 0,
                bottom: 0,
                child: Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
