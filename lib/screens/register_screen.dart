import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../providers/district_provider.dart';
import 'package:provider/provider.dart';
import 'otp_verification_screen.dart';
import '../constants/turkey_districts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import '../config/app_config.dart';


class RegisterScreen extends StatefulWidget {
  final int? tempUserId;
  final String? phone;

  const RegisterScreen({super.key, this.tempUserId, this.phone});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  
  int? _selectedDistrictId;
  String? _selectedDistrictName;
  String _selectedCity = 'Diyarbakır';
  bool _isLoading = false;
  String? _errorMessage;
  bool _acceptedTerms = false;


  @override
  void initState() {
    super.initState();
    if (widget.phone != null) {
      _phoneController.text = widget.phone!;
    }
    Future.microtask(() {
      context.read<DistrictProvider>().fetchDistricts();
    });
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_acceptedTerms) {
      setState(() => _errorMessage = 'Kayıt olmak için sözleşmeleri onaylamanız gerekmektedir.');
      return;
    }

    if (_firstNameController.text.isEmpty || 
        _lastNameController.text.isEmpty || 
        _emailController.text.isEmpty || 
        _passwordController.text.isEmpty ||
        _selectedDistrictName == null) {
      setState(() => _errorMessage = 'Lütfen tüm alanları doldurunuz.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Eğer veritabanında eşleşen ilçe varsa onun ID'sini gönder
      final districts = context.read<DistrictProvider>().districts;
      int? matchedId;
      for (var d in districts) {
        if (d.name.toLowerCase() == _selectedDistrictName!.toLowerCase()) {
          matchedId = d.id;
          break;
        }
      }

      final Map<String, dynamic> data = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'district_id': matchedId ?? 0,
        'district_name': _selectedDistrictName,
        'city': _selectedCity,
        'phone': _phoneController.text.trim(),
        if (widget.tempUserId != null) 'temp_user_id': widget.tempUserId,
      };

      final res = await AuthService.register(data);

      if (res['status'] == 'success') {
        if (mounted) {
           Navigator.of(context).popUntil((route) => route.isFirst);
        }
      } else if (res['status'] == 'needs_otp') {
        if (mounted) {
          Navigator.of(context).push(
            CupertinoPageRoute(
              builder: (context) => OtpVerificationScreen(
                tempUserId: res['temp_user_id'],
                phone: _phoneController.text.trim().isEmpty ? (widget.phone ?? '') : _phoneController.text.trim(),
              ),
            ),
          );
        }
      } else {
        setState(() {
          _errorMessage = res['message'] ?? 'Kayıt başarısız.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Hata: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF0f172a), Color(0xFF1e293b), Color(0xFF0f172a)],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(30),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'KAYIT OL',
                    style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 2),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Profilinizi tamamlayarak aramıza katılın.',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 40),

                  _buildGlassField(
                    controller: _firstNameController,
                    hint: 'Adınız',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 15),
                  _buildGlassField(
                    controller: _lastNameController,
                    hint: 'Soyadınız',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 15),
                  _buildGlassField(
                    controller: _emailController,
                    hint: 'E-posta Adresiniz',
                    icon: Icons.alternate_email,
                    type: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 15),
                  _buildGlassField(
                    controller: _passwordController,
                    hint: 'Şifreniz',
                    icon: Icons.lock_outline,
                    isObscure: true,
                  ),
                  const SizedBox(height: 15),
                  _buildGlassField(
                    controller: _phoneController,
                    hint: 'Telefon Numaranız',
                    icon: Icons.phone_android,
                    type: TextInputType.phone,
                  ),
                  const SizedBox(height: 15),
                                   // İl Seçimi (Varsayılan Diyarbakır)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCity,
                        hint: const Text('İl Seçiniz', style: TextStyle(color: Colors.white38, fontSize: 15)),
                        dropdownColor: const Color(0xFF1e293b),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.cyanAccent),
                        isExpanded: true,
                        items: TurkeyDistricts.cities.map((city) {
                          return DropdownMenuItem<String>(
                            value: city,
                            child: Text(city, style: const TextStyle(color: Colors.white, fontSize: 15)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedCity = val;
                              _selectedDistrictName = null; // İl değiştiğinde ilçe sıfırla
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  
                  // İlçe Seçimi — Diyarbakır ise tüm ilçeleri göster, diğer iller için serbest metin
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedDistrictName,
                        hint: const Text('İlçe Seçiniz', style: TextStyle(color: Colors.white38, fontSize: 15)),
                        dropdownColor: const Color(0xFF1e293b),
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.cyanAccent),
                        isExpanded: true,
                        menuMaxHeight: 350,
                        items: TurkeyDistricts.getDistricts(_selectedCity).map((name) {
                          return DropdownMenuItem<String>(
                            value: name,
                            child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 15)),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _selectedDistrictName = val),
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  if (_errorMessage != null) 
                    Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  const SizedBox(height: 10),
                  _buildTermsCheckbox(),
                  const SizedBox(height: 20),
                  
                  _buildActionButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black45,
                child: const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGlassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isObscure = false,
    TextInputType type = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: TextField(
        controller: controller,
        obscureText: isObscure,
        keyboardType: type,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Colors.white38),
          prefixIcon: Icon(icon, color: Colors.cyanAccent.withOpacity(0.7), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF06b6d4), Color(0xFF0891b2)]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ElevatedButton(
        onPressed: _handleRegister,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: const Text('KAYDI TAMAMLA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.2)),
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return Theme(
      data: Theme.of(context).copyWith(
        unselectedWidgetColor: Colors.white38,
      ),
      child: CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: Colors.cyanAccent,
        checkColor: Colors.black,
        value: _acceptedTerms,
        onChanged: (val) {
          setState(() {
            _acceptedTerms = val ?? false;
            if (_acceptedTerms) _errorMessage = null;
          });
        },
        title: GestureDetector(
          onTap: () => _showLegalDocument(),
          child: const Text(
            'KVKK Aydınlatma Metni ve Mesafeli Satış Sözleşmesi\'ni okudum, onaylıyorum.',
            style: TextStyle(color: Colors.cyanAccent, fontSize: 13, decoration: TextDecoration.underline),
          ),
        ),
      ),
    );
  }

  Future<void> _showLegalDocument() async {
    String url = '${AppConfig.baseMediaUrl}kvkk-aydinlatma.php';

    late final WebViewController webController;
    webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFf0f4f8))
      ..enableZoom(false)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) {
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
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFF1e293b),
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 15),
            Center(
              child: Container(
                width: 50, height: 5,
                decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
              )
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      'KVKK VE SÖZLEŞMELER',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
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
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                child: WebViewWidget(
                  controller: webController,
                  gestureRecognizers: {
                    Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
                    Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
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
