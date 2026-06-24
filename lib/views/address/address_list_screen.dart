import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import '../../services/order_service.dart';
import 'address_add_screen.dart';

class AddressListScreen extends StatefulWidget {
  const AddressListScreen({super.key});

  @override
  State<AddressListScreen> createState() => _AddressListScreenState();
}

class _AddressListScreenState extends State<AddressListScreen> {
  List<dynamic> _addresses = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() => _isLoading = true);
    final addrs = await OrderService.getAddresses();
    if (mounted) {
      setState(() {
        _addresses = addrs;
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteAddress(int id) async {
    final isEn = context.read<LanguageProvider>().isEn;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1e293b),
        title: Text(isEn ? "Delete Address?" : "Adresi Sil?", style: const TextStyle(color: Colors.white)),
        content: Text(isEn ? "Are you sure you want to delete this address?" : "Bu adresi silmek istediğinize emin misiniz?", style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(isEn ? "Cancel" : "İptal")),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(isEn ? "Delete" : "Sil", style: const TextStyle(color: Colors.redAccent))),
        ],
      )
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      await OrderService.deleteAddress(id);
      _loadAddresses();
    }
  }

  Future<void> _setDefault(int id) async {
    setState(() => _isLoading = true);
    await OrderService.setDefaultAddress(id);
    _loadAddresses();
  }

  @override
  Widget build(BuildContext context) {
    final isEn = context.watch<LanguageProvider>().isEn;

    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      appBar: AppBar(
        title: Text(isEn ? "My Addresses" : "Adreslerim", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white)),
        backgroundColor: const Color(0xFF1e293b),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          : _addresses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off_outlined, size: 80, color: Colors.white.withOpacity(0.2)),
                      const SizedBox(height: 20),
                      Text(isEn ? "No address found." : "Kayıtlı adresiniz bulunmuyor.", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _addresses.length,
                  itemBuilder: (ctx, i) {
                    final a = _addresses[i];
                    final isDef = a['is_default'] == 1;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDef ? Colors.cyanAccent.withOpacity(0.5) : Colors.transparent, width: 1),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.location_on, color: isDef ? Colors.cyanAccent : Colors.white54, size: 20),
                                  const SizedBox(width: 8),
                                  Text(a['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                                ],
                              ),
                              if (isDef)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: Colors.cyanAccent.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                  child: Text(isEn ? "Default" : "Varsayılan", style: const TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(a['full_address'] ?? '', style: const TextStyle(color: Colors.white70)),
                          const SizedBox(height: 15),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!isDef)
                                TextButton(
                                  onPressed: () => _setDefault(a['id']),
                                  child: Text(isEn ? "Set Default" : "Varsayılan Yap", style: const TextStyle(color: Colors.cyanAccent)),
                                ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                onPressed: () => _deleteAddress(a['id']),
                              ),
                            ],
                          )
                        ],
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, CupertinoPageRoute(builder: (_) => const AddressAddScreen()));
          _loadAddresses();
        },
        backgroundColor: Colors.cyanAccent,
        icon: const Icon(Icons.add, color: Colors.black),
        label: Text(isEn ? "Add New" : "Yeni Ekle", style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
