import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../config/app_config.dart';
import '../../services/lang_service.dart';
import '../content_detail_screen.dart';

class AnnouncementsTab extends StatefulWidget {
  final int districtId;

  const AnnouncementsTab({super.key, required this.districtId});

  @override
  State<AnnouncementsTab> createState() => _AnnouncementsTabState();
}

class _AnnouncementsTabState extends State<AnnouncementsTab> {
  late Future<List<dynamic>> _announcementsFuture;

  @override
  void initState() {
    super.initState();
    _announcementsFuture = ApiService.getAnnouncements(districtId: widget.districtId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _announcementsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF00c9ff)));
        }

        final announcements = snapshot.data ?? [];

        if (announcements.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.campaign_outlined, color: Colors.white.withOpacity(0.3), size: 64),
                const SizedBox(height: 16),
                Text(langService.t('Şu an güncel bir duyuru bulunmuyor.', en: 'No updates or announcements at the moment.'),
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 120, 20, 100),
          itemCount: announcements.length,
          itemBuilder: (context, index) {
            return _buildAnnouncementCard(announcements[index]);
          },
        );
      },
    );
  }

  Widget _buildAnnouncementCard(dynamic ann) {
    final String? imageUrl = ann['image'] != null && ann['image'].toString().isNotEmpty
        ? AppConfig.imageUrl(ann['image'])
        : null;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          CupertinoPageRoute(
            builder: (c) => ContentDetailScreen(
              contentId: ann['id'],
              type: ContentType.announcement,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: Image.network(
                  imageUrl,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => const SizedBox.shrink(),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00c9ff).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(langService.t('DUYURU', en: 'ANNOUNCEMENT'),
                            style: const TextStyle(color: Color(0xFF00c9ff), fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const Spacer(),
                      if (ann['created_at'] != null)
                        Text(
                          _formatDate(ann['created_at']),
                          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    ann['title'] ?? '',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16, height: 1.4),
                  ),
                  const SizedBox(height: 8),
                  if (ann['content'] != null && ann['content'].toString().isNotEmpty)
                    Text(
                      ann['content'],
                      style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 13, height: 1.6),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      if (langService.isEn) {
        final monthsEn = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return '${dt.day} ${monthsEn[dt.month - 1]} ${dt.year}';
      }
      final months = ['Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz', 'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara'];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return raw;
    }
  }
}

