import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../services/lang_service.dart';
import '../../config/app_config.dart';
import '../../services/api_service.dart';
import '../places_archive_screen.dart';
import '../../core/utils/translation_helper.dart';


class DiscoverTab extends StatelessWidget {
  final Map<String, dynamic> district;
  final Map<String, dynamic>? details;

  const DiscoverTab({super.key, required this.district, this.details});

  @override
  Widget build(BuildContext context) {
    if (details == null) return const Center(child: CircularProgressIndicator(color: Color(0xFF00c9ff)));

    // Web Parity: get_district_details.php dosyasından gelen kategoriler
    final List<dynamic> categories = details?['categories'] ?? [];
    
    return Container(
      color: const Color(0xFF0f172a),
      child: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: SizedBox(height: 110)),
          
          // BANNER: Web sitenizdeki banner mantığı
          SliverToBoxAdapter(child: _buildBanner()),

          // GRID: Web sitenizdeki 2'li kutucuk yapısı
          SliverPadding(
            padding: const EdgeInsets.all(15),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, 
                crossAxisSpacing: 12, 
                mainAxisSpacing: 12, 
                childAspectRatio: 0.85
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildCard(context, categories[index]),
                childCount: categories.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    final String banner = details?['settings']?['hero_image'] ?? 'assets/img/categories/nature.jpg';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15),
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: DecorationImage(image: NetworkImage(AppConfig.imageUrl(banner)), fit: BoxFit.cover),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.bottomCenter, 
            end: Alignment.topCenter,
            colors: [Colors.black.withOpacity(0.8), Colors.transparent]
          ),
        ),
        padding: const EdgeInsets.all(20),
        alignment: Alignment.bottomLeft,
        child: Text(
          district['name'].toString().replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase(), 
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, dynamic cat) {
    return InkWell(
      onTap: () {
        Navigator.push(context, CupertinoPageRoute(builder: (c) => PlacesArchiveScreen(
          category: ApiService.mapCategorySlug(cat['id'].toString()),
          categoryName: TranslationHelper.getCategoryLabel(cat['name'], langService.isEn),
          districtId: district['id'],
        )));
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Column(children: [
          Expanded(child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            child: Image.network(
              AppConfig.imageUrl(cat['image']), 
              fit: BoxFit.cover, 
              width: double.infinity,
              errorBuilder: (c, e, s) => const Icon(Icons.image, color: Colors.white10),
            ),
          )),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              TranslationHelper.getCategoryLabel(cat['name'], langService.isEn), 
              textAlign: TextAlign.center, 
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11)
            ),
          ),
        ]),
      ),
    );
  }
}
