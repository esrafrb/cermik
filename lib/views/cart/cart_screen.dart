import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/language_provider.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final isEn = context.watch<LanguageProvider>().isEn;

    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      appBar: AppBar(
        title: Text(isEn ? "My Cart" : "Sepetim", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        backgroundColor: const Color(0xFF1e293b),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (!cart.isEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              onPressed: () {
                cart.clearCart();
              },
            ),
        ],
      ),
      body: cart.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.white.withOpacity(0.2)),
                  const SizedBox(height: 20),
                  Text(
                    isEn ? "Your cart is empty" : "Sepetiniz boş",
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                  color: Colors.cyanAccent.withOpacity(0.1),
                  child: Text(
                    isEn ? "Ordering from: ${cart.businessName}" : "Sipariş verilen: ${cart.businessName}",
                    style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: cart.items.length,
                    itemBuilder: (ctx, i) {
                      final item = cart.items[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: item.imageUrl.isNotEmpty
                                  ? Image.network(item.imageUrl, width: 60, height: 60, fit: BoxFit.cover, errorBuilder: (_,__,___)=> _placeholder())
                                  : _placeholder(),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                  if (item.variantName != null)
                                    Text(item.variantName!, style: TextStyle(color: Colors.cyanAccent.withOpacity(0.8), fontSize: 12)),
                                  const SizedBox(height: 5),
                                  Text("₺${item.unitPrice.toStringAsFixed(2)}", style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.white54),
                                  onPressed: () => context.read<CartProvider>().updateQuantity(i, item.quantity - 1),
                                ),
                                Text('${item.quantity}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, color: Colors.cyanAccent),
                                  onPressed: () => context.read<CartProvider>().updateQuantity(i, item.quantity + 1),
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1e293b),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, -5))],
                  ),
                  child: Row(
                    children: [
                      // Sol: Toplam Tutar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            isEn ? "Total Amount" : "Toplam Tutar",
                            style: const TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 0.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "₺${cart.totalPrice.toStringAsFixed(2)}",
                            style: const TextStyle(color: Colors.greenAccent, fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      // Sağ: Siparişi Tamamla Butonu
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(context, CupertinoPageRoute(builder: (ctx) => const CheckoutScreen()));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyanAccent,
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                            child: Text(
                              isEn ? "CHECKOUT" : "SİPARİŞİ TAMAMLA",
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.8),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              ],
            ),
    );
  }

  Widget _placeholder() => Container(width: 60, height: 60, color: Colors.white10, child: const Icon(Icons.fastfood, color: Colors.white24));
}
