import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/language_provider.dart';
import '../../services/order_service.dart';
import '../address/address_list_screen.dart';
import '../home/home_screen.dart'; // To redirect after success

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  List<dynamic> _addresses = [];
  int? _selectedAddressId;
  String _paymentMethod = 'cash'; // 'cash' veya 'pos'
  bool _isLoading = true;
  final _noteCtrl = TextEditingController(); // 🆕 Not alanı

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    final addrs = await OrderService.getAddresses();
    if (mounted) {
      setState(() {
        _addresses = addrs;
        if (_addresses.isNotEmpty) {
          final def = _addresses.firstWhere((a) => a['is_default'] == 1, orElse: () => _addresses.first);
          _selectedAddressId = def['id'];
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _placeOrder() async {
    FocusManager.instance.primaryFocus?.unfocus();
    if (_selectedAddressId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lütfen bir adres seçin veya ekleyin.')));
      return;
    }

    final cart = context.read<CartProvider>();
    final isEn = context.read<LanguageProvider>().isEn;

    setState(() => _isLoading = true);
    final res = await OrderService.createOrder(
      businessId: cart.businessId!,
      addressId: _selectedAddressId!,
      items: cart.items.map((i) => i.toJson()).toList().cast<Map<String, dynamic>>(),
      totalPrice: cart.totalPrice,
      paymentMethod: _paymentMethod,
      note: _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : null,
    );

    if (mounted) setState(() => _isLoading = false);

    if (res['status'] == 'success') {
      int orderId = res['order_id'];
      _showOtpDialog(orderId, isEn);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Hata oluştu'), backgroundColor: Colors.redAccent));
    }
  }

  void _showOtpDialog(int orderId, bool isEn) {
    final TextEditingController otpController = TextEditingController();
    bool isVerifying = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      backgroundColor: const Color(0xFF1e293b),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom, left: 25, right: 25, top: 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.sms_outlined, color: Colors.cyanAccent, size: 50),
                  const SizedBox(height: 15),
                  Text(isEn ? "SMS Verification" : "SMS Doğrulama", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(
                    isEn ? "Enter the 6-digit code sent to your phone." : "Telefonunuza gönderilen 6 haneli kodu giriniz.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 25),
                  TextField(
                    controller: otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 10, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      counterText: "",
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                      hintText: "••••••",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.2), letterSpacing: 10),
                    ),
                  ),
                  const SizedBox(height: 25),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: isVerifying ? null : () async {
                        final code = otpController.text.trim();
                        if (code.length != 6) return;

                        FocusManager.instance.primaryFocus?.unfocus();
                        setModalState(() => isVerifying = true);
                        final res = await OrderService.verifyOrder(orderId, code);
                        setModalState(() => isVerifying = false);

                        if (res['status'] == 'success') {
                          Navigator.pop(ctx); // Close modal
                          context.read<CartProvider>().clearCart(); // Clear cart
                          _showSuccessScreen(isEn);
                        } else {
                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(res['message'] ?? 'Hata'), backgroundColor: Colors.redAccent));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.cyanAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: isVerifying
                          ? const CircularProgressIndicator(color: Colors.black)
                          : Text(isEn ? "VERIFY" : "DOĞRULA", style: const TextStyle(fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }
        );
      }
    );
  }

  void _showSuccessScreen(bool isEn) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 80),
            const SizedBox(height: 20),
            Text(isEn ? "Order Confirmed!" : "Sipariş Onaylandı!", style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(
              isEn ? "Your order has been successfully placed." : "Siparişiniz işletmeye başarıyla iletildi.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              onPressed: () {
                Navigator.of(ctx).popUntil((route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
              child: Text(isEn ? "BACK TO HOME" : "ANA SAYFAYA DÖN"),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEn = context.watch<LanguageProvider>().isEn;
    final cart = context.watch<CartProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      appBar: AppBar(
        title: Text(isEn ? "Checkout" : "Siparişi Tamamla", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        backgroundColor: const Color(0xFF1e293b),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: (_addresses.isEmpty || _isLoading) ? null : _placeOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                disabledBackgroundColor: Colors.white24,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.black)
                  : Text(isEn ? "CONFIRM ORDER" : "SİPARİŞİ ONAYLA", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 1)),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : GestureDetector(
              onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
              child: SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(20),
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEn ? "DELIVERY ADDRESS" : "TESLİMAT ADRESİ", style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  if (_addresses.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          const Icon(Icons.location_off_outlined, color: Colors.white24, size: 40),
                          const SizedBox(height: 10),
                          Text(isEn ? "No address found." : "Kayıtlı adresiniz bulunmuyor.", style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 10),
                          OutlinedButton.icon(
                            onPressed: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListScreen()));
                              _loadAddresses();
                            },
                            icon: const Icon(Icons.add, color: Colors.cyanAccent),
                            label: Text(isEn ? "Add Address" : "Adres Ekle", style: const TextStyle(color: Colors.cyanAccent)),
                          )
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          ..._addresses.map((a) {
                            return RadioListTile<int>(
                              value: a['id'],
                              groupValue: _selectedAddressId,
                              onChanged: (val) => setState(() => _selectedAddressId = val),
                              activeColor: Colors.cyanAccent,
                              title: Text(a['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                              subtitle: Text(a['full_address'] ?? '', style: const TextStyle(color: Colors.white70)),
                            );
                          }),
                          TextButton(
                            onPressed: () async {
                              await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressListScreen()));
                              _loadAddresses();
                            },
                            child: Text(isEn ? "Manage Addresses" : "Adresleri Yönet", style: const TextStyle(color: Colors.cyanAccent)),
                          )
                        ],
                      ),
                    ),

                  const SizedBox(height: 30),
                  Text(isEn ? "PAYMENT METHOD" : "ÖDEME YÖNTEMİ", style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
                    child: Column(
                      children: [
                        RadioListTile<String>(
                          value: 'cash',
                          groupValue: _paymentMethod,
                          onChanged: (val) => setState(() => _paymentMethod = val!),
                          activeColor: Colors.cyanAccent,
                          title: Text(isEn ? "Cash on Delivery" : "Kapıda Ödeme (Nakit)", style: const TextStyle(color: Colors.white)),
                          secondary: const Icon(Icons.payments_outlined, color: Colors.greenAccent),
                        ),
                        if (cart.hasPosDevice) ...[
                          Divider(color: Colors.white.withOpacity(0.1), height: 1),
                          RadioListTile<String>(
                            value: 'pos',
                            groupValue: _paymentMethod,
                            onChanged: (val) => setState(() => _paymentMethod = val!),
                            activeColor: Colors.cyanAccent,
                            title: Text(isEn ? "POS on Delivery" : "Kapıda Ödeme (Pos Cihazı Getir)", style: const TextStyle(color: Colors.white)),
                            secondary: const Icon(Icons.credit_card_outlined, color: Colors.orangeAccent),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),
                  Text(isEn ? "ORDER NOTE (OPTIONAL)" : "SİPARİŞ NOTU (İSTEĞE BAĞLI)", style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _noteCtrl,
                    maxLines: 3,
                    maxLength: 300,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: isEn ? "e.g. No onions, ring the doorbell..." : "Örn: Soğansız olsun, zil çalın...",
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Icon(Icons.edit_note_outlined, color: Colors.cyanAccent),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.05),
                      counterStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                    ),
                  ),

                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: const Color(0xFF1e293b), borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.cyanAccent.withOpacity(0.2))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(isEn ? "Total to Pay:" : "Ödenecek Tutar:", style: const TextStyle(color: Colors.white, fontSize: 16)),
                        Text("₺${cart.totalPrice.toStringAsFixed(2)}", style: const TextStyle(color: Colors.greenAccent, fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
    );
  }
}
