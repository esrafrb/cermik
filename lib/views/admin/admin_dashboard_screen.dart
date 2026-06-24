import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../providers/language_provider.dart';
import '../../services/auth_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/app_config.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<dynamic> _recentCekGonder = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final session = await AuthService.getSession();
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/admin/stats'),
        headers: {
          'X-User-Role': session['userRole'] ?? '',
          'X-District-Id': session['userDistrictId'] ?? '0',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['status'] == 'success') {
          setState(() {
            _stats = data['data']['stats'];
            _recentCekGonder = data['data']['recent_cek_gonder'];
            _isLoading = false;
          });
        } else {
          setState(() => _error = data['message']);
        }
      } else {
        setState(() => _error = "Sunucu hatası: ${response.statusCode}");
      }
    } catch (e) {
      setState(() => _error = "Hata oluştu: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEn = context.watch<LanguageProvider>().isEn;

    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      appBar: AppBar(
        title: Text(isEn ? "Admin Dashboard" : "Yönetim Paneli", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.cyan),
            onPressed: _fetchDashboardData,
          )
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.cyan))
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: Colors.redAccent)))
              : RefreshIndicator(
                  onRefresh: _fetchDashboardData,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStatsGrid(),
                        const SizedBox(height: 30),
                        _buildSectionTitle(isEn ? "Recent Submissions" : "Son Paylaşımlar"),
                        const SizedBox(height: 15),
                        _buildRecentList(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 4, height: 16, decoration: BoxDecoration(color: Colors.cyan, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase(), style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 15,
      crossAxisSpacing: 15,
      childAspectRatio: 1.4,
      children: [
        _buildStatCard("Çek-Gönder", _stats['cek_gonder']?.toString() ?? "0", FontAwesomeIcons.paperPlane, Colors.blue),
        _buildStatCard("Yerleşkeler", _stats['places']?.toString() ?? "0", FontAwesomeIcons.mapLocationDot, Colors.green),
        _buildStatCard("İşletmeler", _stats['businesses']?.toString() ?? "0", FontAwesomeIcons.shop, Colors.orange),
        _buildStatCard("Bekleyen Onay", _stats['pending_events']?.toString() ?? "0", FontAwesomeIcons.calendarCheck, Colors.purple),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 10),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildRecentList() {
    if (_recentCekGonder.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: Text("Bekleyen ileti yok.", style: TextStyle(color: Colors.white38))),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _recentCekGonder.length,
      itemBuilder: (context, index) {
        final item = _recentCekGonder[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.03),
            borderRadius: BorderRadius.circular(15),
          ),
          child: ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.white10, child: Icon(Icons.email_outlined, color: Colors.cyan, size: 18)),
            title: Text(item['ad_soyad'] ?? "İsimsiz", style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
            subtitle: Text(item['basvuru_turu'] ?? "Bilinmiyor", style: const TextStyle(color: Colors.white38, fontSize: 12)),
            trailing: const Icon(Icons.chevron_right, color: Colors.white24),
            onTap: () {},
          ),
        );
      },
    );
  }
}
