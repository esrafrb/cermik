import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class RealTrafficWidget extends StatefulWidget {
  final double lat;
  final double lng;
  final String title;
  final bool isEn;

  const RealTrafficWidget({
    super.key,
    required this.lat,
    required this.lng,
    required this.title,
    required this.isEn,
  });

  @override
  State<RealTrafficWidget> createState() => _RealTrafficWidgetState();
}

class _RealTrafficWidgetState extends State<RealTrafficWidget> {
  String trafficLabel = "Hesaplanıyor...";
  String densityLabel = "...";
  Color statusColor = Colors.grey;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.isEn) {
      trafficLabel = "Calculating...";
    }
    _fetchTrafficData();
  }

  Future<void> _fetchTrafficData() async {
    const String apiKey = "AIzaSyC7YLV-3m5HZ7B7K7JtHC1910su9ufhLjw";
    final double originLat = widget.lat - 0.02;
    final double originLng = widget.lng - 0.02;

    final String url = 
      "https://maps.googleapis.com/maps/api/distancematrix/json?origins=$originLat,$originLng&destinations=${widget.lat},${widget.lng}&departure_time=now&key=$apiKey";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK' && data['rows'].isNotEmpty) {
          final elements = data['rows'][0]['elements'];
          if (elements.isNotEmpty && elements[0]['status'] == 'OK') {
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

    // Fallback if failed
    _updateUI(-1);
  }

  void _updateUI(double delayPercent) {
    if (!mounted) return;
    final String delayStr = delayPercent.toStringAsFixed(1);
    setState(() {
      isLoading = false;
      if (delayPercent < 0) {
        // API Error or Restricted
        trafficLabel = widget.isEn ? "No Data" : "Veri Yok";
        densityLabel = widget.isEn ? "Unknown" : "Bilinmiyor";
        statusColor = Colors.grey;
      } else if (delayPercent <= 5) {
        trafficLabel = (widget.isEn ? "Fluid" : "Akıcı") + " (+$delayStr%)";
        densityLabel = widget.isEn ? "Light" : "Hafif";
        statusColor = const Color(0xFF48bb78); 
      } else if (delayPercent > 5 && delayPercent <= 15) {
        trafficLabel = (widget.isEn ? "Normal" : "Normal") + " (+$delayStr%)";
        densityLabel = widget.isEn ? "Medium" : "Orta";
        statusColor = const Color(0xFFed8936); 
      } else {
        trafficLabel = (widget.isEn ? "Busy" : "Yoğun") + " (+$delayStr%)";
        densityLabel = widget.isEn ? "Heavy" : "Yoğun";
        statusColor = const Color(0xFFf56565);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
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
              const FaIcon(FontAwesomeIcons.mapLocationDot, color: Colors.cyanAccent, size: 20),
              const SizedBox(width: 10),
              Text(
                widget.isEn ? "Live Traffic Density" : "Canlı Trafik Yoğunluğu", 
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
              ),
            ],
          ),
          const SizedBox(height: 15),

          // Harita
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: SizedBox(
              height: 200,
              width: double.infinity,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(target: LatLng(widget.lat, widget.lng), zoom: 14.5),
                trafficEnabled: true,
                liteModeEnabled: false,
                scrollGesturesEnabled: false,
                zoomGesturesEnabled: false,
                tiltGesturesEnabled: false,
                rotateGesturesEnabled: false,
                mapToolbarEnabled: false,
                mapType: MapType.normal,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                markers: {
                  Marker(
                    markerId: const MarkerId('biz_target'), 
                    position: LatLng(widget.lat, widget.lng), 
                    infoWindow: InfoWindow(title: widget.title)
                  )
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Durum Tablosu
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.03),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.isEn ? "REGION POINT" : "BÖLGE NOKTASI", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
                      Text(widget.isEn ? "TRAFFIC STATUS" : "TRAFİK DURUMU", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
                      Text(widget.isEn ? "DENSITY" : "TAHMİNİ YOĞUNLUK", style: TextStyle(color: Colors.cyanAccent, fontWeight: FontWeight.bold, fontSize: 11, letterSpacing: 1)),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(flex: 3, child: Text(widget.title, style: const TextStyle(color: Colors.white, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              trafficLabel,
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: isLoading
                                ? const SizedBox(height: 12, width: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(
                                    densityLabel,
                                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 15),
          Text(
            widget.isEn 
                ? "This data is calculated using live traffic density from Google Maps Distance Matrix."
                : "Bu veriler Google Maps Canlı Trafik servisinden bölgesel yoğunluk ölçülerek hesaplanmaktadır.",
            style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}
