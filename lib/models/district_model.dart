class District {
  final int id;
  final String name;
  final String? nameEn;
  final String? slug;
  final String? image;
  final String? logo;
  final String? welcomeText;
  final double? lat;
  final double? lng;
  final bool isActive;

  District({
    required this.id,
    required this.name,
    this.nameEn,
    this.slug,
    this.image,
    this.logo,
    this.welcomeText,
    this.lat,
    this.lng,
    this.isActive = true,
  });


  factory District.fromJson(Map<String, dynamic> json) {
    return District(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      name: json['name'] ?? '',
      nameEn: json['name_en'],
      slug: json['slug'],
      image: json['image'],
      logo: json['logo'],
      welcomeText: json['welcome_text'],
      lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
      lng: json['lng'] != null ? double.tryParse(json['lng'].toString()) : null,

      isActive: (json['is_active'] == 1 || json['is_active'] == true || json['is_active'] == '1'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'image': image,
      'lat': lat,
      'lng': lng,
      'is_active': isActive ? 1 : 0,
    };
  }
}
