import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';
import 'package:rotarehber_flutter/providers/district_provider.dart';
import '../../config/app_config.dart';
import 'package:rotarehber_flutter/models/extra_models.dart';

class ServiceListScreen extends StatefulWidget {
  final String? districtId;
  final String districtName;

  final VoidCallback? onBackPressed;

  const ServiceListScreen({
    super.key, 
    this.districtId,
    required this.districtName,
    this.onBackPressed,
  });

  @override
  State<ServiceListScreen> createState() => _ServiceListScreenState();
}

class _ServiceListScreenState extends State<ServiceListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<int> _expandedItems = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() => context.read<DistrictProvider>().fetchServices(widget.districtId ?? ""));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEn = context.watch<LanguageProvider>().isEn;
    final provider = context.watch<DistrictProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isEn ? "PROJECTS & SERVICES" : "PROJELER VE HİZMETLER", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white)),
            Text(widget.districtName.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.cyanAccent, fontWeight: FontWeight.bold, letterSpacing: 2)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black54, Colors.transparent],
            ),
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: Colors.black26,
            child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20), onPressed: () {
              if (widget.onBackPressed != null) {
                widget.onBackPressed!();
              } else {
                Navigator.pop(context);
              }
            }),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              height: 45,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.03),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.cyanAccent.withOpacity(0.1),
                ),
                labelColor: Colors.cyanAccent,
                unselectedLabelColor: Colors.white38,
                labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                tabs: [
                  Tab(text: isEn ? "COMPLETED" : "TAMAMLANAN"),
                  Tab(text: isEn ? "ONGOING" : "DEVAM EDEN"),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0f172a), Color(0xFF1e293b), Color(0xFF0f172a)],
                ),
              ),
            ),
          ),
          
          if (provider.isLoadingServices)
            const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          else
            _buildTabViews(provider, isEn),
        ],
      ),
    );
  }

  Widget _buildTabViews(DistrictProvider provider, bool isEn) {
    final services = provider.services;
    final ongoing = services.where((s) => s.status.toString() == '0').toList();
    final completed = services.where((s) => s.status.toString() == '1').toList();

    return TabBarView(
      controller: _tabController,
      physics: const BouncingScrollPhysics(),
      children: [
        _buildProjectList(completed, isEn ? "No completed projects found" : "Tamamlanan proje bulunamadı", isEn),
        _buildProjectList(ongoing, isEn ? "No ongoing projects found" : "Devam eden proje bulunamadı", isEn),
      ],
    );
  }

  Widget _buildProjectList(List<Service> items, String emptyMsg, bool isEn) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.architecture_outlined, color: Colors.white12, size: 80),
            const SizedBox(height: 20),
            Text(emptyMsg, style: const TextStyle(color: Colors.white38, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 160, left: 20, right: 20, bottom: 40),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildProjectCard(items[index], isEn),
    );
  }

  Widget _buildProjectCard(Service item, bool isEn) {
    final String imageUrl = item.image != null && item.image!.isNotEmpty
        ? AppConfig.imageUrl(item.image!)
        : "https://via.placeholder.com/800x400?text=Project+Image";
    
    final bool isCompleted = item.status.toString() == '1';
    final bool isExpanded = _expandedItems.contains(item.id);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Image.network(
                      imageUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(color: Colors.black26, height: 200, child: const Icon(Icons.broken_image, color: Colors.white12)),
                    ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 15, right: 15,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isCompleted ? Colors.greenAccent : Colors.orangeAccent,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: (isCompleted ? Colors.greenAccent : Colors.orangeAccent).withOpacity(0.3), blurRadius: 10)],
                        ),
                        child: Text(
                          isCompleted ? (isEn ? "COMPLETED" : "TAMAMLANDI") : (isEn ? "ONGOING" : "DEVAM EDİYOR"),
                          style: const TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isEn ? (item.titleEn ?? item.title) : item.title, 
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                      ),
                      const SizedBox(height: 5),
                      Container(
                        height: 2, width: 40,
                        decoration: BoxDecoration(color: Colors.cyanAccent, borderRadius: BorderRadius.circular(1)),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        isEn ? (item.descriptionEn ?? item.description ?? "") : (item.description ?? ""),
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.5),
                        maxLines: isExpanded ? null : 3,
                        overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () {
                          setState(() {
                            if (isExpanded) {
                              _expandedItems.remove(item.id);
                            } else {
                              _expandedItems.add(item.id);
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isExpanded 
                                  ? (isEn ? "Show Less" : "Daha Az Gör") 
                                  : (isEn ? "Read More" : "Devamını Gör"),
                                style: const TextStyle(
                                  color: Colors.cyanAccent, 
                                  fontSize: 12, 
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, 
                                color: Colors.cyanAccent, 
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (item.progress > 0 && !isCompleted) ...[
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: LinearProgressIndicator(
                                  value: item.progress / 100,
                                  backgroundColor: Colors.white10,
                                  color: Colors.cyanAccent,
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 15),
                            Text("${item.progress}%", style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.w900, fontSize: 12)),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
