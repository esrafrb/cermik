import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_config.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Muhtarlıklar Ekranı — Mahalle listesi (Merkez + Köy)
// ─────────────────────────────────────────────────────────────────────────────
class MuhtarliklarScreen extends StatefulWidget {
  final int districtId;
  final String districtName;

  const MuhtarliklarScreen({
    super.key,
    required this.districtId,
    required this.districtName,
  });

  @override
  State<MuhtarliklarScreen> createState() => _MuhtarliklarScreenState();
}

class _MuhtarliklarScreenState extends State<MuhtarliklarScreen> {
  bool _isLoading = true;
  String? _error;
  List<dynamic> _merkezList = [];
  List<dynamic> _koyList    = [];

  @override
  void initState() {
    super.initState();
    _fetchMuhtarlar();
  }

  Future<void> _fetchMuhtarlar() async {
    try {
      final uri = Uri.parse(
        '${AppConfig.webBaseUrl}/api/muhtarlar.php?district_id=${widget.districtId}',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 15));
      if (res.statusCode == 200) {
        final data = json.decode(utf8.decode(res.bodyBytes));
        if (data['status'] == 'success' && mounted) {
          setState(() {
            _merkezList = List<dynamic>.from(data['data']['merkez'] ?? []);
            _koyList    = List<dynamic>.from(data['data']['koy'] ?? []);
            _isLoading  = false;
          });
          return;
        }
      }
      if (mounted) setState(() { _error = 'Veri alınamadı.'; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = 'Bağlantı hatası: $e'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: Stack(
        children: [
          // Arka plan gradyanı
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.6,
                  colors: [Color(0xFF1e293b), Color(0xFF0f172a)],
                ),
              ),
            ),
          ),

          // İçerik
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF00c9ff)))
                      : _error != null
                          ? Center(child: Text(_error!, style: const TextStyle(color: Colors.white54)))
                          : _buildList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 12),
      decoration: BoxDecoration(
        color: const Color(0xFF0f172a).withOpacity(0.6),
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Muhtarlıklar',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                widget.districtName,
                style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final bool hasMerkez = _merkezList.isNotEmpty;
    final bool hasKoy    = _koyList.isNotEmpty;

    if (!hasMerkez && !hasKoy) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_work_outlined, color: Colors.white.withOpacity(0.15), size: 64),
            const SizedBox(height: 16),
            Text(
              'Henüz muhtar eklenmemiştir.',
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 15),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchMuhtarlar,
      color: const Color(0xFF00c9ff),
      backgroundColor: const Color(0xFF1e293b),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        children: [
          if (hasMerkez) ...[
            _buildSectionHeader('Merkez Mahalle Muhtarları', Icons.location_city_outlined),
            const SizedBox(height: 12),
            ..._merkezList.map((m) => _buildMuhtarCard(m)),
            const SizedBox(height: 24),
          ],
          if (hasKoy) ...[
            _buildSectionHeader('Köy Mahalle Muhtarları', Icons.nature_outlined),
            const SizedBox(height: 12),
            ..._koyList.map((m) => _buildMuhtarCard(m)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF00c9ff), size: 18),
        const SizedBox(width: 8),
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF00c9ff),
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Divider(color: Colors.white.withOpacity(0.08))),
      ],
    );
  }

  Widget _buildMuhtarCard(dynamic m) {
    final String resim = m['resim']?.toString() ?? '';
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        CupertinoPageRoute(builder: (_) => MuhtarDetayScreen(muhtar: m)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.07)),
        ),
        child: Row(
          children: [
            // Fotoğraf — Belediye Başkanı ile aynı oran (radius: 30)
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white.withOpacity(0.08),
              backgroundImage: resim.isNotEmpty ? NetworkImage(resim) : null,
              child: resim.isEmpty
                  ? const Icon(Icons.person, color: Color(0xFF00c9ff), size: 28)
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m['mahalle_adi']?.toString() ?? '',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    m['muhtar_adi']?.toString() ?? '',
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.2), size: 22),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Muhtar Detay Ekranı
// ─────────────────────────────────────────────────────────────────────────────
class MuhtarDetayScreen extends StatelessWidget {
  final dynamic muhtar;
  const MuhtarDetayScreen({super.key, required this.muhtar});

  @override
  Widget build(BuildContext context) {
    final String resim    = muhtar['resim']?.toString() ?? '';
    final String adi      = muhtar['muhtar_adi']?.toString() ?? '';
    final String mahalle  = muhtar['mahalle_adi']?.toString() ?? '';
    final String aciklama = muhtar['aciklama']?.toString() ?? '';
    final String telefon  = muhtar['telefon']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.4,
                  colors: [Color(0xFF1e293b), Color(0xFF0f172a)],
                ),
              ),
            ),
          ),
          CustomScrollView(
            slivers: [
              // Header (fotoğraf + isim)
              SliverToBoxAdapter(child: _buildHeader(context, resim, adi, mahalle)),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (aciklama.isNotEmpty) ...[
                        const Text(
                          'HAKKINDA',
                          style: TextStyle(
                            color: Color(0xFF00c9ff),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.03),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.07)),
                          ),
                          child: Text(
                            aciklama,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              height: 1.65,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                      if (telefon.isNotEmpty)
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () => launchUrl(Uri.parse('tel:$telefon')),
                            icon: const Icon(Icons.phone_outlined, size: 22),
                            label: Text(
                              telefon,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00c9ff),
                              foregroundColor: Colors.black,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                              elevation: 0,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, String resim, String adi, String mahalle) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 60, 24, 36),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF00c9ff).withOpacity(0.15),
            Colors.transparent,
          ],
        ),
      ),
      child: Column(
        children: [
          // Geri butonu
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 20),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 12),
          // Fotoğraf — radius 50 (profil sayfasıyla aynı)
          CircleAvatar(
            radius: 50,
            backgroundColor: const Color(0xFF00c9ff).withOpacity(0.2),
            child: CircleAvatar(
              radius: 46,
              backgroundColor: Colors.white.withOpacity(0.05),
              backgroundImage: resim.isNotEmpty ? NetworkImage(resim) : null,
              child: resim.isEmpty
                  ? const Icon(Icons.person, size: 48, color: Color(0xFF00c9ff))
                  : null,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            adi,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.home_work_outlined, color: Color(0xFF00c9ff), size: 14),
              const SizedBox(width: 6),
              Text(
                mahalle,
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFF00c9ff).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF00c9ff).withOpacity(0.3)),
            ),
            child: const Text(
              'Mahalle Muhtarı',
              style: TextStyle(color: Color(0xFF00c9ff), fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
