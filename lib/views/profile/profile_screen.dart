import 'dart:ui';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart' as dio;
import '../../providers/language_provider.dart';
import '../../providers/district_provider.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../screens/login_screen.dart';
import '../address/address_list_screen.dart';
import '../cart/cart_screen.dart';
import '../order/order_list_screen.dart';
import '../../config/app_config.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ProfileScreen extends StatefulWidget {
  final String? districtId;
  const ProfileScreen({super.key, this.districtId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with TickerProviderStateMixin {
  Map<String, String?> _userData = {};
  bool _isLoading = true;
  bool _showLoginForm = false;
  
  // Dynamic Data
  List<dynamic> _checkins = [];
  List<dynamic> _submissions = [];
  int _checkinsCount = 0;
  int _submissionsCount = 0;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    await _loadUserData();
    if (_userData['isLoggedIn'] == 'true') {
      await _fetchProfileDetails();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadUserData() async {
    final data = await AuthService.getSession();
    if (mounted) {
      setState(() {
        _userData = data;
      });
    }
  }

  Future<void> _fetchProfileDetails() async {
    final res = await AuthService.getProfile();
    if (res['status'] == 'success' && res['data'] != null) {
      final d = res['data'];
      setState(() {
        _checkins = d['checkins'] ?? [];
        _submissions = d['submissions'] ?? [];
        _checkinsCount = d['stats']['checkins'] ?? 0;
        _submissionsCount = d['stats']['submissions'] ?? 0;
        
        if (d['user'] != null && d['user']['profile_image'] != null) {
           _userData['userImage'] = d['user']['profile_image'];
           AuthService.saveSession(d['user']);
        }
      });
    }
  }

  Future<void> _pickAndUploadProfileImage(bool isEn) async {
    final picker = ImagePicker();
    await showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1e293b),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: Colors.cyanAccent),
              title: Text(isEn ? 'Take Photo' : 'Fotoğraf Çek', style: const TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? img = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
                if (img != null && mounted) await _uploadPhoto(img, isEn);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Colors.cyanAccent),
              title: Text(isEn ? 'Choose from Gallery' : 'Galeriden Seç', style: const TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
                if (img != null && mounted) await _uploadPhoto(img, isEn);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadPhoto(XFile img, bool isEn) async {
    final userId = _userData['userId'];
    if (userId == null) return;
    try {
      final dioClient = dio.Dio();
      final formData = dio.FormData.fromMap({
        'user_id': userId,
        'profile_image': await dio.MultipartFile.fromFile(img.path, filename: 'profile.jpg'),
      });
      final res = await dioClient.post(
        '${AppConfig.apiBaseUrl}profile/upload-photo',
        data: formData,
        options: dio.Options(headers: {'Accept': 'application/json'}),
      );
      if (res.data['status'] == 'success') {
        final newUrl = res.data['url']?.toString() ?? '';
        if (mounted) {
          setState(() => _userData['userImage'] = newUrl);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(isEn ? 'Profile photo updated!' : 'Profil fotoğrafı güncellendi!'), backgroundColor: Colors.green),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isEn ? 'Upload failed: $e' : 'Yükleme başarısız: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    bool isEn = context.watch<LanguageProvider>().isEn;
    final isLoggedIn = _userData['isLoggedIn'] == 'true';
    
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      extendBodyBehindAppBar: true,
      appBar: (!isLoggedIn && _showLoginForm) ? null : AppBar(
        title: Text(isEn ? "PROFILE" : "PROFİLİM", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 2, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white), // Geri butonu rengi
        actions: const [],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0f172a), Color(0xFF1e293b), Color(0xFF0f172a)],
                ),
              ),
            ),
          ),

          _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
            : (!isLoggedIn && _showLoginForm)
              ? LoginScreen(
                  isEmbedded: true,
                  onLoginSuccess: () {
                    setState(() => _showLoginForm = false);
                    _loadAllData();
                  },
                )
              : RefreshIndicator(
                  onRefresh: _loadAllData,
                  color: Colors.cyanAccent,
                  backgroundColor: const Color(0xFF1e293b),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 120, bottom: 40),
                    child: Column(
                      children: [
                        if (!isLoggedIn)
                          _buildLoginRequired(isEn)
                        else ...[
                          _buildUserInfo(isEn),
                          const SizedBox(height: 30),
                          _buildActionGrid(isEn),
                          const SizedBox(height: 30),
                          _buildTabsSection(isEn),
                          _buildTabContent(isEn),

                          // HESAP AYARLARI — sadece giriş yapılmışken göster
                          _buildSectionTitle(isEn ? "ACCOUNT SETTINGS" : "HESAP AYARLARI"),
                          _buildAccountSection(isEn),
                        ],

                        _buildSectionTitle(isEn ? "MUNICIPAL INFO" : "KURUMSAL BİLGİLER"),
                        _buildCorporateSection(isEn),

                        // Üyeliğimi Sil — EN ALTA (Kullanım Şartlarından sonra)
                        if (_userData['isLoggedIn'] == 'true')
                          Padding(
                            padding: const EdgeInsets.fromLTRB(25, 30, 25, 0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: Colors.redAccent.withOpacity(0.15)),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.delete_forever_outlined, color: Colors.redAccent, size: 20),
                                ),
                                title: Text(
                                  isEn ? 'Delete My Account' : 'Üyeliğimi Sil',
                                  style: const TextStyle(color: Colors.redAccent, fontSize: 14, fontWeight: FontWeight.w700),
                                ),
                                subtitle: Text(
                                  isEn ? 'Your data will be deleted within 24 hours.' : 'Verileriniz 24 saat içinde silinecektir.',
                                  style: TextStyle(color: Colors.redAccent.withOpacity(0.5), fontSize: 11),
                                ),
                                trailing: const Icon(Icons.chevron_right_rounded, color: Colors.redAccent),
                                onTap: () => _showDeleteAccountDialog(isEn),
                              ),
                            ),
                          ),
                        
                        const SizedBox(height: 40),
                        Text(
                          "V1.6.0",
                          style: TextStyle(color: Colors.white.withOpacity(0.15), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 2),
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildLoginRequired(bool isEn) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              children: [
                const FaIcon(FontAwesomeIcons.circleUser, color: Colors.cyanAccent, size: 60),
                const SizedBox(height: 25),
                Text(
                  isEn ? "Login Required" : "Giriş Yapmalısınız",
                  style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                ),
                const SizedBox(height: 15),
                Text(
                  isEn ? "Please login to access your personalized profile and features." : "Size özel özelliklere ve profilinize erişebilmek için lütfen giriş yapın.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, height: 1.5),
                ),
                const SizedBox(height: 35),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _showLoginForm = true;
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 0,
                    ),
                    child: Text(isEn ? "LOGIN NOW" : "ŞİMDİ GİRİŞ YAP", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserInfo(bool isEn) {
    final String imageUrl = _userData['userImage'] != null && _userData['userImage']!.isNotEmpty
        ? _userData['userImage']!
        : "https://www.rotarehber.com/assets/img/default-avatar.png";

    return Column(
      children: [
        GestureDetector(
          onTap: () => _pickAndUploadProfileImage(isEn),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [Colors.cyanAccent, Color(0xFF0891b2)]),
                ),
                child: CircleAvatar(
                  radius: 55,
                  backgroundImage: imageUrl.startsWith('http') 
                    ? NetworkImage(imageUrl) 
                    : (imageUrl.startsWith('/') ? FileImage(File(imageUrl)) as ImageProvider : NetworkImage(AppConfig.imageUrl(imageUrl))),
                  backgroundColor: Colors.black26,
                ),
              ),
              // Kamera ikonu — tıklanabilir olduğunu gösteriyor
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Color(0xFF0891b2), shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _userData['userName']?.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase() ?? "",
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 0.5),
            ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () async {
                await AuthService.clearSession();
                _loadAllData();
              },
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 18),
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          _userData['userEmail'] ?? "",
          style: TextStyle(color: Colors.cyanAccent.withOpacity(0.6), fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        const SizedBox(height: 15),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.amber.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.withOpacity(0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const FaIcon(FontAwesomeIcons.shieldHalved, color: Colors.amber, size: 10),
              const SizedBox(width: 8),
              Text(
                (_userData['userRole'] ?? "USER").replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase(),
                style: const TextStyle(color: Colors.amber, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionGrid(bool isEn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Row(
        children: [
          Expanded(child: _buildStatCard(isEn ? "My Explorations" : "Keşiflerim", _checkinsCount.toString(), FontAwesomeIcons.mapLocationDot, Colors.cyanAccent)),
          const SizedBox(width: 15),
          Expanded(child: _buildStatCard(isEn ? "My Requests" : "Başvurularım", _submissionsCount.toString(), FontAwesomeIcons.paperPlane, Colors.blueAccent)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, dynamic icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FaIcon(icon, color: color.withOpacity(0.5), size: 18),
          const SizedBox(height: 15),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase(), style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  Widget _buildTabsSection(bool isEn) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 25),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.cyanAccent,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 20),
        indicatorWeight: 3,
        labelColor: Colors.cyanAccent,
        unselectedLabelColor: Colors.white38,
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
        onTap: (index) { setState(() {}); },
        tabs: [
          Tab(text: (isEn ? "VISITS" : "ZİYARETLERİM").replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase()),
          Tab(text: (isEn ? "SUBMISSIONS" : "BAŞVURULARIM").replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase()),
        ],
      ),
    );
  }

  Widget _buildTabContent(bool isEn) {
    return Container(
      height: 380, // Fixed height for the list area
      margin: const EdgeInsets.only(top: 15),
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildCheckinsList(isEn),
          _buildSubmissionsList(isEn),
        ],
      ),
    );
  }

  Widget _buildCheckinsList(bool isEn) {
    if (_checkins.isEmpty) {
      return _buildEmptyState(isEn ? "No visits yet." : "Henüz ziyaret kaydı yok.");
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      itemCount: _checkins.length,
      itemBuilder: (context, index) {
        final item = _checkins[index];
        bool isApproved = item['status'] == 'APPROVED';
        return _buildHistoryItem(
          title: item['target_name'] ?? 'Bilinmeyen Mekan',
          subtitle: item['district_name'] ?? '',
          date: item['created_at'] ?? '',
          status: '', // Kullanıcı talebi: Ziyaretlerde onaylandı vs. yazısı gizlendi.
          statusColor: Colors.transparent,
          icon: FontAwesomeIcons.locationDot,
        );
      },
    );
  }

  Widget _buildSubmissionsList(bool isEn) {
    if (_submissions.isEmpty) {
      return _buildEmptyState(isEn ? "No submissions yet." : "Henüz başvuru kaydı yok.");
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      itemCount: _submissions.length,
      itemBuilder: (context, index) {
        final item = _submissions[index];
        final String processStatus = item['process_status'] ?? 'Beklemede';
        Color sColor = Colors.cyanAccent;
        String sText = processStatus;
        final String typeStr = (item['basvuru_turu'] ?? '').toString().toLowerCase().trim();
        final bool isSpecialType = typeStr == 'şikayet' || typeStr == 'istek' || typeStr == 'i̇stek';
        
        if (!isSpecialType) {
           sColor = Colors.cyanAccent;
           sText = isEn ? "Sent" : "İletildi";
        } else {
           if (processStatus == 'Beklemede') {
              sColor = Colors.amberAccent;
              sText = isEn ? "Pending" : "Beklemede";
           } else if (processStatus == 'İşleme Alındı') {
              sColor = Colors.blueAccent;
              sText = isEn ? "In Process" : "İşleme Alındı";
           } else if (processStatus == 'Tamamlandı' || processStatus == 'Çözüldü') {
              sColor = Colors.greenAccent;
              sText = isEn ? "Completed" : "Tamamlandı";
           }
        }

        final String districtName = item['district_name'] != null ? "${item['district_name']} - " : "";
        return _buildHistoryItem(
          title: item['basvuru_turu'] ?? (isEn ? "Submission" : "Başvuru"),
          subtitle: districtName + (item['aciklama'] ?? ''),
          date: item['created_at'] ?? '',
          status: sText,
          statusColor: sColor,
          icon: FontAwesomeIcons.paperPlane,
        );
      },
    );
  }

  Widget _buildHistoryItem({
    required String title,
    required String subtitle,
    required String date,
    required String status,
    required Color statusColor,
    required dynamic icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 5),
                    Text(subtitle, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              if (status.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Text(status, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              FaIcon(icon, color: Colors.white24, size: 14),
              Text(date.split(' ')[0], style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 10, fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Opacity(
        opacity: 0.5,
        child: Text(msg, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(25, 40, 25, 20),
      child: Row(
        children: [
          Text(title, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
          const SizedBox(width: 15),
          const Expanded(child: Divider(color: Colors.white10, thickness: 1)),
        ],
      ),
    );
  }

  Widget _buildAccountSection(bool isEn) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        children: [
          // Adreslerim
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_on_outlined, color: Colors.cyanAccent, size: 20),
              ),
              title: Text(
                isEn ? 'My Addresses' : 'Adreslerim',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                isEn ? 'Manage your delivery addresses' : 'Teslimat adreslerinizi yönetin',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
              onTap: () {
                Navigator.push(context, CupertinoPageRoute(builder: (ctx) => const AddressListScreen()));
              },
            ),
          ),

          // Sepetim
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.cyanAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shopping_cart_outlined, color: Colors.cyanAccent, size: 20),
              ),
              title: Text(
                isEn ? 'My Cart' : 'Sepetim',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                isEn ? 'View your cart' : 'Sepetinizdeki ürünleri görüntüleyin',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
              onTap: () {
                Navigator.push(context, CupertinoPageRoute(builder: (ctx) => const CartScreen()));
              },
            ),
          ),

          // Siparişlerim
          Container(
            margin: const EdgeInsets.only(bottom: 15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.receipt_long_outlined, color: Colors.greenAccent, size: 20),
              ),
              title: Text(
                isEn ? 'My Orders' : 'Siparişlerim',
                style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                isEn ? 'Track your online orders' : 'Geçmiş siparişlerinizi takip edin',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white54),
              onTap: () {
                Navigator.push(context, CupertinoPageRoute(builder: (ctx) => const OrderListScreen()));
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(bool isEn) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 26),
          const SizedBox(width: 10),
          Text(
            isEn ? 'Delete Account' : 'Hesabı Sil',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ]),
        content: Text(
          isEn
            ? 'This action cannot be undone.\n\nYour account, all visit records, and data will be permanently deleted within 24 hours.\n\nDo you want to continue?'
            : 'Bu işlem geri alınamaz.\n\nHesabınız, tüm ziyaret kayıtlarınız ve verileriniz 24 saat içinde kalıcı olarak silinecektir.\n\nDevam etmek istiyor musunuz?',
          style: const TextStyle(color: Colors.white70, height: 1.5, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(
              isEn ? 'CANCEL' : 'İPTAL',
              style: const TextStyle(color: Colors.white38),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(c);
              await _deleteAccount(isEn);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              isEn ? 'DELETE ACCOUNT' : 'HESABI SİL',
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(bool isEn) async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isEn ? 'Sending request...' : 'İstek gönderiliyor...'),
        backgroundColor: Colors.orange,
      ),
    );
    final result = await AuthService.deleteAccount();
    if (!mounted) return;
    if (result['status'] == 'success') {
      setState(() {
        _userData = {};
        _checkins = [];
        _submissions = [];
        _checkinsCount = 0;
        _submissionsCount = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isEn
              ? 'Your request has been received. Your account will be deleted within 24 hours.'
              : 'Silme isteğiniz alındı. Hesabınız 24 saat içinde kalıcı olarak silinecektir.',
          ),
          backgroundColor: const Color(0xFF10b981),
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? (isEn ? 'An error occurred.' : 'Bir hata oluştu.')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildCorporateSection(bool isEn) {
    final List<Map<String, dynamic>> items = [
      {'title': isEn ? "Privacy Policy" : "Gizlilik Politikası", 'icon': Icons.privacy_tip_outlined, 'type': 'privacy'},
      {'title': isEn ? "KVKK Clarification" : "KVKK Aydınlatma Metni", 'icon': Icons.description_outlined, 'type': 'kvkk'},
      {'title': isEn ? "Cookie Policy" : "Çerez Politikası", 'icon': Icons.cookie_outlined, 'type': 'cookie'},
      {'title': isEn ? "Terms of Use" : "Kullanım Şartları", 'icon': Icons.gavel_outlined, 'type': 'terms'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25),
      child: Column(
        children: items.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  leading: Icon(item['icon'] as IconData, color: Colors.cyanAccent.withOpacity(0.7), size: 20),
                  title: Text(item['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white24),
                  onTap: () => _showLegalContent(item['title'] as String, item['type'] as String),
                ),
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Future<void> _showLegalContent(String title, String type) async {
    String url = AppConfig.baseMediaUrl;
    
    if (type == 'privacy') {
      url += 'gizlilik-politikasi.php';
    } else if (type == 'kvkk') {
      url += 'kvkk-aydinlatma.php';
    } else if (type == 'cookie') {
      url += 'cerez-politikasi.php';
    } else if (type == 'terms') {
      url += 'kullanim-sartlari.php';
    } else {
      url += 'gizlilik-politikasi.php';
    }

    late final WebViewController webController;
    webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFf0f4f8))
      ..enableZoom(false)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) {
          // Sayfа yüklendikten sonra scroll'u zorla aktif et
          webController.runJavaScript('''
            document.body.style.touchAction = 'pan-y';
            document.body.style.overflowY = 'auto';
            document.documentElement.style.overflowY = 'auto';
          ''');
        },
      ))
      ..loadRequest(Uri.parse(url));

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85, // 85% ekran yüksekliği
        decoration: const BoxDecoration(
          color: Color(0xFF1e293b),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),
            // Çekme (drag) çubuğu
            Center(
              child: Container(
                width: 50, 
                height: 5, 
                decoration: BoxDecoration(
                  color: Colors.white24, 
                  borderRadius: BorderRadius.circular(10)
                )
              )
            ),
            const SizedBox(height: 15),
            // Başlık ve Kapat Butonu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase(),
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Web İçeriği (WebView)
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                child: WebViewWidget(
                  controller: webController,
                  gestureRecognizers: {
                    Factory<VerticalDragGestureRecognizer>(
                      () => VerticalDragGestureRecognizer(),
                    ),
                    Factory<TapGestureRecognizer>(
                      () => TapGestureRecognizer(),
                    ),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
