import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../providers/notification_provider.dart';
import '../../providers/language_provider.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    bool isEn = context.watch<LanguageProvider>().isEn;
    const bgColor = Color(0xFF0b0f19);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEn ? "Notifications" : "Bildirimler",
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all, color: Colors.white70),
            onPressed: () {
              context.read<NotificationProvider>().clearAll();
            },
          )
        ],
      ),
      body: Consumer<NotificationProvider>(
        builder: (context, provider, child) {
          final notifications = provider.notifications;

          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(FontAwesomeIcons.bellSlash, color: Colors.white.withOpacity(0.1), size: 50),
                  const SizedBox(height: 20),
                  Text(
                    isEn ? "No notifications yet." : "Henüz bildirim yok.",
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notif = notifications[index];
              return _buildNotificationCard(context, notif, provider);
            },
          );
        },
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, AppNotification notif, NotificationProvider provider) {
    return GestureDetector(
      onTap: () {
        if (!notif.isRead) provider.markAsRead(notif.id);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        decoration: BoxDecoration(
          color: notif.isRead ? Colors.white.withOpacity(0.03) : const Color(0xFF06b6d4).withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: notif.isRead ? Colors.white.withOpacity(0.05) : const Color(0xFF06b6d4).withOpacity(0.3),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      notif.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.bold,
                      ),
                    ),
                  ),
                  if (!notif.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF06b6d4),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                notif.body,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
              if (notif.imageUrl != null && notif.imageUrl!.isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: notif.imageUrl!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      height: 150,
                      color: Colors.white.withOpacity(0.05),
                    ),
                    errorWidget: (context, url, error) => const SizedBox(),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FaIcon(FontAwesomeIcons.clock, color: Colors.white.withOpacity(0.3), size: 10),
                  const SizedBox(width: 5),
                  Text(
                    DateFormat('dd.MM.yyyy HH:mm').format(notif.receivedAt),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
