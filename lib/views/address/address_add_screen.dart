import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/language_provider.dart';
import '../../services/order_service.dart';

class AddressAddScreen extends StatefulWidget {
  const AddressAddScreen({super.key});

  @override
  State<AddressAddScreen> createState() => _AddressAddScreenState();
}

class _AddressAddScreenState extends State<AddressAddScreen> {
  final _titleCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _districtCtrl = TextEditingController(text: 'Çermik'); // Sabit İlçe
  final _cityCtrl = TextEditingController(text: 'Diyarbakır'); // Sabit il
  bool _isDefault = false;
  bool _isLoading = false;

  Future<void> _save() async {
    final title = _titleCtrl.text.trim();
    final address = _addressCtrl.text.trim();

    if (title.isEmpty || address.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başlık ve açık adres zorunludur.')),
      );
      return;
    }

    // Token kontrolü — SharedPreferences'tan doğrudan oku (ApiService.token null olsa bile çalışır)
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Adres eklemek için giriş yapmanız gerekiyor.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    setState(() => _isLoading = true);

    final res = await OrderService.addAddress(
      title: title,
      fullAddress: address,
      district: _districtCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      isDefault: _isDefault,
    );

    if (mounted) setState(() => _isLoading = false);

    if (res['status'] == 'success') {
      Navigator.pop(context);
    } else {
      final msg = res['message'] ?? 'Hata oluştu';
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _addressCtrl.dispose();
    _districtCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEn = context.watch<LanguageProvider>().isEn;

    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      appBar: AppBar(
        title: Text(
          isEn ? "Add Address" : "Adres Ekle",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1e293b),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTextField(
              isEn ? "Address Title (e.g. Home, Work)" : "Adres Başlığı (Ev, İş vb.)",
              _titleCtrl,
              Icons.label_outline,
            ),
            const SizedBox(height: 15),
            _buildTextField(
              isEn ? "Full Address" : "Açık Adres",
              _addressCtrl,
              Icons.map_outlined,
              maxLines: 3,
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                // İlçe sabit "Çermik" — düzenlenemez
                Expanded(
                  child: TextField(
                    controller: _districtCtrl,
                    enabled: false,
                    style: const TextStyle(color: Colors.white70),
                    decoration: InputDecoration(
                      labelText: isEn ? "District" : "İlçe",
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      prefixIcon: const Icon(Icons.location_city_outlined, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                // İl sabit "Diyarbakır" — düzenlenemez
                Expanded(
                  child: TextField(
                    controller: _cityCtrl,
                    enabled: false,
                    style: const TextStyle(color: Colors.white70),
                    decoration: InputDecoration(
                      labelText: isEn ? "City" : "İl",
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.03),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: SwitchListTile(
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
                title: Text(
                  isEn ? "Set as Default Address" : "Varsayılan Adres Yap",
                  style: const TextStyle(color: Colors.white),
                ),
                activeColor: Colors.cyanAccent,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : Text(
                        isEn ? "SAVE ADDRESS" : "ADRESİ KAYDET",
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, IconData icon, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: Colors.cyanAccent),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
