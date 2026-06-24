import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';

class PharmacyTab extends StatefulWidget {
  final int districtId;

  const PharmacyTab({super.key, required this.districtId});

  @override
  State<PharmacyTab> createState() => _PharmacyTabState();
}

class _PharmacyTabState extends State<PharmacyTab> {
  late Future<List<dynamic>> _pharmaciesFuture;

  @override
  void initState() {
    super.initState();
    _pharmaciesFuture = _fetchPharmacies();
  }

  Future<List<dynamic>> _fetchPharmacies() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/get_duty_pharmacies.php?district_id=${widget.districtId}'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return data['data'] ?? [];
      }
      return [];
    } catch (e) {
      debugPrint('Eczane çekme hatası: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _pharmaciesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00c9ff)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.medical_services_outlined, color: Colors.white.withOpacity(0.3), size: 64),
                const SizedBox(height: 16),
                Text('Bugün için kayıtlı nöbetçi eczane bulunamadı.', 
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16)),
              ],
            ),
          );
        }

        final pharmacies = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 120, 20, 100),
          itemCount: pharmacies.length,
          itemBuilder: (context, index) {
            final p = pharmacies[index];
            return _buildPharmacyCard(p);
          },
        );
      },
    );
  }

  Widget _buildPharmacyCard(dynamic p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.medical_information, color: Colors.redAccent, size: 24),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['name'] ?? 'Eczane', 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                    const Text('Nöbetçi', style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.white30, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text(p['address'] ?? '', style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14))),
            ],
          ),
          const SizedBox(height: 10),
          Builder(builder: (context) {
            final rawPhone  = p['phone']?.toString() ?? '';
            // 'No Phone' veya sadece harf içeriyorsa geçersiz say
            final cleanPhone = rawPhone.replaceAll(RegExp(r'[^\d+]'), '');
            final bool hasPhone = cleanPhone.isNotEmpty && !rawPhone.toLowerCase().contains('no phone');
            return InkWell(
              onTap: hasPhone
                  ? () async {
                      final uri = Uri(scheme: 'tel', path: cleanPhone);
                      try { await launchUrl(uri); } catch (_) {
                        if (await canLaunchUrl(uri)) await launchUrl(uri);
                      }
                    }
                  : null,
              child: Row(
                children: [
                  Icon(Icons.phone_outlined,
                      color: hasPhone ? const Color(0xFF00c9ff) : Colors.white24, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    hasPhone ? rawPhone : 'Telefon bilgisi yok',
                    style: TextStyle(
                      color: hasPhone ? const Color(0xFF00c9ff) : Colors.white30,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(p['name'] + ' ' + p['address'])}')),
                  icon: const Icon(Icons.directions_outlined, size: 18),
                  label: const Text('Yol Tarifi Al', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white.withOpacity(0.05),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
