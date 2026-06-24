import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:rotarehber_flutter/providers/district_provider.dart';
import '../../providers/language_provider.dart';
import '../../models/business_model.dart';
import '../../config/app_config.dart';
import '../business/business_detail_screen.dart';

class BusinessListScreen extends StatefulWidget {
  final String districtId;
  final String categoryId;
  final String categoryName;

  const BusinessListScreen({
    super.key,
    required this.districtId,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<BusinessListScreen> createState() => _BusinessListScreenState();
}

class _BusinessListScreenState extends State<BusinessListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() =>
      context.read<DistrictProvider>().fetchBusinesses(widget.districtId, widget.categoryId)
    );
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
          provider.isLoadingBusinesses
              ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
              : provider.businesses.isEmpty
                  ? _buildEmptyState(isEn)
                  : _buildBusinessListView(provider, isEn),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isEn) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(FontAwesomeIcons.storeSlash, size: 60, color: Colors.white.withOpacity(0.1)),
          const SizedBox(height: 20),
          Text(
            isEn ? "No businesses found" : "Bu kategoride işletme bulunamadı",
            style: const TextStyle(color: Colors.white38, fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessListView(DistrictProvider provider, bool isEn) {
    List<Business> sortedBusinesses = List.from(provider.businesses);
    sortedBusinesses.sort((a, b) {
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
      padding: const EdgeInsets.fromLTRB(20, 120, 20, 40),
      physics: const BouncingScrollPhysics(),
      itemCount: sortedBusinesses.length,
      itemBuilder: (context, index) {
        final biz = sortedBusinesses[index];
        return _buildBusinessCard(context, biz, isEn, provider);
      },
    );
  }

  Widget _buildBusinessCard(BuildContext context, Business biz, bool isEn, DistrictProvider provider) {
    String imagePath = (biz.imageMain != null && (biz.imageMain?.isNotEmpty ?? false))
        ? AppConfig.imageUrl(biz.imageMain ?? "")
        : (biz.image != null && (biz.image?.isNotEmpty ?? false) ? AppConfig.imageUrl(biz.image ?? "") : "");

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (context) => BusinessDetailScreen(
              districtId: widget.districtId,
              businessId: biz.id.toString(),
              businessName: isEn ? (biz.nameEn ?? biz.name) : biz.name,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              imagePath.isNotEmpty
                  ? Image.network(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        debugPrint("Image Load Error: $error | Path: $imagePath");
                        return Container(
                          color: const Color(0xFF1e293b),
                          child: const Icon(Icons.image_not_supported, color: Colors.white10),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: const Color(0xFF1e293b),
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white10)),
                        );
                      },
                    )
                  : Container(
                      color: const Color(0xFF1e293b),
                      child: const Icon(Icons.store, color: Colors.white10),
                    ),
              
              // Gradient Overlay (Bottom to Top)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    stops: const [0.0, 0.7],
                    colors: [
                      Colors.black.withOpacity(0.9),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // Content Layout
              Positioned(
                bottom: 15,
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
                            (isEn ? (biz.nameEn ?? biz.name) : biz.name).replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Text(
                                provider.getDistanceTo(biz.lat, biz.lng) ?? "",
                                style: const TextStyle(
                                  color: Colors.cyanAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (provider.getDistanceTo(biz.lat, biz.lng) != null)
                                const SizedBox(width: 10),
                              const FaIcon(FontAwesomeIcons.circleInfo,
                                  color: Colors.white70, size: 10),
                              const SizedBox(width: 5),
                              Text(
                                isEn ? "DETAILS" : "DETAYLAR",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 5),
                      child: FaIcon(
                        FontAwesomeIcons.chevronRight,
                        color: Colors.cyanAccent,
                        size: 18,
                      ),
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
}
