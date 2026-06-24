import 'dart:convert';
import 'package:flutter/foundation.dart';

Map<String, dynamic>? _safeDecodeJson(dynamic value) {
  if (value == null) return null;
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is String && value.isNotEmpty) {
    try {
      final decoded = jsonDecode(value);
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {}
  }
  return null;
}

class Business {
  final int id;
  final String name;
  final String? nameEn;
  final String category;
  final int districtId;
  final String? address;
  final String? addressEn;
  final String? phone;
  final String? email;
  final String? website;
  final String? description;
  final String? descriptionEn;
  final String? image;
  final String? imageMain;
  final double? lat;
  final double? lng;
  final String? workingHours;
  final bool hasOrder;
  final String? orderLink;
  final bool hasPosDevice;
  final bool isActive;
  final List<Product> products;
  final List<ProductCategory> categories;
  final List<Product> uncategorizedProducts;
  final List<String> imageGallery;
  final String? panorama360;
  final Map<String, dynamic>? workingHoursData;
  final Map<String, dynamic>? hotelInfo;
  final int popularScore;
  final String? qrCodePath;
  final Map<String, dynamic> stats;

  Business({
    required this.id,
    required this.name,
    this.nameEn,
    required this.category,
    required this.districtId,
    this.address,
    this.addressEn,
    this.phone,
    this.email,
    this.website,
    this.description,
    this.descriptionEn,
    this.image,
    this.imageMain,
    this.lat,
    this.lng,
    this.workingHours,
    this.hasOrder = false,
    this.orderLink,
    this.hasPosDevice = true,
    this.isActive = true,
    this.products = const [],
    this.categories = const [],
    this.uncategorizedProducts = const [],
    this.imageGallery = const [],
    this.panorama360,
    this.workingHoursData,
    this.hotelInfo,
    this.popularScore = 0,
    this.qrCodePath,
    this.stats = const {'monthly_views': 0, 'yearly_views': 0},
  });

  factory Business.fromJson(Map<String, dynamic> json) {
    try {
      return Business(
        id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
        name: (json['business_name'] ?? json['name'])?.toString() ?? 'Bilinmiyor',
        nameEn: (json['business_name_en'] ?? json['name_en'])?.toString(),
        category: json['category']?.toString() ?? '',
        districtId: int.tryParse(json['district_id']?.toString() ?? '') ?? 0,
        address: json['address']?.toString(),
        addressEn: json['address_en']?.toString(),
        phone: json['phone']?.toString(),
        email: json['email']?.toString(),
        website: json['website']?.toString(),
        description: json['description']?.toString(),
        descriptionEn: json['description_en']?.toString(),
        image: json['image']?.toString(),
        imageMain: json['image_main']?.toString(),
        lat: json['lat'] != null ? double.tryParse(json['lat'].toString()) : null,
        lng: json['lng'] != null ? double.tryParse(json['lng'].toString()) : null,
        workingHours: json['working_hours']?.toString(),
        hasOrder: (json['has_order'] == 1 || json['has_order'] == true || json['has_order'] == '1' || json['order_enabled'] == 1 || json['order_enabled'] == true || json['order_enabled'] == '1'),
        orderLink: json['order_link']?.toString(),
        hasPosDevice: json.containsKey('has_pos_device') ? (json['has_pos_device'] == 1 || json['has_pos_device'] == true || json['has_pos_device'] == '1') : true,
        isActive: (json['is_active'] == 1 || json['is_active'] == true || json['is_active'] == '1'),
        products: (json['products'] is List) ? (json['products'] as List).map((p) => Product.fromJson(p is Map ? Map<String, dynamic>.from(p) : {})).toList() : [],
        categories: (json['categories'] is List) ? (json['categories'] as List).map((c) => ProductCategory.fromJson(c is Map ? Map<String, dynamic>.from(c) : {})).toList() : [],
        uncategorizedProducts: (json['uncategorized_products'] is List) ? (json['uncategorized_products'] as List).map((p) => Product.fromJson(p is Map ? Map<String, dynamic>.from(p) : {})).toList() : [],
        imageGallery: (json['image_gallery'] is List) ? List<String>.from(json['image_gallery']) : [],
        panorama360: json['panorama_360']?.toString(),
        workingHoursData: (json['working_hours'] is Map) ? Map<String, dynamic>.from(json['working_hours']) : _safeDecodeJson(json['working_hours']),
        hotelInfo: (json['hotel_info'] is Map) ? Map<String, dynamic>.from(json['hotel_info']) : _safeDecodeJson(json['hotel_info']),
        popularScore: int.tryParse(json['popular_score']?.toString() ?? '0') ?? 0,
        qrCodePath: json['qr_code_path']?.toString(),
        stats: (json['stats'] is Map) ? Map<String, dynamic>.from(json['stats']) : {'monthly_views': 0, 'yearly_views': 0},
      );
    } catch (e) {
      if (kDebugMode) print("FATAL Error Parsing Business: $e");
      return Business(
        id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
        name: json['name']?.toString() ?? 'Hata (Veri)',
        category: '',
        districtId: 0,
      );
    }
  }
}

