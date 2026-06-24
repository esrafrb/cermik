import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:rotarehber_flutter/providers/district_provider.dart';
import '../../providers/language_provider.dart';
import '../../config/app_config.dart';
import 'package:rotarehber_flutter/models/extra_models.dart';

class EventListScreen extends StatefulWidget {
  final String? districtId;
  final String districtName;

  const EventListScreen({
    super.key, 
    this.districtId,
    required this.districtName,
  });

  @override
  State<EventListScreen> createState() => _EventListScreenState();
}

class _EventListScreenState extends State<EventListScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<DistrictProvider>().fetchEvents(widget.districtId ?? ""));
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
            Text(isEn ? "EVENTS" : "ETKİNLİKLER", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2, color: Colors.white)),
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
            child: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
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
          
          if (provider.isLoadingEvents)
            const Center(child: CircularProgressIndicator(color: Colors.cyanAccent))
          else if (provider.events.isEmpty)
            _buildEmptyState(isEn)
          else
            _buildEventList(provider.events, isEn),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isEn) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.event_note_outlined, color: Colors.white12, size: 80),
          const SizedBox(height: 20),
          Text(isEn ? "No upcoming events found" : "Aktif bir etkinlik bulunamadı", style: const TextStyle(color: Colors.white38, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildEventList(List<Event> events, bool isEn) {
    final now = DateTime.now();

    // Gelecek etkinlikler (en yakın tarih önce)
    final upcoming = events
        .where((e) => e.eventDate != null && DateTime.tryParse(e.eventDate!) != null
            && DateTime.parse(e.eventDate!).isAfter(now))
        .toList()
      ..sort((a, b) => DateTime.parse(a.eventDate!).compareTo(DateTime.parse(b.eventDate!)));

    // Geçmiş etkinlikler (en son geçen önce)
    final past = events
        .where((e) => e.eventDate != null && DateTime.tryParse(e.eventDate!) != null
            && !DateTime.parse(e.eventDate!).isAfter(now))
        .toList()
      ..sort((a, b) => DateTime.parse(b.eventDate!).compareTo(DateTime.parse(a.eventDate!)));

    // Tarihi olmayanlar en sona
    final noDate = events.where((e) => e.eventDate == null || DateTime.tryParse(e.eventDate!) == null).toList();

    final sorted = [...upcoming, ...past, ...noDate];
    final pastSet = past.toSet();

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 140, 20, 40),
      itemCount: sorted.length,
      itemBuilder: (context, index) {
        final event = sorted[index];
        final isPast = pastSet.contains(event);
        return Opacity(
          opacity: isPast ? 0.45 : 1.0,
          child: _buildEventCard(event, isEn, isPast: isPast),
        );
      },
    );
  }

  Widget _buildEventCard(Event item, bool isEn, {bool isPast = false}) {
    final String imageUrl = item.image != null && item.image!.isNotEmpty
        ? AppConfig.imageUrl(item.image!)
        : "https://via.placeholder.com/800x400?text=Event+Image";

    final dateStr = item.eventDate != null 
        ? DateFormat('dd MMMM yyyy', isEn ? 'en_US' : 'tr_TR').format(DateTime.parse(item.eventDate!))
        : "";

    final dateColor = isPast ? Colors.grey : Colors.cyanAccent;

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
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Container(color: Colors.black26, height: 180, child: const Icon(Icons.broken_image, color: Colors.white12)),
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
                    if (item.locationName != null)
                      Positioned(
                        bottom: 12, left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: Colors.cyanAccent, size: 12),
                              const SizedBox(width: 5),
                              Text(item.locationName!, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                            ],
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
                      Row(
                        children: [
                          Icon(Icons.calendar_today_rounded, color: dateColor, size: 14),
                          const SizedBox(width: 8),
                          Text(dateStr, style: TextStyle(color: dateColor, fontSize: 11, fontWeight: FontWeight.w900)),
                          if (isPast) ...[const SizedBox(width: 8), Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(6)), child: const Text('GEÇTİ', style: TextStyle(color: Colors.white38, fontSize: 9, fontWeight: FontWeight.bold)))],
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        (isEn ? (item.titleEn ?? item.title) : item.title),
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                      ),
                      const SizedBox(height: 5),
                      Container(
                        height: 2, width: 40,
                        decoration: BoxDecoration(color: isPast ? Colors.white24 : Colors.cyanAccent, borderRadius: BorderRadius.circular(1)),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        (isEn ? (item.descriptionEn ?? item.description) : item.description) ?? "",
                        style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13, height: 1.5),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
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
