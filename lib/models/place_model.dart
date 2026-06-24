import 'dart:convert';

class Place {
  final int id;
  final String name;
  final String? nameEn;
  final String category;
  final String? description;
  final String? descriptionEn;
  final String? hastaliklar;
  final String? hastaliklarEn;
  final double? lat;
  final double? lng;
  final String? aiContext;
  final int popularScore;
  final String? panorama360;
  final List<String> imageGallery;
  final String? imageMain;
  final int districtId;
  final bool isActive;
  final int checkinDay;
  final int checkinMonth;
  final int checkinYear;
  final String? headingHastaliklarTr;
  final String? headingHastaliklarEn;

  Place({
    required this.id,
    required this.name,
    this.nameEn,
    required this.category,
    this.description,
    this.descriptionEn,
    this.hastaliklar,
    this.hastaliklarEn,
    this.headingHastaliklarTr,
    this.headingHastaliklarEn,
    this.lat,
    this.lng,
    this.aiContext,
    this.popularScore = 0,
    this.panorama360,
    this.imageGallery = const [],
    this.imageMain,
    required this.districtId,
    this.isActive = true,
    this.checkinDay = 0,
    this.checkinMonth = 0,
    this.checkinYear = 0,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    List<String> gallery = [];
    if (json['image_gallery'] != null) {
      try {
        if (json['image_gallery'] is String) {
          var decoded = jsonDecode(json['image_gallery']);
          if (decoded is List) gallery = List<String>.from(decoded);
        } else if (json['image_gallery'] is List) {
          gallery = List<String>.from(json['image_gallery']);
        }
      } catch (_) {}
    }

    return Place(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      nameEn: json['name_en'],
      category: json['category'] ?? '',
      description: json['description'],
      descriptionEn: json['description_en'],
      hastaliklar: json['hastaliklar'],
      hastaliklarEn: json['hastaliklar_en'],
      headingHastaliklarTr: json['heading_hastaliklar_tr'],
      headingHastaliklarEn: json['heading_hastaliklar_en'],
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lng: json['lng'] != null ? double.tryParse(json['lng'].toString()) : null,
      aiContext: json['ai_context'],
      popularScore: json['popular_score'] is int ? json['popular_score'] : (int.tryParse(json['popular_score']?.toString() ?? '0') ?? 0),
      panorama360: json['panorama_360'],
      imageGallery: gallery,
      imageMain: json['image_main'],
      districtId: json['district_id'] is int ? json['district_id'] : int.parse(json['district_id'].toString()),
      isActive: (json['is_active'] == 1 || json['is_active'] == true || json['is_active'] == '1' || 
                 json['is_approved'] == 1 || json['is_approved'] == true || json['is_approved'] == '1' ||
                 json['is_active'] == null), // Default to true if missing
      checkinDay: json['checkin_day'] ?? 0,
      checkinMonth: json['checkin_month'] ?? 0,
      checkinYear: json['checkin_year'] ?? 0,
    );
  }
}
