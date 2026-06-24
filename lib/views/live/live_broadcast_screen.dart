import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../../providers/language_provider.dart';
import 'package:rotarehber_flutter/models/extra_models.dart';

class LiveBroadcastScreen extends StatefulWidget {
  final List<LiveBroadcast> broadcasts;

  const LiveBroadcastScreen({super.key, required this.broadcasts});

  @override
  State<LiveBroadcastScreen> createState() => _LiveBroadcastScreenState();
}

class _LiveBroadcastScreenState extends State<LiveBroadcastScreen> {
  int _selectedIndex = 0;
  late WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initController(0);
  }

  void _initController(int index) {
    final lb = widget.broadcasts[index];

    // iOS (WKWebView) için inline oynatma ve otomatik başlatma izinleri
    late final PlatformWebViewControllerCreationParams params;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF000000))
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _isLoading = true);
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _isLoading = false);
        },
      ));

    // iOS + Facebook: iframe cross-origin engeli nedeniyle doğrudan URL yükle (iPhone Safari UA ile)
    if (lb.facebookUrl != null && lb.facebookUrl!.isNotEmpty && !kIsWeb && Platform.isIOS) {
      _controller.setUserAgent(
        'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
        'AppleWebKit/605.1.15 (KHTML, like Gecko) '
        'Version/17.0 Mobile/15E148 Safari/604.1'
      );
      _controller.loadRequest(Uri.parse(lb.facebookUrl!));
      return; // HTML iframe'e gitme, direkt URL aç
    }

    // Android + Facebook: Windows UA ile iframe embed
    if (lb.facebookUrl != null && lb.facebookUrl!.isNotEmpty) {
      _controller.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
    }

    // YouTube, Facebook (Android) ve diğer tüm yayın türleri için HTML iframe oluşturulup yüklenir
    String htmlContent = _buildHtml(lb);
    String baseUrl = (lb.facebookUrl != null && lb.facebookUrl!.isNotEmpty)
        ? "https://www.facebook.com"
        : "https://rotarehber.com";

    _controller.loadHtmlString(htmlContent, baseUrl: baseUrl);
  }

  String _extractYouTubeId(String url) {
    if (url.contains('v=')) return url.split('v=').last.split('&').first;
    if (url.contains('youtu.be/')) return url.split('youtu.be/').last.split('?').first;
    if (url.contains('embed/')) return url.split('embed/').last.split('?').first;
    return '';
  }

  /// YouTube, Facebook ve diğer platformlar için HTML iframe oluşturur
  String _buildHtml(LiveBroadcast lb) {
    if (lb.youtubeUrl != null && lb.youtubeUrl!.isNotEmpty) {
      final String videoId = _extractYouTubeId(lb.youtubeUrl!);
      return '''<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
.wrap { position: fixed; inset: 0; display: flex; align-items: center; justify-content: center; }
iframe { width: 100vw; height: 56.25vw; max-height: 100vh; border: 0; }
</style>
</head>
<body>
<div class="wrap">
<iframe
  src="https://www.youtube.com/embed/$videoId?autoplay=1&modestbranding=1&rel=0&playsinline=1&fs=1&origin=https://rotarehber.com"
  frameborder="0"
  allow="autoplay; encrypted-media; picture-in-picture; fullscreen"
  allowfullscreen="true"
></iframe>
</div>
</body>
</html>''';
    }

    // Facebook
    if (lb.facebookUrl != null && lb.facebookUrl!.isNotEmpty) {
      final String encoded = Uri.encodeComponent(lb.facebookUrl!);
      return '''<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
<style>
* { margin: 0; padding: 0; box-sizing: border-box; }
html, body { width: 100%; height: 100%; background: #000; overflow: hidden; }
.wrap { position: fixed; inset: 0; display: flex; align-items: center; justify-content: center; }
iframe { width: 100vw; height: 56.25vw; max-height: 100vh; border: 0; }
</style>
</head>
<body>
<div class="wrap">
<iframe
  src="https://www.facebook.com/plugins/video.php?href=$encoded&show_text=false&autoplay=true&mute=false"
  style="overflow:hidden"
  scrolling="no"
  frameborder="0"
  allowfullscreen="true"
  allow="autoplay; clipboard-write; encrypted-media; picture-in-picture; web-share"
></iframe>
</div>
</body>
</html>''';
    }

    return '<html><body style="background:#000"></body></html>';
  }

  @override
  Widget build(BuildContext context) {
    final bool isEn = context.watch<LanguageProvider>().isEn;

    if (widget.broadcasts.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF0f172a),
        appBar: AppBar(
          title: Text(isEn ? 'Live Broadcasts' : 'Canlı Yayınlar'),
          backgroundColor: const Color(0xFF1e293b),
        ),
        body: Center(
          child: Text(
            isEn ? 'No active broadcasts.' : 'Aktif yayın bulunamadı.',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final lb = widget.broadcasts[_selectedIndex];
    final String title = isEn ? (lb.titleEn ?? lb.title) : lb.title;
    final String description = isEn
        ? (lb.descriptionEn?.isNotEmpty == true ? lb.descriptionEn! : (lb.description ?? ''))
        : (lb.description ?? '');

    return Scaffold(
      backgroundColor: const Color(0xFF0f172a),
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF1e293b),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Video alanı - 16:9 oranında, tam genişlik
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: [
                WebViewWidget(controller: _controller),
                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(color: Colors.red),
                  ),
              ],
            ),
          ),

          // Birden fazla yayın varsa liste göster
          if (widget.broadcasts.length > 1) _buildBroadcastList(isEn),

          // Açıklama
          if (description.isNotEmpty)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.live_tv, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(5)),
                          child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(description, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.6)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBroadcastList(bool isEn) {
    return Container(
      height: 60,
      color: const Color(0xFF1e293b),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: widget.broadcasts.length,
        itemBuilder: (context, i) {
          final bool selected = i == _selectedIndex;
          final String t = isEn
              ? (widget.broadcasts[i].titleEn ?? widget.broadcasts[i].title)
              : widget.broadcasts[i].title;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedIndex = i;
                _isLoading = true;
              });
              _initController(i);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: selected ? Colors.redAccent : Colors.white12,
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(t, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: selected ? FontWeight.bold : FontWeight.normal)),
            ),
          );
        },
      ),
    );
  }
}
