import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

/// Konum haritası + canlı trafik yoğunluğu widget'ı.
/// TAMAMEN NATIVE GoogleMap SDK kullanılarak güncellenmiştir.
class LocationTrafficWidget extends StatefulWidget {
  final double lat;
  final double lng;
  final String title;
  final bool isEn;
  final bool showCheckIn;
  final VoidCallback? onCheckIn;

  const LocationTrafficWidget({
    super.key,
    required this.lat,
    required this.lng,
    required this.title,
    required this.isEn,
    this.showCheckIn = false,
    this.onCheckIn,
  });

  @override
  State<LocationTrafficWidget> createState() => _LocationTrafficWidgetState();
}

class _LocationTrafficWidgetState extends State<LocationTrafficWidget> {
  // HTTP requests for Distance Matrix MUST use an unrestricted key.
  static const String _distanceMatrixApiKey = "AIzaSyC7YLV-3m5HZ7B7K7JtHC1910su9ufhLjw";

  String _trafficLabel = "...";
  String _densityLabel = "...";
  Color _statusColor = Colors.grey;
  bool _isLoading = true;

  late GoogleMapController _locationMapController;
  late GoogleMapController _trafficMapController;

  final String _darkMapStyle = '''
  [
    {"elementType": "geometry", "stylers": [{"color": "#1d2c4d"}]},
    {"elementType": "labels.text.fill", "stylers": [{"color": "#8ec3b9"}]},
    {"elementType": "labels.text.stroke", "stylers": [{"color": "#1a3646"}]},
    {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#304a7d"}]},
    {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#17263c"}]}
  ]
  ''';

  final String _lightMapStyle = '''
  [
    {"elementType": "geometry", "stylers": [{"color": "#f5f5f5"}]},
    {"elementType": "labels.text.fill", "stylers": [{"color": "#333333"}]},
    {"elementType": "labels.text.stroke", "stylers": [{"color": "#ffffff"}]},
    {"featureType": "road", "elementType": "geometry", "stylers": [{"color": "#d6d6d6"}]},
    {"featureType": "water", "elementType": "geometry", "stylers": [{"color": "#b3d4e5"}]}
  ]
  ''';

  /// 06:00 - 20:00 arası gündüz, diğerleri gece
  bool get _isDayTime {
    final hour = DateTime.now().hour;
    return hour >= 6 && hour < 20;
  }

  @override
  void initState() {
    super.initState();
    _trafficLabel = widget.isEn ? "Calculating..." : "Hesaplanıyor...";
    _densityLabel = "...";
    _fetchTrafficData();
  }

