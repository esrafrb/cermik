import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:dio/dio.dart' as dio;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'package:rotarehber_flutter/providers/district_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/auth_service.dart';
import '../../screens/login_screen.dart';
import '../../config/app_config.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class CekGonderScreen extends StatefulWidget {
  final String districtId;
  final String districtName;

  const CekGonderScreen({
    super.key,
    required this.districtId,
    required this.districtName,
  });

  @override
  State<CekGonderScreen> createState() => _CekGonderScreenState();
}

class _CekGonderScreenState extends State<CekGonderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _adSoyadController = TextEditingController();
  final _tcNoController = TextEditingController();
  final _emailController = TextEditingController();
  final _telNoController = TextEditingController();
  final _aciklamaController = TextEditingController();

  String _selectedTur = '';
  final List<XFile?> _photos = [null, null, null];
  bool _isSubmitting = false;
  bool _isLoggedIn = false;
  bool _checkingAuth = true;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _checkAuthAndPreFill();
  }

  Future<void> _checkAuthAndPreFill() async {
    final session = await AuthService.getSession();
    if (mounted) {
      setState(() {
        _isLoggedIn = session['isLoggedIn'] == 'true';
        _checkingAuth = false;
        if (_isLoggedIn) {
          _userId = session['userId'];
          _adSoyadController.text = session['userName'] ?? '';
          _emailController.text = session['userEmail'] ?? '';
          _telNoController.text = session['userPhone'] ?? '';
        }
      });
    }
  }

  // Silindi (Dinamik hale getirildi)

  dynamic _getIcon(String? iconName) {
    switch (iconName) {
      case 'fa-circle-info': return FontAwesomeIcons.circleInfo;
      case 'fa-hand': return FontAwesomeIcons.hand;
      case 'fa-lightbulb': return FontAwesomeIcons.lightbulb;
      case 'fa-triangle-exclamation': return FontAwesomeIcons.triangleExclamation;
      case 'fa-heart': return FontAwesomeIcons.heart;
      default: return FontAwesomeIcons.paperPlane;
    }
  }

  Color _getColor(String? hex) {
    if (hex == null || hex.isEmpty) return Colors.cyanAccent;
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) {
      return Color(int.parse('0xFF$hex'));
    }
    return Colors.cyanAccent;
  }

  @override
  Widget build(BuildContext context) {
    bool isEn = context.watch<LanguageProvider>().isEn;
    final provider = context.watch<DistrictProvider>();
    
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Builder(
          builder: (context) {
            final settings = context.watch<DistrictProvider>().districtDetails['settings'] ?? {};
            String titleEn = settings['menu_cek_gonder_en'] ?? "CAPTURE & SEND";
            String titleTr = settings['menu_cek_gonder_tr'] ?? "ÇEK GÖNDER";
            return Text(isEn ? titleEn.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase() : titleTr.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white));
          }
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black26,
            child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient
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

          if (_checkingAuth)
            const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          else
            _buildMainForm(isEn, provider),
        ],
      ),
    );
  }

  Widget _buildMainForm(bool isEn, DistrictProvider provider) {
    final dist = provider.districtDetails['district'] ?? {};
    final String districtLogo = AppConfig.imageUrl(dist['logo'] ?? "");

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 120, 20, 100),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Prominent District Branding (Logo from Admin)
            Center(
              child: Column(
                children: [
                  if (dist['logo'] != null && dist['logo'] != "")
                    Image.network(
                      districtLogo, 
                      height: 80, 
                      errorBuilder: (c, e, s) => const FaIcon(FontAwesomeIcons.route, color: Colors.cyanAccent, size: 40)
                    ),
                  const SizedBox(height: 15),
                  Text(
                    widget.districtName.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    isEn ? "Citizen Interaction Portal" : "Vatandaş Etkileşim Portalı",
                    style: TextStyle(color: Colors.cyanAccent.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            _buildGlassContainer(
              child: Column(
                children: [
                  const FaIcon(FontAwesomeIcons.paperPlane, color: Colors.cyanAccent, size: 30),
                  const SizedBox(height: 15),
                  Text(
                    isEn ? "Have something to share?" : "Bir sorun mu var?",
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isEn ? "Snap, describe and report to the district." : "Fotoğrafını çekin ve belediyeye hemen iletin.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            _buildSectionHeader(isEn ? "SUBMISSION TYPE" : "BAŞVURU TÜRÜ"),
            const SizedBox(height: 15),
            Builder(
              builder: (ctx) {
                final settings = provider.districtDetails['settings'] ?? {};
                List<Map<String, dynamic>> turler = [];
                if (settings['cek_gonder_types'] != null && settings['cek_gonder_types'].toString().isNotEmpty) {
                  try {
                    final parsed = jsonDecode(settings['cek_gonder_types']);
                    if (parsed is List) {
                      for (var item in parsed) {
                        if (item['active'] == true || item['active'] == 'true' || item['active'] == 1) {
                          turler.add({
                            'id': item['id'],
                            'label': item['tr'] ?? '',
                            'labelEn': item['en'] ?? '',
                            'icon': _getIcon(item['icon']),
                            'color': _getColor(item['color']),
                          });
                        }
                      }
                    }
                  } catch (e) {}
                }
                if (turler.isEmpty) {
                  turler = [
                    {'id': 'Bilgilendirme', 'label': 'Bilgi', 'labelEn': 'Info', 'icon': FontAwesomeIcons.circleInfo, 'color': Colors.blueAccent},
                    {'id': 'İstek', 'label': 'İstek', 'labelEn': 'Request', 'icon': FontAwesomeIcons.hand, 'color': Colors.purpleAccent},
                    {'id': 'Öneri', 'label': 'Öneri', 'labelEn': 'Suggestion', 'icon': FontAwesomeIcons.lightbulb, 'color': Colors.orangeAccent},
                    {'id': 'Şikayet', 'label': 'Şikayet', 'labelEn': 'Complaint', 'icon': FontAwesomeIcons.triangleExclamation, 'color': Colors.redAccent},
                    {'id': 'Teşekkür', 'label': 'Teşekkür', 'labelEn': 'Thanks', 'icon': FontAwesomeIcons.heart, 'color': Colors.pinkAccent},
                  ];
                }
                return _buildTurSelection(isEn, turler);
              }
            ),
            const SizedBox(height: 35),

            _buildSectionHeader(isEn ? "PERSONAL INFORMATION" : "KİŞİSEL BİLGİLER"),
            const SizedBox(height: 15),
            _buildGlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildInput(controller: _adSoyadController, label: isEn ? "Full Name" : "Ad Soyad", icon: Icons.person_outline, isEn: isEn, readOnly: _isLoggedIn && _adSoyadController.text.isNotEmpty),
                  _buildInput(controller: _tcNoController, label: isEn ? "TR ID No" : "T.C. Kimlik No", icon: Icons.badge_outlined, keyboardType: TextInputType.number, maxLength: 11, isEn: isEn),
                  _buildInput(controller: _emailController, label: isEn ? "Email" : "E-posta", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, isEn: isEn, readOnly: _isLoggedIn && _emailController.text.isNotEmpty),
                  _buildInput(controller: _telNoController, label: isEn ? "Phone" : "Telefon", icon: Icons.phone_outlined, keyboardType: TextInputType.phone, isEn: isEn, readOnly: _isLoggedIn && _telNoController.text.isNotEmpty),
                ],
              ),
            ),
            const SizedBox(height: 35),

            _buildSectionHeader(isEn ? "DESCRIPTION & PHOTOS" : "AÇIKLAMA VE FOTOĞRAFLAR"),
            const SizedBox(height: 15),
            _buildGlassContainer(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                   _buildInput(controller: _aciklamaController, label: isEn ? "Description" : "Açıklama Yazın", icon: Icons.edit_note, maxLines: 4, isEn: isEn),
                   const SizedBox(height: 20),
                   _buildPhotoUploadGrid(isEn),
                ],
              ),
            ),
            const SizedBox(height: 50),

            _buildSubmitButton(isEn),
          ],
        ),
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child, EdgeInsets padding = const EdgeInsets.all(25)}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: Colors.cyanAccent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildTurSelection(bool isEn, List<Map<String, dynamic>> turler) {
    if (turler.isEmpty) return const SizedBox();
    
    // Son öğeyi geniş butona almak yerine, çift veya tek sayıya göre grid veya tam genişlikte render edelim
    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
          ),
          itemCount: turler.length % 2 == 0 ? turler.length : turler.length - 1,
          itemBuilder: (context, index) {
            final tur = turler[index];
            final isSelected = _selectedTur == tur['id'];
            return _buildTurItem(tur, isSelected, isEn);
          },
        ),
        if (turler.length % 2 != 0) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => setState(() => _selectedTur = turler.last['id']),
            child: _buildTurItem(turler.last, _selectedTur == turler.last['id'], isEn, isFullWidth: true),
          ),
        ]
      ],
    );
  }

  Widget _buildTurItem(Map<String, dynamic> tur, bool isSelected, bool isEn, {bool isFullWidth = false}) {
    return GestureDetector(
      onTap: () => setState(() => _selectedTur = tur['id']),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? tur['color'].withOpacity(0.15) : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? tur['color'] : Colors.white.withOpacity(0.05), width: 1.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(tur['icon'], color: isSelected ? tur['color'] : Colors.white24, size: 24),
            const SizedBox(height: 8),
            Text(isEn ? tur['labelEn'] : tur['label'], style: TextStyle(color: isSelected ? Colors.white : Colors.white38, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    int? maxLength,
    bool isEn = false,
    bool readOnly = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        keyboardType: keyboardType,
        maxLines: maxLines,
        maxLength: maxLength,
        style: TextStyle(color: readOnly ? Colors.white54 : Colors.white, fontSize: 15),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: readOnly ? Colors.cyanAccent.withOpacity(0.5) : Colors.cyanAccent, size: 20),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.white38, fontSize: 13),
          filled: true,
          fillColor: readOnly ? Colors.black26 : Colors.black12,
          counterStyle: const TextStyle(color: Colors.white24, fontSize: 10),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: const BorderSide(color: Colors.white10)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: readOnly ? Colors.white10 : Colors.cyanAccent, width: 1)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        ),
        validator: (v) => v!.isEmpty ? (isEn ? "Please fill this field" : "Lütfen bu alanı doldurun") : null,
      ),
    );
  }

  Widget _buildPhotoUploadGrid(bool isEn) {
    return Row(
      children: List.generate(3, (index) {
        return Expanded(
          child: GestureDetector(
            onTap: () => _photos[index] == null ? _pickImage(index) : null,
            child: Container(
              height: 110,
              margin: EdgeInsets.only(right: index == 2 ? 0 : 12),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: _photos[index] == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const FaIcon(FontAwesomeIcons.camera, color: Colors.white24, size: 20),
                        const SizedBox(height: 8),
                        Text(isEn ? "Add" : "Ekle", style: const TextStyle(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    )
                  : Stack(
                      children: [
                        Positioned.fill(child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(File(_photos[index]!.path), fit: BoxFit.cover))),
                        Positioned(
                          top: 5, right: 5,
                          child: GestureDetector(
                            onTap: () => setState(() => _photos[index] = null),
                            child: CircleAvatar(radius: 12, backgroundColor: Colors.black54, child: const Icon(Icons.close, color: Colors.white, size: 14)),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildSubmitButton(bool isEn) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF06b6d4), Color(0xFF0891b2)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.cyan.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitForm,
        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
        child: _isSubmitting
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(isEn ? "SUBMIT TO MUNICIPALITY" : "BELEDİYEYE GÖNDER", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1)),
      ),
    );
  }

  Future<void> _pickImage(int index) async {
    final isEn = context.read<LanguageProvider>().isEn;
    final ImagePicker picker = ImagePicker();

    // Kamera mı Galeri mi seç
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
                final XFile? img = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
                if (img != null && mounted) setState(() => _photos[index] = img);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: Colors.cyanAccent),
              title: Text(isEn ? 'Choose from Gallery' : 'Galeriden Seç', style: const TextStyle(color: Colors.white)),
              onTap: () async {
                Navigator.pop(ctx);
                final XFile? img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                if (img != null && mounted) setState(() => _photos[index] = img);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    final isEn = context.read<LanguageProvider>().isEn;
    if (_selectedTur.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEn ? 'Please select a submission type.' : 'Lütfen bir başvuru türü seçiniz.')));
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      String? fcmToken;
      try {
        fcmToken = await FirebaseMessaging.instance.getToken();
      } catch (e) {}

      final formDataMap = {
        'basvuru_turu': _selectedTur,
        'ad_soyad': _adSoyadController.text,
        'tc_no': _tcNoController.text,
        'email': _emailController.text,
        'tel_no': _telNoController.text,
        'aciklama': _aciklamaController.text,
        'district_id': widget.districtId,
        'user_id': _userId,
        'fcm_token': fcmToken ?? '',
      };

      final dio.FormData formData = dio.FormData.fromMap(formDataMap);
      for (int i = 0; i < _photos.length; i++) {
        if (_photos[i] != null) {
          formData.files.add(MapEntry('foto${i + 1}', await dio.MultipartFile.fromFile(_photos[i]!.path, filename: 'photo_${i+1}.jpg')));
        }
      }
      final result = await context.read<DistrictProvider>().submitCekGonder(formData);
      if (mounted) {
        if (result['status'] == 'success') _showSuccessDialog(isEn);
        else ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? (isEn ? 'An error occurred.' : 'Bir hata oluştu.'))));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(isEn ? 'Error: $e' : 'Hata: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSuccessDialog(bool isEn) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AlertDialog(
          backgroundColor: const Color(0xFF1e293b),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: Colors.white10)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.greenAccent, size: 60),
              const SizedBox(height: 20),
              Text(isEn ? "SUCCESSFUL" : "BAŞARILI", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 10),
              Text(isEn ? "Your application has been successfully submitted to our municipality." : "Başvurunuz başarıyla belediyemize iletilmiştir.", textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 14)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () { Navigator.pop(context); Navigator.pop(context); },
              child: Text(isEn ? "RETURN TO HOME" : "ANA SAYFAYA DÖN", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
