import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import '../config/app_config.dart';

class Web360View extends StatefulWidget {
  final String panoramaUrl;
  final bool isEmbedded;

  const Web360View({super.key, required this.panoramaUrl, this.isEmbedded = false});

  @override
  State<Web360View> createState() => _Web360ViewState();
}

class _Web360ViewState extends State<Web360View> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black);

    _loadContent();
  }

  @override
  void didUpdateWidget(Web360View oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.panoramaUrl != widget.panoramaUrl) {
      _loadContent();
    }
  }

  void _loadContent() {
    if (widget.panoramaUrl.contains('insta360.com')) {
      // Web'deki ile birebir aynı: iframe + negatif margin ile üst UI gizleme
      String p360 = widget.panoramaUrl;
      String separator = p360.contains('?') ? '&' : '?';
      String embedUrl = "$p360${separator}help=0&gui=0&brand=0&title=0&share=0&logo=0";

      String html = '''
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body { background: #000; overflow: hidden; width: 100vw; height: 100vh; }
                .wrapper {
                    width: 100%;
                    height: 100%;
                    overflow: hidden;
                    position: relative;
                }
                iframe {
                    width: 100%;
                    height: calc(100% + 160px);
                    margin-top: -140px;
                    border: none;
                    background: transparent;
                }
            </style>
        </head>
        <body>
            <div class="wrapper">
                <iframe 
                    src="$embedUrl" 
                    allowfullscreen 
                    allow="accelerometer; gyroscope; magnetometer; vr"
                ></iframe>
            </div>
        </body>
        </html>
      ''';
      _controller.loadHtmlString(html);
    } else {
      String imageUrl = AppConfig.imageUrl(widget.panoramaUrl);
      // Web panelindeki Pannellum config — dokunmatik sürükleme aktif
      String htmlTemplate = '''
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no, viewport-fit=cover">
            <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/pannellum@2.5.6/build/pannellum.css"/>
            <script type="text/javascript" src="https://cdn.jsdelivr.net/npm/pannellum@2.5.6/build/pannellum.js"></script>
            <style>
                * { margin: 0; padding: 0; }
                body { margin: 0; padding: 0; background: #000; overflow: hidden; }
                #panorama { width: 100vw; height: 100vh; }
                .pnlm-controls-container { display: ${widget.isEmbedded ? 'none' : 'block'}; }
            </style>
        </head>
        <body>
            <div id="panorama"></div>
            <script>
                pannellum.viewer('panorama', {
                    "type": "equirectangular",
                    "panorama": "$imageUrl",
                    "autoLoad": true,
                    "autoRotate": -2,
                    "compass": false,
                    "showZoomCtrl": ${widget.isEmbedded ? 'false' : 'true'},
                    "mouseZoom": true,
                    "showFullscreenCtrl": false,
                    "draggable": true,
                    "disableKeyboardCtrl": false,
                    "touchPanSpeedCoeffFactor": 1
                });
            </script>
        </body>
        </html>
      ''';
      _controller.loadHtmlString(htmlTemplate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(
      controller: _controller,
      gestureRecognizers: {
        Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
      },
    );
  }
}