class ProductCategory {
  final int id;
  final String name;
  final String? nameEn;
  final List<Product> products;

  ProductCategory({
    required this.id,
    required this.name,
    this.nameEn,
    this.products = const [],
  });

  factory ProductCategory.fromJson(Map<String, dynamic> json) {
    return ProductCategory(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      name: json['name']?.toString() ?? 'Bilinmiyor',
      nameEn: json['name_en']?.toString(),
      products: (json['products'] is List) ? (json['products'] as List).map((p) => Product.fromJson(p is Map ? Map<String, dynamic>.from(p) : {})).toList() : [],
    );
  }
}

class ProductVariant {
  final String name;
  final double priceDiff;

  ProductVariant({required this.name, required this.priceDiff});

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      name: json['name']?.toString() ?? '',
      priceDiff: double.tryParse(json['price_diff']?.toString() ?? '0') ?? 0.0,
    );
  }
}

class Product {
  final int id;
  final String name;
  final String? nameEn;
  final String? description;
  final String? descriptionEn;
  final String? price;
  final String? image;
  final List<ProductVariant> variants;

  Product({
    required this.id,
    required this.name,
    this.nameEn,
    this.description,
    this.descriptionEn,
    this.price,
    this.image,
    this.variants = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      return Product(
        id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
        name: json['product_name']?.toString() ?? json['name']?.toString() ?? 'Bilinmiyor',
        nameEn: json['product_name_en']?.toString() ?? json['name_en']?.toString(),
        description: json['description']?.toString(),
        descriptionEn: json['description_en']?.toString(),
        price: json['price']?.toString() ?? '0',
        image: json['image']?.toString(),
        variants: (json['variants'] is List) ? (json['variants'] as List).map((v) => ProductVariant.fromJson(v is Map ? Map<String, dynamic>.from(v) : {})).toList() : [],
      );
    } catch (e) {
      if (kDebugMode) print("Error parsing Product: $e");
      return Product(id: 0, name: 'Veri Hatası', price: '0');
    }
  }
}

class Pharmacy {
  final int id;
  final String name;
  final int districtId;
  final String? address;
  final String? phone;
  final double? lat;
  final double? lng;
  final bool isDuty;

  Pharmacy({
    required this.id,
    required this.name,
    required this.districtId,
    this.address,
    this.phone,
    this.lat,
    this.lng,
    this.isDuty = false,
  });

  factory Pharmacy.fromJson(Map<String, dynamic> json) {
    try {
      return Pharmacy(
        id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
        name: json['name']?.toString() ?? 'Bilinmiyor',
        districtId: int.tryParse(json['district_id']?.toString() ?? '') ?? 0,
        address: json['address']?.toString(),
        phone: json['phone']?.toString(),
        lat: double.tryParse(json['lat']?.toString() ?? ''),
        lng: double.tryParse(json['lng']?.toString() ?? ''),
        isDuty: (json['is_duty'] == 1 || json['is_duty'] == true || json['is_duty'] == '1' || json['is_on_duty'] == 1 || json['is_on_duty'] == '1'),
      );
    } catch (e) {
      return Pharmacy(id: 0, name: 'Hata', districtId: 0);
    }
  }
}

class Hospital {
  final int id;
  final String name;
  final String? nameEn;
  final int? districtId;
  final String? description;
  final String? descriptionEn;
  final String? address;
  final String? phone;
  final double? lat;
  final double? lng;
  final String? imageMain;
  final String? panorama360;

  Hospital({
    required this.id,
    required this.name,
    this.nameEn,
    this.districtId,
    this.description,
    this.descriptionEn,
    this.address,
    this.phone,
    this.lat,
    this.lng,
    this.imageMain,
    this.panorama360,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    try {
      return Hospital(
        id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
        name: json['name']?.toString() ?? 'Bilinmiyor',
        nameEn: json['name_en']?.toString(),
        districtId: int.tryParse(json['district_id']?.toString() ?? ''),
        description: json['description']?.toString(),
        descriptionEn: json['description_en']?.toString(),
        address: json['address']?.toString(),
        phone: json['phone']?.toString(),
        lat: double.tryParse(json['lat']?.toString() ?? ''),
        lng: double.tryParse(json['lng']?.toString() ?? ''),
        imageMain: json['image_main']?.toString(),
        panorama360: json['panorama_360']?.toString(),
      );
    } catch (e) {
      return Hospital(id: 0, name: 'Hata');
    }
  }
}
