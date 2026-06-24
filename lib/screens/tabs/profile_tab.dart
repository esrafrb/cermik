import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../services/lang_service.dart';
import '../login_screen.dart';

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> with SingleTickerProviderStateMixin {
  bool _isLoggedIn  = false;
  bool _isLoading   = true;
  String _userName  = '';
  String _userEmail = '';
  String _userPhone = '';
  String _userImage = '';
  int _checkInCount = 0;
  int _submissionCount = 0;
  List<dynamic> _checkins     = [];
  List<dynamic> _submissions  = [];
  late TabController _innerTabCtrl;

  @override
  void initState() {
    super.initState();
    _innerTabCtrl = TabController(length: 2, vsync: this);
    _loadUser();
  }

  @override
  void dispose() {
    _innerTabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final session = await AuthService.getSession();
    if (session['isLoggedIn'] != 'true') {
      if (mounted) setState(() { _isLoggedIn = false; _isLoading = false; });
      return;
    }
    if (mounted) {
      setState(() {
        _isLoggedIn    = true;
        _userName      = session['userName'] ?? '';
        _userEmail     = session['userEmail'] ?? '';
        _userPhone     = session['userPhone'] ?? '';
        _userImage     = session['userImage'] ?? '';
      });
    }

    final res = await AuthService.getUserSummary();
    if (res['status'] == 'success' && mounted) {
      setState(() {
        final stats = res['stats'] ?? {};
        final history = res['history'] ?? {};
        _checkInCount = stats['approved_checkins'] ?? 0;
        _submissionCount = stats['cek_gonder_submissions'] ?? 0;
        _checkins = history['checkins'] ?? [];
        _submissions = history['submissions'] ?? [];
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await AuthService.clearSession();
    if (mounted) {
      setState(() {
        _isLoggedIn  = false;
        _userName    = '';
        _userEmail   = '';
        _userPhone   = '';
        _userImage   = '';
        _checkins    = [];
        _submissions = [];
      });
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;

    final session = await AuthService.getSession();
    final result = await ApiService.updateProfileImage(
      imagePath: file.path,
      sessionCookie: session['sessionCookie'],
    );

    if (result['status'] == 'success' && mounted) {
      setState(() => _userImage = result['image_path'] ?? '');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil fotoğrafı güncellendi'), backgroundColor: Color(0xFF10b981)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF00c9ff)));
    }
    if (!_isLoggedIn) {
      return _buildGuestView();
    }
    return _buildProfileView();
  }

  Widget _buildGuestView() {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: Stack(
        children: [
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Column(children: [
                    Container(
                      width: 90, height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(colors: [Color(0xFF00c9ff), Color(0xFF92fe9d)]),
                        boxShadow: [BoxShadow(color: const Color(0xFF00c9ff).withOpacity(0.3), blurRadius: 20)],
                      ),
                      child: const Icon(Icons.person_outline, color: Colors.black, size: 44),
                    ),
                    const SizedBox(height: 24),
                    const Text('Hoş Geldiniz', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Text('Sana özel keşifler, check-in geçmişi ve daha fazlası için giriş yap.',
                        textAlign: TextAlign.center, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14, height: 1.5)),
                    const SizedBox(height: 40),
                    SizedBox(
                      width: double.infinity, height: 56,
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(context, CupertinoPageRoute(builder: (_) => const LoginScreen()))
                            .then((_) => _loadUser()),
                        icon: const Icon(Icons.login),
                        label: const Text('Giriş Yap veya Kayıt Ol', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00c9ff),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          elevation: 0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Daha Sonra / Geri Dön', style: TextStyle(color: Colors.white.withOpacity(0.4))),
                    ),
                  ]),
                ),
                const SizedBox(height: 40),
                _buildEmergencyNumbers(),
              ]),
            ),
          ),
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white70, size: 32),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileView() {
    final String imageUrl = _userImage.startsWith('http') 
        ? _userImage 
        : (_userImage.isNotEmpty ? '${ApiService.baseUrl}/../$_userImage' : '');

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0f172a),
      ),
      child: SingleChildScrollView(
        child: Column(children: [
          _buildHeader(imageUrl),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Transform.translate(
              offset: const Offset(0, -30),
              child: Row(children: [
                _buildStatCard('$_checkInCount', langService.isEn ? 'TOTAL\nDISCOVERY' : 'TOPLAM\nKEŞİF'),
                const SizedBox(width: 12),
                _buildStatCard('$_submissionCount', langService.isEn ? 'SNAP & SEND\nRECORD' : 'ÇEK GÖNDER\nKAYDI'),
                const SizedBox(width: 12),
                _buildStatCard('0', langService.isEn ? 'POINTS\n(SOON)' : 'PUAN\n(YAKINDA)'),
              ]),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('AKTİVİTE ÖZETİ', style: TextStyle(color: Color(0xFF00c9ff), fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: TabBar(
                  controller: _innerTabCtrl,
                  indicator: BoxDecoration(
                    color: const Color(0xFF00c9ff).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF00c9ff)),
                  ),
                  labelColor: const Color(0xFF00c9ff),
                  unselectedLabelColor: Colors.white38,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  tabs: const [Tab(text: 'Keşiflerim'), Tab(text: 'Gönderiler')],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 400,
                child: TabBarView(controller: _innerTabCtrl, children: [
                  _buildCheckInsList(),
                  _buildSubmissionsList(),
                ]),
              ),
            ]),
          ),

          const SizedBox(height: 24),
          const Divider(color: Colors.white10, indent: 20, endIndent: 20),
          
          _buildMenuSection('HESAP AYARLARI', [
            _buildMenuItem(Icons.person_outline, 'Profil Bilgilerim', () {}),
            _buildMenuItem(Icons.lock_reset_outlined, 'Şifre Değiştir', () {}),
            _buildMenuItem(Icons.logout, 'Çıkış Yap', () => _showLogoutDialog(), isDestructive: true),
            _buildMenuItem(Icons.delete_forever_outlined, langService.pick(tr: 'Üyeliğimi Sil', en: 'Delete Account'), () => _showDeleteAccountDialog(), isDestructive: true),
          ]),

          _buildMenuSection('KURUMSAL', [
            _buildMenuItem(Icons.article_outlined, 'KVKK Aydınlatma Metni', () {}),
            _buildMenuItem(Icons.shield_outlined, 'Gizlilik Politikası', () {}),
            _buildMenuItem(Icons.info_outline, 'Hakkımızda', () {}),
          ]),

          const SizedBox(height: 30),
          _buildEmergencyNumbers(),
          const SizedBox(height: 50),
        ]),
      ),
    );
  }

  Widget _buildHeader(String imageUrl) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 60),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [const Color(0xFF00c9ff).withOpacity(0.2), Colors.transparent],
        ),
      ),
      child: Column(children: [
        Stack(children: [
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFF00c9ff).withOpacity(0.2),
            child: CircleAvatar(
              radius: 46,
              backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
              child: imageUrl.isEmpty ? const Icon(Icons.person, size: 50, color: Color(0xFF00c9ff)) : null,
            ),
          ),
          Positioned(bottom: 0, right: 0, 
            child: GestureDetector(
              onTap: _pickAndUploadAvatar,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Color(0xFF00c9ff), shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, size: 16, color: Colors.black),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 20),
        Text(_userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.email_outlined, color: Color(0xFF00c9ff), size: 14),
          const SizedBox(width: 6),
          Text(_userEmail, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
        ]),
        if (_userPhone.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.phone_outlined, color: Color(0xFF00c9ff), size: 14),
              const SizedBox(width: 6),
              Text(_userPhone, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
            ]),
          ),
      ]),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFF1e293b),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(children: [
          Text(value, style: const TextStyle(color: Color(0xFF00c9ff), fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
          const SizedBox(height: 6),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold, height: 1.2)),
        ]),
      ),
    );
  }

  Widget _buildCheckInsList() {
    if (_checkins.isEmpty) return _buildEmptyList('Henüz keşif yapmadınız.');
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _checkins.length,
      itemBuilder: (c, i) => _buildCheckInItem(_checkins[i]),
    );
  }

  Widget _buildSubmissionsList() {
    if (_submissions.isEmpty) return _buildEmptyList('Henüz gönderi yapmadınız.');
    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: _submissions.length,
      itemBuilder: (c, i) => _buildSubmissionItem(_submissions[i]),
    );
  }

  Widget _buildEmptyList(String msg) {
    return Center(child: Text(msg, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 14)));
  }

  Widget _buildCheckInItem(dynamic item) {
    final status = item['status'] ?? 'PENDING';
    final isApproved = status == 'APPROVED';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: (isApproved ? Colors.green : Colors.orange).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: Icon(isApproved ? Icons.verified : Icons.history, color: isApproved ? Colors.green : Colors.orange, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item['name'] ?? '—', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(item['district_name'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
        ])),
        Text(_formatDate(item['created_at']), style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11)),
      ]),
    );
  }

  Widget _buildSubmissionItem(dynamic item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFF00c9ff).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.send, color: Color(0xFF00c9ff), size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item['basvuru_turu'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          Text(item['aciklama'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
        ])),
        Text(_formatDate(item['created_at']), style: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 11)),
      ]),
    );
  }

  Widget _buildMenuSection(String title, List<Widget> items) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Color(0xFF00c9ff), fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(children: items),
        ),
      ]),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, VoidCallback onTap, {bool isDestructive = false}) {
    final color = isDestructive ? Colors.redAccent : Colors.white70;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 16),
          Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w500))),
          Icon(Icons.chevron_right, color: color.withOpacity(0.3), size: 18),
        ]),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        title: const Text('Çıkış Yap', style: TextStyle(color: Colors.white)),
        content: const Text('Oturumunuz kapatılacaktır. Devam etmek istiyor musunuz?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('İPTAL', style: TextStyle(color: Colors.white38))),
          TextButton(onPressed: () { Navigator.pop(c); _logout(); }, child: const Text('ÇIKIŞ YAP', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 26),
          const SizedBox(width: 10),
          Text(
            langService.pick(tr: 'Hesabı Sil', en: 'Delete Account'),
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ]),
        content: Text(
          langService.pick(
            tr: 'Bu işlem geri alınamaz.\n\nHesabınız, tüm check-in kayıtlarınız ve verileriniz kalıcı olarak silinecektir.\n\nDevam etmek istiyor musunuz?',
            en: 'This action cannot be undone.\n\nYour account, all check-in records, and data will be permanently deleted.\n\nDo you want to continue?',
          ),
          style: const TextStyle(color: Colors.white70, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: Text(
              langService.pick(tr: 'İPTAL', en: 'CANCEL'),
              style: const TextStyle(color: Colors.white38),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(c);
              await _deleteAccount();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              langService.pick(tr: 'HESABI SİL', en: 'DELETE ACCOUNT'),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(langService.pick(tr: 'İstek gönderiliyor...', en: 'Sending request...')),
        backgroundColor: Colors.orange,
      ),
    );
    final result = await AuthService.deleteAccount();
    if (!mounted) return;
    if (result['status'] == 'success') {
      setState(() {
        _isLoggedIn  = false;
        _userName    = '';
        _userEmail   = '';
        _userPhone   = '';
        _userImage   = '';
        _checkins    = [];
        _submissions = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(langService.pick(
            tr: 'Silme isteğiniz alındı. Hesabınız 24 saat içinde kalıcı olarak silinecektir.',
            en: 'Your request has been received. Your account will be permanently deleted within 24 hours.',
          )),
          backgroundColor: const Color(0xFF10b981),
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? langService.pick(tr: 'Bir hata oluştu.', en: 'An error occurred.')),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildEmergencyNumbers() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF00c9ff).withOpacity(0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF00c9ff).withOpacity(0.1)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Icon(Icons.emergency_outlined, color: Color(0xFF00c9ff), size: 20),
          SizedBox(width: 10),
          Text('ÖNEMLİ TELEFONLAR', style: TextStyle(color: Color(0xFF00c9ff), fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1)),
        ]),
        const SizedBox(height: 20),
        _emergencyRow('Polis İmdat', '155'),
        _emergencyRow('Jandarma', '156'),
        _emergencyRow('Acil Servis', '112'),
        _emergencyRow('İtfaiye', '110'),
      ]),
    );
  }

  Widget _emergencyRow(String label, String no) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Text(label, style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14)),
        const Spacer(),
        GestureDetector(
          onTap: () => launchUrl(Uri.parse('tel:$no')),
          child: Text(no, style: const TextStyle(color: Color(0xFF00c9ff), fontWeight: FontWeight.bold, fontSize: 18)),
        ),
      ]),
    );
  }

  String _formatDate(String? raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}
