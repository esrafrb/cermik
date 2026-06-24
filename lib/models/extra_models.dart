class LiveBroadcast {
  final int id;
  final String title;
  final String? titleEn;
  final String? description;
  final String? descriptionEn;
  final String? image;
  final String? youtubeUrl;
  final String? facebookUrl;
  final double? lat;
  final double? lng;

  LiveBroadcast({
    required this.id,
    required this.title,
    this.titleEn,
    this.description,
    this.descriptionEn,
    this.image,
    this.youtubeUrl,
    this.facebookUrl,
    this.lat,
    this.lng,
  });

  factory LiveBroadcast.fromJson(Map<String, dynamic> json) {
    return LiveBroadcast(
      id: json['id'],
      title: json['title'] ?? '',
      titleEn: json['title_en'],
      description: json['description'],
      descriptionEn: json['description_en'],
      image: json['image'],
      youtubeUrl: json['youtube_url'],
      facebookUrl: json['facebook_url'],
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lng: json['lng'] != null ? double.tryParse(json['lng'].toString()) : null,
    );
  }
}

class CustomMenu {
  final int id;
  final String nameTr;
  final String? nameEn;
  final String slug;
  final String? image;
  final String icon;
  final String? targetUrl;
  final int? placeId;
  final double? lat;
  final double? lng;

  CustomMenu({
    required this.id,
    required this.nameTr,
    this.nameEn,
    required this.slug,
    this.image,
    required this.icon,
    this.targetUrl,
    this.placeId,
    this.lat,
    this.lng,
  });

  factory CustomMenu.fromJson(Map<String, dynamic> json) {
    return CustomMenu(
      id: json['id'],
      nameTr: json['name_tr'] ?? '',
      nameEn: json['name_en'],
      slug: json['slug'] ?? '',
      image: json['image'],
      icon: json['icon'] ?? 'fa-link',
      targetUrl: json['target_url'],
      placeId: json['place_id'] != null ? int.tryParse(json['place_id'].toString()) : null,
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lng: json['lng'] != null ? double.tryParse(json['lng'].toString()) : null,
    );
  }
}

class MunicipalGuide {
  final int id;
  final String title;
  final String? titleEn;
  final String? content;
  final String? contentEn;
  final String? image;
  final String? phone;
  final String? category;
  final int? districtId;
  final bool isActive;

  MunicipalGuide({
    required this.id,
    required this.title,
    this.titleEn,
    this.content,
    this.contentEn,
    this.image,
    this.phone,
    this.category,
    this.districtId,
    this.isActive = true,
  });

  factory MunicipalGuide.fromJson(Map<String, dynamic> json) {
    return MunicipalGuide(
      id: json['id'] is int ? json['id'] : int.parse(json['id']?.toString() ?? '0'),
      title: json['title'] ?? json['name'] ?? '',
      titleEn: json['title_en'] ?? json['name_en'],
      content: json['description'] ?? json['content'],
      contentEn: json['description_en'] ?? json['content_en'],
      image: json['image'],
      phone: json['phone']?.toString(),
      category: json['category'],
      districtId: json['district_id'] is int ? json['district_id'] : (int.tryParse(json['district_id']?.toString() ?? '')),
      isActive: (json['is_active'] == 1 || json['is_active'] == true || json['is_active'] == '1'),
    );
  }
}

class Event {
  final int id;
  final String title;
  final String? titleEn;
  final String? description;
  final String? descriptionEn;
  final String? image;
  final String? eventDate;
  final String? locationName;
  final int? districtId;
  final bool isActive;

  Event({
    required this.id,
    required this.title,
    this.titleEn,
    this.locationName,
    this.description,
    this.descriptionEn,
    this.image,
    this.eventDate,
    this.districtId,
    this.isActive = true,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      titleEn: json['title_en'],
      locationName: json['location_name'],
      description: json['description'],
      descriptionEn: json['description_en'],
      image: json['image'],
      eventDate: json['event_date'],
      districtId: json['district_id'],
      isActive: (json['is_active'] == 1 || json['is_active'] == true || json['is_active'] == '1'),
    );
  }
}

class Service {
  final int id;
  final String title;
  final String? titleEn;
  final String? description;
  final String? descriptionEn;
  final String? image;
  final int? districtId;
  final int status;
  final int progress;

  Service({
    required this.id,
    required this.title,
    this.titleEn,
    this.description,
    this.descriptionEn,
    this.image,
    this.districtId,
    this.status = 0,
    this.progress = 0,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      titleEn: json['title_en'],
      description: json['description'],
      descriptionEn: json['description_en'],
      image: json['image'],
      districtId: json['district_id'],
      status: json['status'] is int ? json['status'] : (int.tryParse(json['status']?.toString() ?? '0') ?? 0),
      progress: json['progress'] is int ? json['progress'] : (int.tryParse(json['progress']?.toString() ?? '0') ?? 0),
    );
  }
}

class Announcement {
  final int id;
  final String title;
  final String? titleEn;
  final String content;
  final String? contentEn;
  final String? image;
  final int? districtId;
  final String? createdAt;

  Announcement({
    required this.id,
    required this.title,
    this.titleEn,
    required this.content,
    this.contentEn,
    this.image,
    this.districtId,
    this.createdAt,
  });

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      title: json['title'] ?? '',
      titleEn: json['title_en'],
      content: json['content'] ?? '',
      contentEn: json['content_en'],
      image: json['image'],
      districtId: json['district_id'],
      createdAt: json['created_at'],
    );
  }
}
