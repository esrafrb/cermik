import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../business/business_detail_screen.dart';
import '../place/place_detail_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  bool _isScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("KAREKOD OKUT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: (capture) {
              if (_isScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                final String? code = barcode.rawValue;
                if (code != null) {
                  setState(() => _isScanned = true);
                  _handleScannedCode(code);
                  break;
                }
              }
            },
          ),
          // Scanner Overlay Frame (Web Parity Style)
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.cyan, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 20,
                    right: 20,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: Colors.cyan,
                        boxShadow: [BoxShadow(color: Colors.cyan.withOpacity(0.5), blurRadius: 10)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Center(
              child: Text(
                "Lütfen karekodu çerçeve içine odaklayın",
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleScannedCode(String code) {
    // Check for our business/place ID pattern
    try {
      Uri uri = Uri.parse(code);
      String? id = uri.queryParameters['id'];
      String? target = uri.queryParameters['target'];
      
      if (id != null && target != null) {
        int? intId = int.tryParse(id);
        if (intId != null) {
            if (target == 'place') {
              Navigator.pushReplacement(
                context,
                CupertinoPageRoute(
                  builder: (context) => PlaceDetailScreen(placeId: intId),
                ),
              );
            } else if (target == 'business') {
              Navigator.pushReplacement(
                context,
                CupertinoPageRoute(
                  builder: (context) => BusinessDetailScreen(
                    districtId: "0",
                    businessId: id,
                    businessName: "Mekan Detayı",
                  ),
                ),
              );
            } else {
               _showError("Geçersiz Karekod", "Bu karekod tipi desteklenmiyor: $target");
            }
        } else {
           _showError("Geçersiz Karekod", "Karekod numarası hatalı: $id");
        }
      } else {
         _showError("Geçersiz Karekod", "Bu karekod bir rota noktasına ait değil: $code");
      }
    } catch (e) {
      _showError("Hata", "Karekod okunamadı: $code");
    }
  }

  void _showError(String title, String msg) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(title),
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(c);
              setState(() => _isScanned = false);
            },
            child: const Text("TEKRAR DENE"),
          ),
        ],
      ),
    );
  }
}
