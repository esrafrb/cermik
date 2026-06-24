import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/auth_service.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';
import '../config/app_config.dart';

class LoginScreen extends StatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onLoginSuccess;
  const LoginScreen({super.key, this.isEmbedded = false, this.onLoginSuccess});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  
  bool _isLoading = false;
  bool _otpSent = false;
  bool _isQuickLogin = false; // Toggle between Quick (OTP) and Standard (Email/Pass)
  int? _tempUserId;
  String? _errorMessage;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);
    _fadeController.forward();
    _otpFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _otpFocusNode.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _setError(String? msg) => setState(() => _errorMessage = msg);

  Future<void> _handleQuickLogin() async {
    if (_phoneController.text.length < 10) {
      _setError('Lütfen geçerli bir telefon numarası giriniz.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await AuthService.quickLogin(_phoneController.text.trim());
      
      if (res['status'] == 'needs_otp') {
        setState(() {
          _otpSent = true;
          _tempUserId = res['temp_user_id'];
          _isLoading = false;
        });
        _fadeController.reset();
        _fadeController.forward();
      } else {
        _setError(res['message'] ?? 'Kod gönderilemedi.');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _setError('Bir hata oluştu: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleStandardLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _setError('Lütfen e-posta ve şifrenizi giriniz.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await AuthService.login(
        identity: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (res['status'] == 'success') {
        if (widget.isEmbedded) {
          if (widget.onLoginSuccess != null) widget.onLoginSuccess!();
        } else if (mounted) {
          Navigator.pop(context, true);
        }
      } else if (res['status'] == 'needs_otp') {
        setState(() {
          _otpSent = true;
          _tempUserId = res['temp_user_id'] is int ? res['temp_user_id'] : int.tryParse(res['temp_user_id'].toString());
          _isLoading = false;
        });
        _fadeController.reset();
        _fadeController.forward();
      } else {
        _setError(res['message'] ?? 'Giriş başarısız.');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _setError('Giriş hatası: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleVerifyOtp() async {
    String otpCode = _otpController.text;
    if (otpCode.length != 6) {
      _setError('Lütfen 6 haneli doğrulama kodunu eksiksiz giriniz.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await AuthService.verifyOtp(
        otpCode: otpCode,
        tempUserId: _tempUserId!,
      );

      if (res['status'] == 'success') {
        if (widget.isEmbedded) {
          if (widget.onLoginSuccess != null) widget.onLoginSuccess!();
        } else if (mounted) {
          Navigator.pop(context, true);
        }
      } else if (res['status'] == 'needs_profile_completion') {
        // Redirect to Register/Profile Completion screen
        if (mounted) {
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (context) => RegisterScreen(
                tempUserId: res['user_id'],
                phone: _phoneController.text,
              ),
            ),
          );
        }
        setState(() => _isLoading = false);
      } else {
        _setError(res['message'] ?? 'Kod hatalı veya süresi dolmuş.');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _setError('Doğrulama hatası: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: Stack(
        children: [
          // Background Gradient
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

          // Glass Accents
          Positioned(
            top: -150, right: -150,
            child: _buildBlurCircle(400, Colors.cyanAccent.withOpacity(0.08)),
          ),
          Positioned(
            bottom: -150, left: -150,
            child: _buildBlurCircle(400, Colors.blueAccent.withOpacity(0.05)),
          ),

          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildLogo(),
                    const SizedBox(height: 40),
                    
                    if (!_otpSent) _buildToggleSelection(),
                    const SizedBox(height: 30),

                    _buildGlassContainer(
                      child: Column(
                        children: [
                          if (_otpSent) 
                            _buildOtpSection()
                          else if (_isQuickLogin)
                            _buildPhoneSection()
                          else
                            _buildStandardSection(),
                          
                          if (_errorMessage != null) _buildErrorBadge(),
                        ],
                      ),
                    ),

                    const SizedBox(height: 30),
                    if (!_otpSent) _buildFooterLinks(),
                    
                    const SizedBox(height: 40),
                    _buildLegalText(),
                  ],
                ),
              ),
            ),
          ),

          if (_isLoading) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  Widget _buildBlurCircle(double size, Color color) {
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      child: BackdropFilter(filter: ImageFilter.blur(sigmaX: 70, sigmaY: 70), child: const SizedBox()),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Hero(
          tag: 'app_logo',
          child: Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
              boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.1), blurRadius: 40, spreadRadius: -10)],
            ),
            child: Image.network(
              "${AppConfig.baseMediaUrl}splash_logo.png",
              width: 80,
              height: 80,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) => Image.network(
                "${AppConfig.baseMediaUrl}assets/img/logo/logo.png",
                width: 80,
                height: 80,
                fit: BoxFit.contain,
                errorBuilder: (c, e, s) => const FaIcon(FontAwesomeIcons.locationDot, color: Colors.cyanAccent, size: 45),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleSelection() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          _buildToggleButton("Şifre ile Giriş", !_isQuickLogin, () => setState(() => _isQuickLogin = false)),
          _buildToggleButton("Hızlı Giriş", _isQuickLogin, () => setState(() => _isQuickLogin = true)),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool active, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? Colors.cyanAccent.withOpacity(0.8) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.black87 : Colors.white54,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassContainer({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withOpacity(0.08)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildPhoneSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('TELEFON NUMARASI', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 15),
        _buildTextField(
          controller: _phoneController,
          hint: '05xx xxx xx xx',
          icon: Icons.phone_android_rounded,
          type: TextInputType.phone,
          formatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(11)],
        ),
        const SizedBox(height: 30),
        _buildActionButton(label: 'DOĞRULAMA KODU GÖNDER', onPressed: _handleQuickLogin),
      ],
    );
  }

  Widget _buildStandardSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('E-POSTA VEYA TELEFON', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _emailController,
          hint: 'user@example.com',
          icon: Icons.alternate_email_rounded,
        ),
        const SizedBox(height: 25),
        const Text('ŞİFRE', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 12),
        _buildTextField(
          controller: _passwordController,
          hint: '••••••••',
          icon: Icons.lock_outline_rounded,
          isObscure: true,
        ),
        const SizedBox(height: 30),
        _buildActionButton(label: 'GİRİŞ YAP', onPressed: _handleStandardLogin),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => const ForgotPasswordScreen())),
            child: const Text('Şifremi Unuttum', style: TextStyle(color: Colors.white38, fontSize: 12)),
          ),
        ),
      ],
    );
  }

  Widget _buildOtpSection() {
    return Column(
      children: [
        const Text('SMS DOĞRULAMA', style: TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
        const SizedBox(height: 25),
        Stack(
          alignment: Alignment.center,
          children: [
            Opacity(
              opacity: 0.0,
              child: SizedBox(
                height: 55,
                child: TextField(
                  controller: _otpController,
                  focusNode: _otpFocusNode,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  maxLength: 6,
                  onChanged: (v) {
                    setState(() {});
                    if (v.length == 6) {
                      _otpFocusNode.unfocus();
                    }
                  },
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ),
            GestureDetector(
              onTap: () => FocusScope.of(context).requestFocus(_otpFocusNode),
              child: Container(
                color: Colors.transparent,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (index) => _buildOtpBox(index)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 40),
        _buildActionButton(label: 'GİRİŞİ TAMAMLA', onPressed: _handleVerifyOtp),
        const SizedBox(height: 20),
        TextButton(
          onPressed: () {
            setState(() {
              _otpSent = false;
              _otpController.clear();
            });
          },
          child: const Text('NUMARAYI DEĞİŞTİR', style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isObscure = false,
    TextInputType type = TextInputType.text,
    List<TextInputFormatter>? formatters,
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
        inputFormatters: formatters,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
          prefixIcon: Icon(icon, color: Colors.cyanAccent.withOpacity(0.7), size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  Widget _buildActionButton({required String label, required VoidCallback onPressed}) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF06b6d4), Color(0xFF0891b2)]),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.2), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        child: Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
      ),
    );
  }

  Widget _buildErrorBadge() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
            const SizedBox(width: 10),
            Expanded(child: Text(_errorMessage!, style: const TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterLinks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('Hesabınız yok mu?', style: TextStyle(color: Colors.white38, fontSize: 13)),
        TextButton(
          onPressed: () => Navigator.push(context, CupertinoPageRoute(builder: (context) => const RegisterScreen())),
          child: const Text('Kayıt Ol', style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildLegalText() {
    return const Text(
      'Giriş yaparak kullanım koşullarını ve gizlilik politikasını kabul etmiş olursunuz.',
      textAlign: TextAlign.center,
      style: TextStyle(color: Colors.white24, fontSize: 11, height: 1.5),
    );
  }

  Widget _buildLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black45,
        child: const Center(child: CircularProgressIndicator(color: Colors.cyanAccent)),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    String digit = "";
    if (_otpController.text.length > index) {
      digit = _otpController.text[index];
    }
    bool isFocused = _otpFocusNode.hasFocus && (_otpController.text.length == index || (_otpController.text.length == 6 && index == 5));

    return Container(
      width: 42,
      height: 55,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: digit.isNotEmpty 
              ? Colors.cyanAccent 
              : (isFocused ? Colors.cyanAccent.withOpacity(0.5) : Colors.white.withOpacity(0.08))
        ),
      ),
      child: Text(
        digit,
        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
      ),
    );
  }
}

