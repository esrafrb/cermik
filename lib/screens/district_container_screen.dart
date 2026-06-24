import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/sidebar_menu.dart';
import '../config/app_config.dart';
import '../services/lang_service.dart';
import 'tabs/discover_tab.dart';
import 'tabs/events_tab.dart';
import 'tabs/announcements_tab.dart';
import 'tabs/services_tab.dart';
import 'tabs/profile_tab.dart';

class DistrictContainerScreen extends StatefulWidget {
  final Map<String, dynamic> district;
  final int initialIndex;

  const DistrictContainerScreen({super.key, required this.district, this.initialIndex = 0});

  @override
  State<DistrictContainerScreen> createState() => _DistrictContainerScreenState();
}

class _DistrictContainerScreenState extends State<DistrictContainerScreen> {
  int _currentIndex = 0;
  Map<String, dynamic>? _details;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _fetchDetails();
    
    // Dil değişirse sayfayı yenile
    langService.addListener(_onLangChanged);
  }

  @override
  void dispose() {
    langService.removeListener(_onLangChanged);
    super.dispose();
  }

  void _onLangChanged() {
    if (mounted) _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    final res = await ApiService.getDistrictDetails(widget.district['id']);
    if (mounted) {
      setState(() {
        _details = res;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Web: .section-bg
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      extendBody: true,
      endDrawer: _details == null ? null : SidebarMenu(
        districtSettings: {
          'id': widget.district['id'],
          'name': widget.district['name'],
          'slug': widget.district['slug'] ?? _details!['slug'],
          'district_id': widget.district['id'],
          ...?(_details!['settings'] as Map?),
        },
        onTabSelected: (index) {
          setState(() => _currentIndex = index);
          Navigator.pop(context); // Close drawer
        },
      ),
      body: Stack(
        children: [
          // Background (Web: .theme-bg)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topRight,
                  radius: 1.5,
                  colors: [Color(0xFF1e293b), Color(0xFF0f172a)],
                ),
              ),
            ),
          ),

          // Content (Tabs)
          IndexedStack(
            index: _currentIndex,
            children: [
              DiscoverTab(district: widget.district, details: _details),
              EventsTab(districtId: widget.district['id']),
              AnnouncementsTab(districtId: widget.district['id']),
              ServicesTab(districtId: widget.district['id'], districtName: widget.district['name']),
              const ProfileTab(),
            ],
          ),

          // Header (Web: .header)
          _buildHeader(),

          // Bottom Nav (Web: .nav-bar)
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: FloatingBottomNavBar(
              currentIndex: _currentIndex,
              onTabSelected: (index) {
                if (index == 2) {
                  // Yakındaki İlçeler (Home)
                  Navigator.pop(context);
                } else {
                  setState(() => _currentIndex = index);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: Container(
        height: 100,
        padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
        decoration: BoxDecoration(
          color: const Color(0xFF0f172a).withOpacity(0.4),
          border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.08))),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_outlined, color: Color(0xFF00c9ff), size: 24),
                const SizedBox(width: 8),
                Text('${(_details?['weather'] as Map?)?['temp'] ?? '--'}°', 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
              ],
            ),
            
            // Web: #site-logo + Title
            InkWell(
              onTap: () => Navigator.pop(context),
              child: Row(
                children: [
                  Image.network(AppConfig.imageUrl('assets/img/logo/logo.png'), height: 40, 
                    errorBuilder: (c, e, s) => const Icon(Icons.location_on, color: Color(0xFF00c9ff))),
                  const SizedBox(width: 10),
                  Text((_details?['settings'] as Map?)?['site_name']?.toString() ?? widget.district['name'], 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                ],
              ),
            ),


            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu, color: Colors.white70),
                onPressed: () => Scaffold.of(context).openEndDrawer(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
