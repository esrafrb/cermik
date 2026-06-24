import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../config/app_config.dart';
import '../services/lang_service.dart';

enum ContentType { announcement, event }

class ContentDetailScreen extends StatefulWidget {
  final dynamic contentId;
  final ContentType type;

  const ContentDetailScreen({
    super.key,
    required this.contentId,
    required this.type,
  });

  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    Map<String, dynamic>? res;
    if (widget.type == ContentType.announcement) {
      res = await ApiService.getAnnouncementDetails(widget.contentId);
    } else {
      res = await ApiService.getEventDetails(widget.contentId);
    }

    if (mounted) {
      setState(() {
        _data = res;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1e293b).withOpacity(0.5),
        elevation: 0,
        title: Text(
          widget.type == ContentType.announcement 
            ? langService.t('Duyuru Detayı', en: 'Announcement Detail')
            : langService.t('Etkinlik Detayı', en: 'Event Detail'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00c9ff)))
          : _data == null
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          Text(langService.t('İçerik yüklenemedi.', en: 'Could not load content details.'),
              style: const TextStyle(color: Colors.white70)),
          TextButton(onPressed: _fetchDetails, child: const Text('Tekrar Dene')),
        ],
      ),
    );
  }

  Widget _buildContent() {
    final String? imageUrl = _data!['image'] != null ? AppConfig.imageUrl(_data!['image']) : null;
    final String title = _data!['title'] ?? '';
    final String description = _data!['description'] ?? _data!['content'] ?? '';
    final String dateStr = _data!['event_date'] ?? _data!['created_at'] ?? '';

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Hero Image ──
          if (imageUrl != null)
            Container(
              height: 250,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.cover),
              ),
            ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (widget.type == ContentType.event ? Colors.purple : Colors.blue).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    (widget.type == ContentType.event 
                      ? langService.t('ETKİNLİK', en: 'EVENT')
                      : langService.t('DUYURU', en: 'ANNOUNCEMENT')),
                    style: TextStyle(
                      color: (widget.type == ContentType.event ? Colors.purpleAccent : Colors.blueAccent),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Title
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),

                // Date
                Row(
                  children: [
                    const Icon(Icons.calendar_month_outlined, color: Colors.white30, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(dateStr),
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                // Content
                const Divider(color: Colors.white10),
                const SizedBox(height: 25),
                Text(
                  description,
                  style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15, height: 1.7),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd.MM.yyyy HH:mm').format(dt);
    } catch (_) {
      return raw;
    }
  }
}
