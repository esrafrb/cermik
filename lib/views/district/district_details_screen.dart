import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/language_provider.dart';
import '../../providers/district_provider.dart';
import '../../config/app_config.dart';
import '../../widgets/district_drawer.dart';
import '../business/business_list_screen.dart';
import '../pharmacy/pharmacy_list_screen.dart';
import '../cek_gonder/cek_gonder_screen.dart';
import '../service/service_list_screen.dart';
import '../profile/profile_screen.dart';
import '../live/live_broadcast_screen.dart';
import '../announcement/announcement_list_screen.dart';
import '../event/event_list_screen.dart';
import '../place/place_detail_screen.dart';
import '../place/place_list_screen.dart';
import '../../models/extra_models.dart';
import '../../models/place_model.dart';
import '../../screens/places_archive_screen.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../providers/cart_provider.dart';
import '../cart/cart_screen.dart';

class DistrictDetailsScreen extends StatefulWidget {
  final String districtId;
  final String districtName;

  const DistrictDetailsScreen({
    super.key,
    required this.districtId,
    required this.districtName,
  });

  @override
  State<DistrictDetailsScreen> createState() => _DistrictDetailsScreenState();
}

class _DistrictDetailsScreenState extends State<DistrictDetailsScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final provider = context.read<DistrictProvider>();
      provider.fetchDistrictDetails(widget.districtId);
      provider.fetchEvents(widget.districtId);
    });
  }

  @override
  Widget build(BuildContext context) {
    bool isEn = context.watch<LanguageProvider>().isEn;
    final provider = context.watch<DistrictProvider>();
    final details = provider.districtDetails;

    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      endDrawer: DistrictDrawer(
        districtId: widget.districtId,
        districtSlug: details['district']?['slug']?.toString() ?? '',
        mayorName: provider.mayorInfo['name']?.toString() ?? 'Belediye Başkanı',
        mayorTitle: (isEn ? (provider.mayorInfo['title_en'] ?? provider.mayorInfo['title']) : provider.mayorInfo['title'])?.toString() ?? (isEn ? 'Mayor' : 'Başkan'),
        mayorImageUrl: provider.mayorInfo['image']?.toString() ?? '',
        address: provider.contactInfo['address']?.toString() ?? '',
        phone: provider.contactInfo['phone']?.toString() ?? '',
        email: provider.contactInfo['email']?.toString() ?? '',
        onHomeTap: () {
          Navigator.pop(context);
          setState(() => _currentIndex = 0);
        },
        onServicesTap: () {
          Navigator.pop(context);
          setState(() => _currentIndex = 3);
        },
        onAnnouncementsTap: () {
          Navigator.pop(context);
          Navigator.push(context, CupertinoPageRoute(builder: (c) => AnnouncementListScreen(districtId: widget.districtId, districtName: widget.districtName)));
        },
        onEventsTap: () {
          Navigator.pop(context);
          Navigator.push(context, CupertinoPageRoute(builder: (c) => EventListScreen(districtId: widget.districtId, districtName: widget.districtName)));
        },
        onPharmaciesTap: () {
          Navigator.pop(context);
          Navigator.push(context, CupertinoPageRoute(builder: (c) => PharmacyListScreen(districtId: widget.districtId, districtName: widget.districtName)));
        },
        onLiveTap: () {
          Navigator.pop(context);
          if (provider.liveBroadcasts.isNotEmpty) {
            Navigator.push(context, CupertinoPageRoute(builder: (c) => LiveBroadcastScreen(broadcasts: provider.liveBroadcasts)));
          }
        },
      ),
      body: Stack(
        children: [
          IndexedStack(
            index: _currentIndex,
            children: [
              _buildExploreTab(isEn, provider, details),
              const SizedBox.shrink(), // Index 1 is Cart (handled via push)
              const SizedBox.shrink(),
              ServiceListScreen(
                districtId: widget.districtId, 
                districtName: widget.districtName,
                onBackPressed: () => setState(() => _currentIndex = 0),
              ),
              ProfileScreen(districtId: widget.districtId),
            ],
          ),
          if (_currentIndex == 0) _buildAppBar(isEn),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(isEn),
    );
  }

  Widget _buildExploreTab(bool isEn, DistrictProvider provider, dynamic details) {
    if (provider.isLoadingDetails) {
      return const Center(child: CircularProgressIndicator(color: Colors.cyan));
    }

    final districtData = details['district'] ?? {};
    final double? fallbackLat = districtData['lat'] != null ? double.tryParse(districtData['lat'].toString()) : null;
    final double? fallbackLng = districtData['lng'] != null ? double.tryParse(districtData['lng'].toString()) : null;

    final List<dynamic> allCategories = List.from(provider.categories);
    
    // HotSpring'i her zaman grid'den çıkar - hero banner olarak gösterilecek
    // Hem eski (custom_menus=[]) hem yeni sunucu (custom_menus=[hotspring]) koduyla uyumlu
    allCategories.removeWhere((cat) => cat['id']?.toString() == 'HotSpring');
    
    // İlçe mönüleri (Kategoriler) Çermik (3) ana sayfası hariç km'ye göre sırala
    if (widget.districtId != "3") {
      allCategories.sort((a, b) {
        String? distAStr = provider.getDistanceTo(
          a['lat'] != null ? double.tryParse(a['lat'].toString()) : null,
          a['lng'] != null ? double.tryParse(a['lng'].toString()) : null
        );
        String? distBStr = provider.getDistanceTo(
          b['lat'] != null ? double.tryParse(b['lat'].toString()) : null,
          b['lng'] != null ? double.tryParse(b['lng'].toString()) : null
        );
        
        if (distAStr == null && distBStr == null) return 0;
        if (distAStr == null) return 1;
        if (distBStr == null) return -1;

        double distA = double.tryParse(distAStr.replaceAll(' KM', '')) ?? 999999;
        double distB = double.tryParse(distBStr.replaceAll(' KM', '')) ?? 999999;
        return distA.compareTo(distB);
      });
    }

    // FETCH District Specific Hero Titles from Settings (Admin Panel) matching Web logic
    final Map<String, dynamic> districtSettings = details['settings'] ?? {};
    

    // ── Hero Banner Listesi ──────────────────────────────────────────────
    // Kaynak 1: custom_menus (yeni sunucu kodu)
    // Kaynak 2: settings hero (eski sunucu: cermik/cungus)
    // Kaynak 3: categories'deki HotSpring (eski sunucu: sinek gibi yeni ilçeler)
    // Bu sayede hem eski hem yeni sunucu koduyla uyumlu
    final List<Widget> heroBannerWidgets = [];

    // Canlı Yayınlar
    for (var lb in (provider.liveBroadcasts)) {
      final String lbTitle = (isEn ? (lb.titleEn ?? lb.title) : lb.title);
      final String lbImg = (lb.image != null && lb.image!.isNotEmpty)
          ? AppConfig.imageUrl(lb.image!)
          : "https://via.placeholder.com/800x400?text=CANLI+YAYIN";
      heroBannerWidgets.add(_buildHeroItem(
        title: lbTitle,
        imgUrl: lbImg,
        distance: (lb.lat != null && lb.lng != null) 
            ? provider.getDistanceTo(lb.lat, lb.lng) 
            : null,
        onTap: () => Navigator.push(context, CupertinoPageRoute(
          builder: (context) => LiveBroadcastScreen(broadcasts: [lb])
        )),
        isLive: true,
        isEn: isEn,
      ));
    }

    // Custom Menus (yeni sunucu kodu - custom_menus tablosundan + HotSpring places)
    for (var cm in provider.customMenus) {
      final String cmTitle = (isEn ? (cm.nameEn ?? cm.nameTr) : cm.nameTr).toString();
      final String cmImg = (cm.image != null && cm.image!.isNotEmpty)
          ? AppConfig.imageUrl(cm.image!) : '';
      heroBannerWidgets.add(_buildHeroItem(
        title: cmTitle,
        imgUrl: cmImg.isNotEmpty ? cmImg : "https://via.placeholder.com/800x400?text=Menu",
        distance: provider.getDistanceTo(
          cm.lat != null ? double.tryParse(cm.lat.toString()) : fallbackLat,
          cm.lng != null ? double.tryParse(cm.lng.toString()) : fallbackLng,
        ),
        onTap: () {
          if (cm.placeId != null && cm.placeId! > 0) {
            Navigator.push(context, CupertinoPageRoute(
              builder: (context) => PlaceDetailScreen(placeId: cm.placeId!)
            ));
          } else if (cm.slug.contains('hotspring') || cm.slug.contains('kaplica') ||
              cmTitle.toLowerCase().contains('kaplıca')) {
            var pId = provider.places.cast<Place?>().firstWhere(
              (p) => p?.category == 'HotSpring', orElse: () => null
            )?.id ?? 56;
            Navigator.push(context, CupertinoPageRoute(
              builder: (context) => PlaceDetailScreen(placeId: pId)
            ));
          }
        },
        isEn: isEn,
      ));
    }

    // FALLBACK: custom_menus boşsa eski sunucu uyumu için settings/categories'den hero banner
    if (provider.customMenus.isEmpty) {
      final String heroTarget = districtSettings['hero_target']?.toString() ?? 'none';
      final dynamic heroTargetId = districtSettings['hero_target_id'];

      if (heroTarget == 'place' && heroTargetId != null) {
        // Çermik, Çüngüş için: settings'ten hero_image ve hero_title kullan
        final String heroImg = districtSettings['hero_image']?.toString() ?? '';
        final String heroTitleTr = districtSettings['hero_title_tr']?.toString() ?? '';
        final String heroTitleEn = districtSettings['hero_title_en']?.toString() ?? heroTitleTr;
        final double? heroLat = districtSettings['hero_lat'] != null
            ? double.tryParse(districtSettings['hero_lat'].toString()) : null;
        final double? heroLng = districtSettings['hero_lng'] != null
            ? double.tryParse(districtSettings['hero_lng'].toString()) : null;
        if (heroTitleTr.isNotEmpty || heroTitleEn.isNotEmpty) {
          heroBannerWidgets.add(_buildHeroItem(
            title: isEn ? (heroTitleEn.isNotEmpty ? heroTitleEn : heroTitleTr) : heroTitleTr,
            imgUrl: heroImg.isNotEmpty
                ? AppConfig.imageUrl(heroImg)
                : "https://via.placeholder.com/800x400?text=Kaplica",
            distance: provider.getDistanceTo(
              heroLat ?? fallbackLat, heroLng ?? fallbackLng
            ),
            onTap: () {
              final int placeId = int.tryParse(heroTargetId.toString()) ?? 0;
              if (placeId > 0) {
                Navigator.push(context, CupertinoPageRoute(
                  builder: (context) => PlaceDetailScreen(placeId: placeId)
                ));
              }
            },
            isEn: isEn,
          ));
        }
      } else {
        // Sinek gibi yeni ilçeler: sunucu henüz güncellenmemişse
        // categories içindeki HotSpring kaydından hero banner oluştur
        final dynamic hotspringCat = provider.categories.cast<dynamic>().firstWhere(
          (c) => c['id']?.toString() == 'HotSpring',
          orElse: () => null,
        );
        if (hotspringCat != null) {
          final String catNameTr = hotspringCat['name_tr']?.toString() ?? 'Kaplıcalar';
          final String catNameEn = hotspringCat['name_en']?.toString() ?? catNameTr;
          final String catImg = hotspringCat['image']?.toString() ?? '';
          heroBannerWidgets.add(_buildHeroItem(
            title: isEn ? catNameEn : catNameTr,
            imgUrl: catImg.isNotEmpty
                ? AppConfig.imageUrl(catImg)
                : "https://via.placeholder.com/800x400?text=Kaplica",
            distance: null,
            onTap: () => Navigator.push(context, CupertinoPageRoute(
              builder: (context) => PlacesArchiveScreen(
                districtId: int.tryParse(widget.districtId) ?? 0,
                category: 'HotSpring',
                categoryName: isEn ? catNameEn : catNameTr,
              )
            )),
            isEn: isEn,
          ));
        }
      }
    }
    // ────────────────────────────────────────────────────────────────────

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.top + 70)),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                ...heroBannerWidgets,
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 15,
              crossAxisSpacing: 15,
              childAspectRatio: 0.85,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index >= allCategories.length) return null;
                final category = allCategories[index];
                final String catNameTr = (category['name_tr'] ?? category['id'] ?? "").toString();
                final String catNameEn = (category['name_en'] ?? catNameTr).toString();
                final String catName = (isEn ? (catNameEn.isNotEmpty ? catNameEn : catNameTr) : catNameTr);
                final String catId = (category['id'] ?? "").toString();
                final String catImg = (category['image'] != null && category['image'] != "") ? AppConfig.imageUrl(category['image']) : "https://via.placeholder.com/400x400?text=M\u00f6n\u00fc";
                
                dynamic displayIcon = FontAwesomeIcons.layerGroup;
                final String iconStr = (category['icon'] ?? '').toString().toLowerCase();
                if (iconStr.contains('pills') || iconStr.contains('hospital')) displayIcon = FontAwesomeIcons.hospital;
                if (iconStr.contains('store')) displayIcon = FontAwesomeIcons.store;
                if (iconStr.contains('landmark')) displayIcon = FontAwesomeIcons.landmark;
                if (iconStr.contains('leaf')) displayIcon = FontAwesomeIcons.leaf;
                if (iconStr.contains('hotel')) displayIcon = FontAwesomeIcons.hotel;
                if (iconStr.contains('utensils')) displayIcon = FontAwesomeIcons.utensils;
                if (iconStr.contains('camera')) displayIcon = FontAwesomeIcons.camera;

                String? distText;
                final catLat = category['lat'];
                final catLng = category['lng'];
                if (catLat != null && catLng != null && catLat.toString().isNotEmpty && catLng.toString().isNotEmpty) {
                  distText = provider.getDistanceTo(
                    double.tryParse(catLat.toString()),
                    double.tryParse(catLng.toString())
                  );
                }

                return _buildCategoryCard(
                  name: catName,
                  img: catImg,
                  icon: displayIcon,
                  distance: distText,
                  onTap: () {
                    final String slug = (category['slug'] ?? category['id'] ?? '').toString().toLowerCase();
                    final String catIdLower = catId.toLowerCase();
                    
                    // Eczane/Hastane yönlendirmesi
                    if (slug == 'pharmacy' || catId == 'PharmacyHospital' || catIdLower == 'pharmacy') {
                      Navigator.push(context, CupertinoPageRoute(builder: (context) => PharmacyListScreen(districtId: widget.districtId, districtName: widget.districtName)));
                    
                    // Kuruyemiş Pazarı
                    } else if (slug == 'kuruyemis' || slug == 'kuruyemis_pazari' || catId == 'Kuruyemis') {
                      showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));
                      ApiService.getPlaces(districtId: int.parse(widget.districtId), category: 'Kuruyemis').then((placesList) {
                        Navigator.pop(context); // close dialog
                        if (placesList.isNotEmpty) {
                          Navigator.push(context, CupertinoPageRoute(builder: (context) => PlaceDetailScreen(placeId: placesList.first['id'])));
                        } else {
                          Navigator.push(context, CupertinoPageRoute(builder: (context) => BusinessListScreen(districtId: widget.districtId, categoryName: catName, categoryId: 'kuruyemis_pazari')));
                        }
                      });
                    
                    // Çek Gönder
                    } else if (slug == 'cek-gonder' || catId == 'cek-gonder') {
                      AuthService.getSession().then((session) {
                        bool isLoggedIn = session['isLoggedIn'] == 'true';
                        if (!isLoggedIn) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(isEn 
                              ? "You need to log in to use $catName. Redirecting..." 
                              : "$catName hizmetini kullanmak için üye girişi yapmalısınız. Yönlendiriliyorsunuz."),
                            backgroundColor: Colors.orange,
                            duration: const Duration(seconds: 2),
                          ));
                          Future.delayed(const Duration(seconds: 1), () {
                            setState(() => _currentIndex = 4);
                          });
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(isEn 
                              ? "Add value to the city with your ideas!"
                              : "Fikrinle Şehre Değer Kat!"),
                            backgroundColor: Colors.orange,
                            duration: const Duration(seconds: 2),
                          ));
                          Future.delayed(const Duration(seconds: 2), () {
                            Navigator.push(context, CupertinoPageRoute(builder: (context) => CekGonderScreen(districtId: widget.districtId, districtName: widget.districtName)));
                          });
                        }
                      });

                    // Mekan bazlı kategoriler (tarihi, doğa, park, kaplıca)
                    } else if (
                      slug.contains('historical') || slug.contains('nature') || 
                      slug.contains('park') || slug.contains('hotspring') || 
                      slug.contains('thermal') || slug.contains('kaplica') ||
                      catId == 'Historical' || catId == 'Nature' || catId == 'ParkAndGarden' || catId == 'HotSpring'
                    ) {
                       final String apiCategory = catId; // API'den gelen doğru ID kullan
                       Navigator.push(context, CupertinoPageRoute(builder: (context) => PlacesArchiveScreen(districtId: int.parse(widget.districtId), category: apiCategory, categoryName: catName)));
                    
                    // İşletme bazlı kategoriler
                    } else {
                       // hotels/restaurants için doğru kategori slug
                       String bizCatId = slug;
                       if (catId == 'hotels') bizCatId = 'hotel';
                       if (catId == 'restaurants') bizCatId = 'restaurant';
                       Navigator.push(context, CupertinoPageRoute(builder: (context) => BusinessListScreen(districtId: widget.districtId, categoryId: bizCatId, categoryName: catName)));
                    }
                  }
                );
              },
              childCount: allCategories.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildAppBar(bool isEn) {
    final provider = context.watch<DistrictProvider>();
    final details = provider.districtDetails;
    
    // Geçmiş sayfadan kalan verilerin (stale data) görünmesini engellemek için kontrol
    final bool isStale = provider.isLoadingDetails || 
                         details.isEmpty || 
                         (details['district'] != null && details['district']['id'].toString() != widget.districtId);

    final String districtSlug = isStale ? '' : (details['district']?['slug']?.toString() ?? '');
    // API artık site_logo'yu doğru şekilde döndürüyor (web ile aynı mantık)
    // Öncelik: 1) API'den gelen site_logo (settings veya {slug}/assets/logo.png) 2) Flutter fallback
    final String apiLogo = isStale ? '' : (details['settings']?['site_logo']?.toString() ?? '');
    final String primaryLogoUrl = apiLogo.isNotEmpty ? apiLogo : (districtSlug.isNotEmpty ? '$districtSlug/assets/logo.png' : '');

    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        height: 100,
        decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black.withOpacity(0.8), Colors.transparent])),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Sol taraf: Geri dönüş butonu, Hava Durumu ve Bildirim
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8), 
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle), 
                      child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16)
                    ),
                  ),
                  if (provider.districtsWeather[widget.districtId] != null) ...[
                    const SizedBox(width: 8),
                    Builder(builder: (context) {
                      final weather = provider.districtsWeather[widget.districtId];
                      final temp = weather['temperature']?.round() ?? '--';
                      final wmo = weather['weathercode'] ?? 0;
                      
                      dynamic wIcon = FontAwesomeIcons.cloudSun;
                      if (wmo == 0 || wmo == 1) wIcon = FontAwesomeIcons.sun;
                      else if (wmo == 2) wIcon = FontAwesomeIcons.cloudSun;
                      else if (wmo == 3) wIcon = FontAwesomeIcons.cloud;
                      else if (wmo >= 45 && wmo <= 48) wIcon = FontAwesomeIcons.smog;
                      else if (wmo >= 51 && wmo <= 65) wIcon = FontAwesomeIcons.cloudRain;
                      else if (wmo >= 71 && wmo <= 75) wIcon = FontAwesomeIcons.snowflake;
                      else if (wmo >= 80 && wmo <= 82) wIcon = FontAwesomeIcons.cloudShowersHeavy;
                      else if (wmo >= 95) wIcon = FontAwesomeIcons.bolt;

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.cyan.withOpacity(0.5)),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.black.withOpacity(0.3),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            FaIcon(wIcon, color: Colors.cyanAccent, size: 16),
                            const SizedBox(height: 2),
                            Text('$temp°', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, height: 1.0)),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context, CupertinoPageRoute(
                          builder: (c) => AnnouncementListScreen(
                            districtId: widget.districtId, 
                            districtName: widget.districtName,
                          )
                        ));
                      },
                      child: const FaIcon(FontAwesomeIcons.solidBell, color: Colors.white60, size: 20),
                    ),
                  ],
                ],
              ),
              
              // Orta: Logo ve İlçe Adı — profil, etkinlikler ve hizmetler tabında gizlenir
              Expanded(
                child: (_currentIndex == 1 || _currentIndex == 3 || _currentIndex == 4)
                  ? const SizedBox.shrink()
                  : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (isStale) ...[
                      const SizedBox(width: 48, height: 48),
                      const SizedBox(width: 12),
                    ] else if (primaryLogoUrl.isNotEmpty) ...[
                      Image.network(
                        AppConfig.imageUrl(primaryLogoUrl), 
                        height: 48,
                        width: 48, 
                        fit: BoxFit.contain, 
                        errorBuilder: (c, e, s) => districtSlug.isNotEmpty 
                          ? Image.network(
                              AppConfig.imageUrl('$districtSlug/assets/logo.png'),
                              height: 48, 
                              width: 48, 
                              fit: BoxFit.contain,
                              errorBuilder: (c2, e2, s2) => const SizedBox.shrink(),
                            )
                          : const SizedBox.shrink(),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Flexible(
                      child: Text(
                        widget.districtName.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase(), 
                        overflow: TextOverflow.ellipsis, 
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 1)
                      )
                    ),
                  ],
                ),
              ),
              Builder(builder: (context) => IconButton(icon: const FaIcon(FontAwesomeIcons.bars, color: Colors.white, size: 22), onPressed: () => Scaffold.of(context).openEndDrawer())),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav(bool isEn) {
    final cart = context.watch<CartProvider>();
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1e293b), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10)]),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 1) {
            if (cart.isEmpty) {
              Navigator.push(context, CupertinoPageRoute(builder: (context) => BusinessListScreen(districtId: widget.districtId, categoryId: 'restaurant', categoryName: isEn ? 'Restaurants' : 'Restoranlar')));
            } else {
              Navigator.push(context, CupertinoPageRoute(builder: (context) => const CartScreen()));
            }
          }
          else if (index == 2) Navigator.of(context).popUntil((route) => route.isFirst);
          else setState(() => _currentIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: const Color(0xFF06b6d4),
        unselectedItemColor: Colors.white60,
        selectedFontSize: 10,
        unselectedFontSize: 10,
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.explore_outlined, size: 20), label: isEn ? "Discover" : "Keşfet"),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.shopping_cart_outlined, size: 20),
                if (cart.totalItems > 0)
                  Positioned(
                    top: -5,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '${cart.totalItems}',
                        style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            label: isEn ? "Cart" : "Sepet",
          ),
          BottomNavigationBarItem(icon: Container(padding: const EdgeInsets.all(8), decoration: const BoxDecoration(color: Colors.cyan, shape: BoxShape.circle), child: const Icon(Icons.home_outlined, color: Colors.black, size: 24)), label: ""),
          BottomNavigationBarItem(icon: const FaIcon(FontAwesomeIcons.handHoldingHeart), label: isEn ? "Services" : "Hizmetler"),
          BottomNavigationBarItem(icon: const FaIcon(FontAwesomeIcons.user), label: isEn ? "Profile" : "Profil"),
        ],
      ),
    );
  }

  Widget _buildCategoryCard({required String name, required String img, required dynamic icon, String? distance, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white.withOpacity(0.1))),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: Stack(fit: StackFit.expand, children: [
                Image.network(img, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: Colors.white.withOpacity(0.05), child: const Icon(Icons.category, color: Colors.white24))),
                Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.8)]))),
                if (distance != null && distance.isNotEmpty)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65), 
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const FaIcon(FontAwesomeIcons.locationArrow, color: Colors.white, size: 8),
                          const SizedBox(width: 4),
                          Text(distance, style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
              ])),
              Padding(padding: const EdgeInsets.all(12), child: Text(name.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroItem({required String title, required String imgUrl, String? distance, bool isLive = false, required VoidCallback onTap, required bool isEn}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        height: 180,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 15, offset: const Offset(0, 5))]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(imgUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Container(color: const Color(0xFF1e293b), child: const Icon(Icons.image, color: Colors.white10))),
              Container(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.black12, Colors.black.withOpacity(0.85)]))),
              if (isLive) Positioned(top: 15, right: 15, child: _buildLiveIndicator(isEn)),
              if (distance != null && distance.isNotEmpty)
                Positioned(
                  bottom: 15,
                  left: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5), 
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const FaIcon(FontAwesomeIcons.locationArrow, color: Colors.white, size: 10),
                        const SizedBox(width: 5),
                        Text(distance, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              Center(child: Text(title.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1, shadows: [Shadow(color: Colors.black, blurRadius: 10)]))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeaderWithLink({required String title, required VoidCallback onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
        InkWell(onTap: onTap, child: Row(children: [Text(context.watch<LanguageProvider>().isEn ? "All" : "Tümü", style: const TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)), const Icon(Icons.chevron_right, color: Colors.cyanAccent, size: 18)])),
      ],
    );
  }

  Widget _buildLiveIndicator(bool isEn) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.circle, color: Colors.white, size: 8), const SizedBox(width: 5), Text(isEn ? "LIVE" : "CANLI", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))]),
    );
  }
}
