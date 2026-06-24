import 'package:flutter/material.dart';
import '../../config/app_config.dart';
import '../../services/api_service.dart';

class ServicesTab extends StatefulWidget {
  final int districtId;
  final String districtName;

  const ServicesTab({super.key, required this.districtId, required this.districtName});

  @override
  State<ServicesTab> createState() => _ServicesTabState();
}

class _ServicesTabState extends State<ServicesTab> {
  int _currentFilter = 1; // 1: Tamamlanan, 0: Devam Eden (Web default is 1)
  late Future<List<dynamic>> _servicesFuture;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  void _loadServices() {
    setState(() {
      _servicesFuture = ApiService.getServices(districtId: widget.districtId, status: _currentFilter);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 120),
        
        // District Header (Web: .services-header-compact)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              Text(
                '${widget.districtName} Belediye Başkanlığı'.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF00c9ff), fontWeight: FontWeight.w900, fontSize: 16),
              ),
              const SizedBox(height: 5),
              const Text('Hizmetlerimiz ve Projelerimiz', style: TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ),
        
        const SizedBox(height: 20),

        // Filter Tabs (Web: .services-filter-tabs)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              _buildFilterBtn('Tamamlanan', 1, Icons.done_all),
              const SizedBox(width: 10),
              _buildFilterBtn('Devam Eden', 0, Icons.update),
            ],
          ),
        ),

        const SizedBox(height: 15),

        // Services List
        Expanded(
          child: FutureBuilder<List<dynamic>>(
            future: _servicesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFF00c9ff)));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.engineering_outlined, color: Colors.white.withOpacity(0.3), size: 64),
                      const SizedBox(height: 16),
                      Text('Seçilen kategoride proje bulunamadı.', 
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16)),
                    ],
                  ),
                );
              }

              final services = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                itemCount: services.length,
                itemBuilder: (context, index) {
                  return _buildServiceCard(services[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBtn(String label, int status, IconData icon) {
    bool isActive = _currentFilter == status;
    return Expanded(
      child: InkWell(
        onTap: () {
          if (!isActive) {
            setState(() {
              _currentFilter = status;
              _loadServices();
            });
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: isActive ? const Color(0xFF00c9ff) : Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isActive ? const Color(0xFF00c9ff) : Colors.white70),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: isActive ? Colors.white : Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildServiceCard(dynamic svc) {
    final image = svc['image'] != null 
        ? AppConfig.imageUrl(svc['image']) 
        : AppConfig.imageUrl('assets/img/project_default.jpg');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            child: Stack(
              children: [
                Image.network(image, height: 180, width: double.infinity, fit: BoxFit.cover, 
                  errorBuilder: (c, e, s) => Container(color: Colors.black26, height: 180, child: const Icon(Icons.broken_image, color: Colors.white24))),
                Positioned(
                  top: 15, right: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Color(svc['status'] == 1 ? 0xFF10b981 : 0xFFf59e0b).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(svc['status'] == 1 ? 'Tamamlandı' : 'Devam Ediyor', 
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 10)),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(svc['title'] ?? '', 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text(svc['description'] ?? '', 
                  style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
