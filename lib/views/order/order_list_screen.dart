import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../services/order_service.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  bool _isLoading = true;
  List<dynamic> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final orders = await OrderService.getMyOrders();
    if (mounted) {
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEn = context.watch<LanguageProvider>().isEn;

    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      appBar: AppBar(
        title: Text(isEn ? "My Orders" : "Siparişlerim", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        backgroundColor: const Color(0xFF1e293b),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : _orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long_outlined, size: 80, color: Colors.white.withOpacity(0.2)),
                      const SizedBox(height: 20),
                      Text(
                        isEn ? "You have no orders yet." : "Henüz siparişiniz bulunmuyor.",
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  color: Colors.cyanAccent,
                  backgroundColor: const Color(0xFF1e293b),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      return _buildOrderItem(order, isEn);
                    },
                  ),
                ),
    );
  }

  Widget _buildOrderItem(dynamic order, bool isEn) {
    final status = order['status'] ?? 'pending';
    Color statusColor = Colors.orangeAccent;
    String statusText = isEn ? "Pending" : "Beklemede";

    if (status == 'approved') {
      statusColor = Colors.tealAccent;
      statusText = isEn ? "Approved" : "Onaylandı";
    } else if (status == 'preparing') {
      statusColor = Colors.blueAccent;
      statusText = isEn ? "Preparing" : "Hazırlanıyor";
    } else if (status == 'on_way') {
      statusColor = Colors.cyanAccent;
      statusText = isEn ? "On The Way" : "Yola Çıktı";
    } else if (status == 'delivered') {
      statusColor = Colors.greenAccent;
      statusText = isEn ? "Delivered" : "Teslim Edildi";
    } else if (status == 'cancelled') {
      statusColor = Colors.redAccent;
      statusText = isEn ? "Cancelled" : "İptal Edildi";
    }

    final double total = double.tryParse(order['total_price'].toString()) ?? 0.0;
    final String date = order['created_at']?.toString().substring(0, 10) ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "${isEn ? 'Order' : 'Sipariş'} #${order['id']}",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            isEn ? "Total: ₺${total.toStringAsFixed(2)}" : "Toplam: ₺${total.toStringAsFixed(2)}",
            style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                order['business_name'] ?? '',
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
              ),
              Text(
                date,
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
              ),
            ],
          )
        ],
      ),
    );
  }
}
