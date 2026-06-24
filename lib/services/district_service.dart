import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../models/district_model.dart';
import '../services/api_service.dart';

class DistrictService {
  final DioClient _dioClient = DioClient();

  Future<List<District>> getDistricts() async {
    try {
      final response = await _dioClient.dio.get('districts');
      final List<dynamic> data = (response.data is Map && response.data.containsKey('data')) 
          ? response.data['data'] 
          : response.data;
      return data.map((d) => District.fromJson(d)).toList();
    } catch (e) {
      throw Exception('İlçeler yüklenemedi: $e');
    }
  }

  Future<Map<String, dynamic>> getDistrictDetail(String districtId) async {
    try {
      final response = await _dioClient.dio.get('districts/$districtId');
      return (response.data is Map && response.data.containsKey('data')) 
          ? response.data['data'] 
          : response.data;
    } catch (e) {
      throw Exception('İlçe detayları yüklenemedi: $e');
    }
  }

  Future<List<dynamic>> getBusinessesByCategory(String districtId, String category) async {
    try {
      final response = await _dioClient.dio.get('businesses', queryParameters: {
        'district_id': districtId,
        'category': category,
      });
      return (response.data is Map && response.data.containsKey('data')) 
          ? response.data['data'] 
          : response.data;
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getBusinessDetail(String id) async {
    try {
      final response = await _dioClient.dio.get('businesses/$id');
      return (response.data is Map && response.data.containsKey('data')) 
          ? response.data['data'] 
          : response.data;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getPharmacyAndHealth(String districtId) async {
    try {
      final response = await _dioClient.dio.get('pharmacies', queryParameters: {'district_id': districtId});
      return (response.data is Map && response.data.containsKey('data')) ? Map<String, dynamic>.from(response.data['data']) : {};
    } catch (e) { return {}; }
  }

  Future<List<dynamic>> getPharmacies(String districtId) async {
    try {
      final response = await _dioClient.dio.get('pharmacies', queryParameters: {'district_id': districtId});
      return (response.data is Map && response.data.containsKey('data')) ? response.data['data'] : response.data;
    } catch (e) { return []; }
  }

  Future<List<dynamic>> getDutyPharmacies(String districtId) async {
    try {
      final response = await _dioClient.dio.get('pharmacies/duty', queryParameters: {'district_id': districtId});
      return (response.data is Map && response.data.containsKey('data')) ? response.data['data'] : response.data;
    } catch (e) { return []; }
  }

  Future<List<dynamic>> getAnnouncements(String districtId) async {
    final id = int.tryParse(districtId);
    if (id == null) return [];
    return await ApiService.getAnnouncements(districtId: id);
  }

  Future<List<dynamic>> getEvents(String districtId) async {
    final id = int.tryParse(districtId);
    if (id == null) return [];
    return await ApiService.getEvents(districtId: id);
  }

  Future<List<dynamic>> getServices(String districtId) async {
    final id = int.tryParse(districtId);
    if (id == null) return [];
    return await ApiService.getServices(districtId: id);
  }

  Future<List<dynamic>> getGuides() async {
    try {
      final response = await _dioClient.dio.get('guides');
      return (response.data is Map && response.data.containsKey('data')) ? response.data['data'] : response.data;
    } catch (e) { return []; }
  }

  Future<List<dynamic>> getLiveBroadcasts(String districtId) async {
    try {
      final response = await _dioClient.dio.get('live-broadcasts', queryParameters: {'district_id': districtId});
      return (response.data is Map && response.data.containsKey('data')) ? response.data['data'] : response.data;
    } catch (e) { return []; }
  }

  Future<List<dynamic>> getCustomMenus(String districtId) async {
    try {
      final response = await _dioClient.dio.get('custom-menus', queryParameters: {'district_id': districtId});
      return (response.data is Map && response.data.containsKey('data')) ? response.data['data'] : response.data;
    } catch (e) { return []; }
  }

  Future<List<dynamic>> getPlaces(String districtId, {String? category}) async {
    final id = int.tryParse(districtId);
    if (id == null) return [];
    return await ApiService.getPlaces(districtId: id, category: category);
  }

  Future<Map<String, dynamic>?> getPlaceDetail(int id) async {
    return await ApiService.getPlaceDetails(id);
  }

  Future<Map<String, dynamic>> submitCekGonder(FormData formData) async {
    try {
      final response = await _dioClient.dio.post('cek-gonder', data: formData);
      return response.data;
    } catch (e) {
      throw Exception('Form gönderilemedi: $e');
    }
  }

  Future<List<dynamic>> getGlobalEvents() async {
    return await ApiService.getEvents(globalStatus: 'APPROVED');
  }
}