  Future<void> _fetchTrafficData() async {
    final double originLat = widget.lat - 0.02;
    final double originLng = widget.lng - 0.02;
    final String url =
        "https://maps.googleapis.com/maps/api/distancematrix/json?origins=$originLat,$originLng&destinations=${widget.lat},${widget.lng}&departure_time=now&key=$_distanceMatrixApiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['rows'] != null && (data['rows'] as List).isNotEmpty) {
          final elements = data['rows'][0]['elements'];
          if (elements != null && (elements as List).isNotEmpty && elements[0]['status'] == 'OK') {
            final durationObj = elements[0]['duration'];
            final trafficObj = elements[0]['duration_in_traffic'];
            if (durationObj != null && trafficObj != null) {
              final int normalTime = durationObj['value'];
              final int trafficTime = trafficObj['value'];
              final double delayPercent = ((trafficTime - normalTime) / normalTime) * 100;
              _updateUI(delayPercent < 0 ? 0 : delayPercent);
              return;
            }
          }
        }
      }
    } catch (_) {}
    // Fallback if failed or denied
    _updateUI(-1);
  }

  void _updateUI(double delayPercent) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (delayPercent < 0) {
        // API Error or Fallback
        _trafficLabel = widget.isEn ? "No Data" : "Veri Yok";
        _densityLabel = widget.isEn ? "Unknown" : "Bilinmiyor";
        _statusColor = Colors.grey;
      } else {
        String percentStr = "(+${delayPercent.toStringAsFixed(1)}%)";
        if (delayPercent <= 5) {
          _trafficLabel = widget.isEn ? "Fluid\n$percentStr" : "Akıcı\n$percentStr";
          _densityLabel = widget.isEn ? "Light" : "Hafif";
          _statusColor = const Color(0xFF48bb78);
        } else if (delayPercent <= 15) {
          _trafficLabel = widget.isEn ? "Normal\n$percentStr" : "Normal\n$percentStr";
          _densityLabel = widget.isEn ? "Medium" : "Orta";
          _statusColor = const Color(0xFFed8936);
        } else {
          _trafficLabel = widget.isEn ? "Busy\n$percentStr" : "Yoğun\n$percentStr";
          _densityLabel = widget.isEn ? "Heavy" : "Yoğun";
          _statusColor = const Color(0xFFf56565);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final String mapStyle = _isDayTime ? _lightMapStyle : _darkMapStyle;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ────── 1) KONUM BİLGİSİ (Native Normal Map) ──────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const FaIcon(FontAwesomeIcons.locationDot, color: Colors.cyanAccent, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    widget.isEn ? "Location Info" : "Konum Bilgisi",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(widget.lat, widget.lng),
                      zoom: 15,
                    ),
                    mapType: MapType.normal,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    onMapCreated: (controller) {
                      _locationMapController = controller;
                      // Saate göre harita stilini uygula
                      _locationMapController.setMapStyle(mapStyle);
                    },
                    markers: {
                      Marker(
                        markerId: const MarkerId('location_marker'),
                        position: LatLng(widget.lat, widget.lng),
                        infoWindow: InfoWindow(title: widget.title),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
                      ),
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),
              // Yol Tarifi Butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final url = 'https://www.google.com/maps/dir/?api=1&destination=\${widget.lat},\${widget.lng}';
                    launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
                  },
                  icon: const FaIcon(FontAwesomeIcons.diamondTurnRight, size: 14),
                  label: Text(
                    widget.isEn ? "Get Directions" : "Yol Tarifi Al",
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06b6d4),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ────── 2) CANLI TRAFİK VE YOĞUNLUK (Native Google Maps + Traffic Layer) ──────
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const FaIcon(FontAwesomeIcons.mapLocationDot, color: Colors.cyanAccent, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    widget.isEn ? "Live Traffic & Density" : "Canlı Trafik ve Yoğunluk",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Google Maps trafik katmanı
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: LatLng(widget.lat, widget.lng),
                      zoom: 14,
                    ),
                    mapType: MapType.normal,
                    trafficEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    onMapCreated: (controller) {
                      _trafficMapController = controller;
                      // Saate göre harita stilini uygula (gündüz açık, gece koyu)
                      _trafficMapController.setMapStyle(mapStyle);
                    },
                    markers: {
                      Marker(
                        markerId: const MarkerId('traffic_marker'),
                        position: LatLng(widget.lat, widget.lng),
                        infoWindow: InfoWindow(title: widget.title),
                        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
                      ),
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),

              // Trafik Durum Tablosu
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.03),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.white12),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              widget.isEn ? "REGION / POINT" : "BÖLGE / NOKTA",
                              style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              widget.isEn ? "TRAFFIC STATUS" : "TRAFİK DURUMU",
                              style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              widget.isEn ? "DENSITY" : "TAHMİNİ YOĞUNLUK",
                              style: const TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 0.5),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Data Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              widget.title,
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: _buildPill(_trafficLabel, _statusColor),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 14,
                                      width: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white54),
                                    )
                                  : _buildPill(_densityLabel, _statusColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Text(
                widget.isEn
                    ? "* Data is updated live from Google Maps."
                    : "* Veriler Google Maps üzerinden anlık olarak güncellenmektedir.",
                style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 11),
      ),
    );
  }
}
