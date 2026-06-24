import 'dart:async';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';
import '../models/imsakiye_model.dart';
import '../services/imsakiye_service.dart';
import '../providers/language_provider.dart';

class RamadanTimerWidget extends StatefulWidget {
  final int districtId;

  const RamadanTimerWidget({super.key, required this.districtId});

  @override
  State<RamadanTimerWidget> createState() => _RamadanTimerWidgetState();
}

class _RamadanTimerWidgetState extends State<RamadanTimerWidget> {
  List<ImsakiyeModel>? _imsakiyeList;
  bool _isLoading = true;
  Timer? _timer;
  String _countdownText = "";
  String _titleText = "";
  bool _isBayramMode = false;
  String _bayramNamazi = "";
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final service = ImsakiyeService();
    final data = await service.fetchImsakiye(widget.districtId);
    if (mounted) {
      setState(() {
        _imsakiyeList = data;
        _isLoading = false;
      });
      if (_imsakiyeList != null && _imsakiyeList!.isNotEmpty) {
        _startTimer();
      }
    }
  }

  void _startTimer() {
    _updateTimer();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateTimer();
    });
  }

  void _updateTimer() {
    if (!mounted || _imsakiyeList == null || _imsakiyeList!.isEmpty) return;

    final now = DateTime.now();
    
    // Find today's and tomorrow's records
    ImsakiyeModel? todayRecord;
    ImsakiyeModel? tomorrowRecord;
    
    for (var record in _imsakiyeList!) {
      if (record.date.year == now.year && record.date.month == now.month && record.date.day == now.day) {
        todayRecord = record;
      } else if (record.date.isAfter(now)) {
        if (tomorrowRecord == null) {
          tomorrowRecord = record;
        }
      }
    }

    // Check if today is a Special Day WITHOUT fasting
    if (todayRecord != null && (todayRecord.imsak == null || todayRecord.imsak!.isEmpty || todayRecord.iftar == null || todayRecord.iftar!.isEmpty)) {
      setState(() {
        _isBayramMode = true;
        _titleText = todayRecord!.dayTitle ?? (todayRecord.bayramDay > 0 ? "Ramazan Bayramı ${todayRecord.bayramDay}. Gün" : "Özel Gün");
        _bayramNamazi = todayRecord.bayramNamazi ?? "";
        _imageUrl = todayRecord.imageUrl;
        _countdownText = "";
      });
      _timer?.cancel();
      return;
    }

    // If today is Bayram (Even if it has fasting times, usually Bayram has no fasting, but just in case)
    if (todayRecord != null && todayRecord.bayramDay > 0) {
      setState(() {
        _isBayramMode = true;
        _titleText = todayRecord!.dayTitle ?? "Ramazan Bayramı ${todayRecord.bayramDay}. Gün";
        _bayramNamazi = todayRecord.bayramNamazi ?? "";
        _imageUrl = todayRecord.imageUrl;
        _countdownText = "";
      });
      _timer?.cancel();
      return;
    }

    DateTime? targetTime;
    String targetTitle = "";
    String? targetImageUrl;
    
    // Helper to get title
    String getPrefix(ImsakiyeModel record) {
      return (record.dayTitle != null && record.dayTitle!.isNotEmpty) ? "${record.dayTitle} - " : "";
    }

    if (todayRecord != null) {
      final imsakParts = todayRecord.imsak!.split(':');
      final iftarParts = todayRecord.iftar!.split(':');
      
      final imsakTime = DateTime(now.year, now.month, now.day, int.parse(imsakParts[0]), int.parse(imsakParts[1]), 0);
      final iftarTime = DateTime(now.year, now.month, now.day, int.parse(iftarParts[0]), int.parse(iftarParts[1]), 0);

      if (now.isBefore(imsakTime)) {
        // Night time, waiting for Imsak
        targetTime = imsakTime;
        targetTitle = "${getPrefix(todayRecord)}İmsaka Kalan Süre";
        targetImageUrl = todayRecord.imageUrl;
      } else if (now.isBefore(iftarTime)) {
        // Fasting time, waiting for Iftar
        targetTime = iftarTime;
        targetTitle = "${getPrefix(todayRecord)}İftara Kalan Süre";
        targetImageUrl = todayRecord.imageUrl;
      } else {
        // After Iftar, waiting for tomorrow
        if (tomorrowRecord != null) {
          if (tomorrowRecord.bayramDay > 0 || tomorrowRecord.imsak == null || tomorrowRecord.imsak!.isEmpty) {
            setState(() {
              _isBayramMode = true;
              _titleText = tomorrowRecord!.dayTitle ?? (tomorrowRecord.bayramDay > 0 ? "Yarın Ramazan Bayramı ${tomorrowRecord.bayramDay}. Gün" : "Yarın Özel Gün");
              _bayramNamazi = tomorrowRecord.bayramNamazi ?? "";
              _imageUrl = tomorrowRecord.imageUrl;
              _countdownText = "";
            });
            _timer?.cancel();
            return;
          } else {
            final tImsakParts = tomorrowRecord.imsak!.split(':');
            targetTime = DateTime(tomorrowRecord.date.year, tomorrowRecord.date.month, tomorrowRecord.date.day, int.parse(tImsakParts[0]), int.parse(tImsakParts[1]), 0);
            targetTitle = "${getPrefix(tomorrowRecord)}İmsaka Kalan Süre";
            targetImageUrl = tomorrowRecord.imageUrl;
          }
        }
      }
    } else if (tomorrowRecord != null) {
       // If no today record but we have tomorrow, maybe it starts tomorrow
       if (tomorrowRecord.bayramDay > 0 || tomorrowRecord.imsak == null || tomorrowRecord.imsak!.isEmpty) {
           setState(() {
              _isBayramMode = true;
              _titleText = tomorrowRecord!.dayTitle ?? (tomorrowRecord.bayramDay > 0 ? "Yarın Ramazan Bayramı ${tomorrowRecord.bayramDay}. Gün" : "Yarın Özel Gün");
              _bayramNamazi = tomorrowRecord.bayramNamazi ?? "";
              _imageUrl = tomorrowRecord.imageUrl;
              _countdownText = "";
            });
            _timer?.cancel();
            return;
       } else {
          final tImsakParts = tomorrowRecord.imsak!.split(':');
          targetTime = DateTime(tomorrowRecord.date.year, tomorrowRecord.date.month, tomorrowRecord.date.day, int.parse(tImsakParts[0]), int.parse(tImsakParts[1]), 0);
          targetTitle = "${getPrefix(tomorrowRecord)}İmsaka Kalan Süre";
          targetImageUrl = tomorrowRecord.imageUrl;
       }
    }

    if (targetTime != null) {
      final diff = targetTime.difference(now);
      if (diff.isNegative) {
        _fetchData(); // Refresh if time passed and not caught
        return;
      }

      int days = diff.inDays;
      int hours = diff.inHours % 24;
      int minutes = diff.inMinutes % 60;
      int seconds = diff.inSeconds % 60;

      String cText = "";
      if (days > 0) {
        cText += "$days Gün ";
      }
      cText += "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";

      setState(() {
        _isBayramMode = false;
        _titleText = targetTitle;
        _imageUrl = targetImageUrl;
        _countdownText = cText;
      });
    } else {
      // No target time found (Ramadan over)
      setState(() {
        _imsakiyeList = null; // Hide widget
      });
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox.shrink(); // Don't show loading to avoid jumping UI
    }

    if (_imsakiyeList == null || _imsakiyeList!.isEmpty) {
      return const SizedBox.shrink(); // Auto-hide if no data
    }

    bool isEn = context.watch<LanguageProvider>().isEn;
    
    // Translate titles
    String displayTitle = _titleText;
    if (isEn) {
      if (_titleText == "İftara Kalan Süre") displayTitle = "Time to Iftar";
      if (_titleText == "İmsaka Kalan Süre") displayTitle = "Time to Imsak";
      if (_titleText.contains("Bayramı 1. Gün")) displayTitle = "Eid al-Fitr - Day 1";
      if (_titleText.contains("Bayramı 2. Gün")) displayTitle = "Eid al-Fitr - Day 2";
      if (_titleText.contains("Bayramı 3. Gün")) displayTitle = "Eid al-Fitr - Day 3";
      if (_titleText.contains("Yarın Ramazan Bayramı")) displayTitle = "Tomorrow is Eid!";
    }

    return Container(
      margin: const EdgeInsets.only(top: 10, bottom: 20, left: 20, right: 20),
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
      decoration: BoxDecoration(
        image: (_imageUrl != null && _imageUrl!.isNotEmpty)
            ? DecorationImage(
                image: NetworkImage(_imageUrl!),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.65), BlendMode.darken),
              )
            : null,
        gradient: (_imageUrl == null || _imageUrl!.isEmpty) ? const LinearGradient(
          colors: [
            Color(0xFF1a2639),
            Color(0xFF0f172a),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ) : null,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF06b6d4).withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF06b6d4).withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: 1,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            displayTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              shadows: [
                Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_isBayramMode)
            Column(
              children: [
                if (_bayramNamazi.isNotEmpty)
                  Text(
                    isEn ? "Eid Prayer: $_bayramNamazi" : "Bayram Namazı Vakti: $_bayramNamazi",
                    style: const TextStyle(
                      color: Color(0xFF06b6d4),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 1)),
                      ],
                    ),
                  ),
              ],
            )
          else
            Text(
              _countdownText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                shadows: [
                  Shadow(color: Colors.black, blurRadius: 6, offset: Offset(0, 2)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
