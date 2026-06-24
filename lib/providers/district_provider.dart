import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../services/district_service.dart';
import '../services/api_service.dart';
import '../models/district_model.dart';
import '../models/business_model.dart';
import '../models/extra_models.dart';
import '../models/place_model.dart';
import 'package:geolocator/geolocator.dart';

class DistrictProvider extends ChangeNotifier {
  final DistrictService _districtService = DistrictService();
  
  List<District> _districts = [];
  Map<String, dynamic> _districtDetails = {};
  Map<String, dynamic> _mayorInfo = {};
  Map<String, dynamic> _contactInfo = {};
  List<MunicipalGuide> _municipalGuide = [];
  List<Business> _businesses = [];
  List<Pharmacy> _pharmacies = [];
  List<Pharmacy> _dutyPharmacies = [];
  List<Hospital> _hospitals = [];
  List<Announcement> _announcements = [];
  List<Event> _events = [];
  List<Service> _services = [];
  List<dynamic> _guideItems = [];
  List<dynamic> _categories = [];
  List<LiveBroadcast> _liveBroadcasts = [];
  List<CustomMenu> _customMenus = [];
  List<dynamic> _globalEvents = [];
  List<Place> _places = [];
  
  Business? _currentBusiness;
  Place? _currentPlace;
  Map<String, dynamic> _weatherData = {};
  Map<String, dynamic> _districtsWeather = {}; // <DistrictId, WeatherData>
  String? _error;
  Position? _currentPosition;
  Map<String, String> _districtDistances = {}; // <DistrictId, DistanceString>

  bool _isLoadingDistricts = false;
  bool _isLoadingDetails = false;
  bool _isLoadingBusinesses = false;
  bool _isLoadingBusinessDetail = false;
  bool _isLoadingPharmacies = false;
  bool _isLoadingAnnouncements = false;
  bool _isLoadingEvents = false;
  bool _isLoadingServices = false;
  bool _isLoadingGuide = false;
  bool _isLoadingLive = false;
  bool _isLoadingCustomMenus = false;
  bool _isLoadingGlobalEvents = false;
  bool _isLoadingPlaces = false;
  bool _isLoadingPlaceDetail = false;

  // Getters
  List<District> get districts => _districts;
  Map<String, dynamic> get districtDetails => _districtDetails;
  Map<String, dynamic> get mayorInfo => _mayorInfo;
  Map<String, dynamic> get contactInfo => _contactInfo;
  List<MunicipalGuide> get municipalGuide => _municipalGuide;
  List<Business> get businesses => _businesses;
  List<Pharmacy> get pharmacies => _pharmacies;
  List<Pharmacy> get dutyPharmacies => _dutyPharmacies;
  List<Hospital> get hospitals => _hospitals;
  List<Announcement> get announcements => _announcements;
  List<Event> get events => _events;
  List<Service> get services => _services;
  List<dynamic> get guideItems => _guideItems;
  List<dynamic> get categories => _categories;
  List<LiveBroadcast> get liveBroadcasts => _liveBroadcasts;
  List<CustomMenu> get customMenus => _customMenus;
  List<dynamic> get globalEvents => _globalEvents;
  List<Place> get places => _places;
  
  Business? get currentBusiness => _currentBusiness;
  Place? get currentPlace => _currentPlace;
  Map<String, dynamic> get weatherData => _weatherData;
  Map<String, dynamic> get districtsWeather => _districtsWeather;
  String? get error => _error;
  Position? get currentPosition => _currentPosition;
  Map<String, String> get districtDistances => _districtDistances;

  bool get isLoadingDistricts => _isLoadingDistricts;
  bool get isLoadingDetails => _isLoadingDetails;
  bool get isLoadingBusinesses => _isLoadingBusinesses;
  bool get isLoadingBusinessDetail => _isLoadingBusinessDetail;
  bool get isLoadingPharmacies => _isLoadingPharmacies;
  bool get isLoadingAnnouncements => _isLoadingAnnouncements;
  bool get isLoadingEvents => _isLoadingEvents;
  bool get isLoadingServices => _isLoadingServices;
  bool get isLoadingGuide => _isLoadingGuide;
  bool get isLoadingLive => _isLoadingLive;
  bool get isLoadingCustomMenus => _isLoadingCustomMenus;
  bool get isLoadingGlobalEvents => _isLoadingGlobalEvents;
  bool get isLoadingPlaces => _isLoadingPlaces;
  bool get isLoadingPlaceDetail => _isLoadingPlaceDetail;

  // Methods
  Future<void> fetchDistricts() async {
    _isLoadingDistricts = true;
    _error = null;
    notifyListeners();
    try {
      final box = Hive.box('rotarehber_cache');
      final localData = box.get('districts');
      if (localData != null && localData is List) {
        _districts = localData.map((d) => District.fromJson(Map<String, dynamic>.from(d as Map))).toList();
        sortDistrictsByProximity();
        notifyListeners(); // Arayüzü anında önbellekten yükle
      }

      List<dynamic> data = [];
      try {
        data = await ApiService.getDistricts();
      } catch (e) {
        // iOS ilk kurulum izin penceresi network'ü bloklarsa diye 3 saniye sonra 1 kez daha dene
        await Future.delayed(const Duration(seconds: 3));
        data = await ApiService.getDistricts();
      }
      
      _districts = data.map((d) => District.fromJson(d)).toList();
      box.put('districts', data); // Arka planda gelen en güncel veriyi kaydet
      
      sortDistrictsByProximity();
      updateDistrictsWeather();
    } catch (e) {
      if (_districts.isEmpty) {
        _error = "Bağlantı Hatası: ${e.toString()}";
      }
      debugPrint("District fetch error: $e");
    } finally {
      _isLoadingDistricts = false;
      notifyListeners();
    }
  }

  Future<void> sortDistrictsByProximity() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // Request only if it hasn't been permanently denied to avoid UI hang
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.whileInUse || permission == LocationPermission.always) {
        Position position;
        try {
          position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.low,
            timeLimit: const Duration(seconds: 5),
          ).timeout(const Duration(seconds: 6));
        } catch (e) {
          debugPrint("Location fallback: $e");
          position = await Geolocator.getLastKnownPosition() ?? 
            Position(longitude: 0, latitude: 0, timestamp: DateTime.now(), accuracy: 0, altitude: 0, heading: 0, speed: 0, speedAccuracy: 0, altitudeAccuracy: 0, headingAccuracy: 0);
        }
        
        _currentPosition = position;
        _districtDistances.clear();

        _districts.sort((a, b) {
          if (a.lat == null || a.lng == null) return 1;
          if (b.lat == null || b.lng == null) return -1;
          
          double distA = Geolocator.distanceBetween(position.latitude, position.longitude, a.lat!, a.lng!);
          double distB = Geolocator.distanceBetween(position.latitude, position.longitude, b.lat!, b.lng!);
          
          _districtDistances[a.id.toString()] = (distA / 1000).toStringAsFixed(1) + " KM";
          _districtDistances[b.id.toString()] = (distB / 1000).toStringAsFixed(1) + " KM";

          return distA.compareTo(distB);
        });
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Sorting or Location error: $e");
    }
  }

  Future<void> updateDistrictsWeather() async {
    final dio = Dio();
    List<Future<void>> weatherFutures = [];

    for (var d in _districts) {
      if (d.lat != null && d.lng != null) {
        weatherFutures.add(
          dio.get(
            'https://api.open-meteo.com/v1/forecast',
            queryParameters: {
              'latitude': d.lat,
              'longitude': d.lng,
              'current_weather': true,
            }
          ).then((res) {
            if (res.data != null && res.data['current_weather'] != null) {
              _districtsWeather[d.id.toString()] = res.data['current_weather'];
            }
          }).catchError((e) {
            debugPrint("Weather fetch error: $e");
          })
        );
      }
    }
    await Future.wait(weatherFutures);
    notifyListeners();
  }

  Future<void> fetchDistrictDetails(String districtId) async {
    _isLoadingDetails = true;
    notifyListeners();
    try {
      _districtDetails = await _districtService.getDistrictDetail(districtId);
      
      final dist = _districtDetails['district'] ?? {};
      final settings = _districtDetails['settings'] ?? {};
      
      _mayorInfo = {
        'name': (dist['mayor_name'] != null && dist['mayor_name'] != "") ? dist['mayor_name'] : (settings['mayor_name'] ?? "Belediye Başkanı"),
        'title': (dist['mayor_title'] != null && dist['mayor_title'] != "") ? dist['mayor_title'] : (settings['mayor_title'] ?? "Başkan"),
        'title_en': (dist['mayor_title_en'] != null && dist['mayor_title_en'] != "") ? dist['mayor_title_en'] : (settings['mayor_title_en'] ?? "Mayor"),
        'image': (dist['mayor_image'] != null && dist['mayor_image'] != "") ? dist['mayor_image'] : (settings['mayor_image'] ?? "assets/img/baskan.png"),
        'bio': (dist['mayor_bio'] != null && dist['mayor_bio'] != "") ? dist['mayor_bio'] : (settings['mayor_bio'] ?? ""),
        'bio_en': (dist['mayor_bio_en'] != null && dist['mayor_bio_en'] != "") ? dist['mayor_bio_en'] : (settings['mayor_bio_en'] ?? ""),
      };
      
      _contactInfo = {
        'address': settings['site_address'] ?? "Adres Bilgisi",
        'phone': settings['site_phone'] ?? "Telefon No",
        'email': settings['site_email'] ?? "Email Adresi",
      };

      if (_districtDetails['municipal_guide'] != null && _districtDetails['municipal_guide'] is List) {
        final List mg = _districtDetails['municipal_guide'];
        _municipalGuide = mg
            .where((m) => m is Map)
            .map((m) => MunicipalGuide.fromJson(Map<String, dynamic>.from(m as Map)))
            .where((guide) {
              // Deneme verilerini (asdasd, adsasd vb.) filtrele
              final title = guide.title.toLowerCase();
              return !title.contains('asdasd') && !title.contains('adsasd') && title.length > 3;
            })
            .toList();
      }

      if (_districtDetails['categories'] != null && _districtDetails['categories'] is List) {
        _categories = List<dynamic>.from(_districtDetails['categories']);
      }
      
      if (_districtDetails['weather'] != null && _districtDetails['weather'] is Map) {
        _weatherData = Map<String, dynamic>.from(_districtDetails['weather']);
      }
      
      if (_districtDetails['live_broadcasts'] != null && _districtDetails['live_broadcasts'] is List) {
        final List lb = _districtDetails['live_broadcasts'];
        _liveBroadcasts = lb.where((l) => l is Map).map((l) => LiveBroadcast.fromJson(Map<String, dynamic>.from(l as Map))).toList();
      }

      if (_districtDetails['custom_menus'] != null && _districtDetails['custom_menus'] is List) {
        final List cm = _districtDetails['custom_menus'];
        _customMenus = cm.where((m) => m is Map).map((m) => CustomMenu.fromJson(Map<String, dynamic>.from(m as Map))).toList();
      }

      if (_districtDetails['announcements'] != null && _districtDetails['announcements'] is List) {
        final List ann = _districtDetails['announcements'];
        _announcements = ann.where((a) => a is Map).map((a) => Announcement.fromJson(Map<String, dynamic>.from(a as Map))).toList();
      }
    } catch (e) {
      debugPrint("Error fetching district details: $e");
    } finally {
      _isLoadingDetails = false;
      notifyListeners();
    }
  }

  Future<void> fetchBusinesses(String districtId, String categoryId) async {
    _isLoadingBusinesses = true;
    notifyListeners();
    try {
      // Map common slugs to database category names for Businesses
      String mappedCategory = categoryId;
      final String s = categoryId.toLowerCase();
      
      if (s.contains('hotel') || s.contains('accommodation') || s.contains('otel') || s.contains('konaklama')) {
        mappedCategory = 'Hotel';
      } else if (s.contains('restaurant') || s.contains('dining') || s.contains('lokanta') || s.contains('yemek')) {
        mappedCategory = 'Restaurant';
      } else if (s.contains('hospital') || s.contains('health') || s.contains('saglik') || s.contains('hastane')) {
        mappedCategory = 'Hospital';
      }

      final response = await _districtService.getBusinessesByCategory(districtId, mappedCategory);
      _businesses = response.where((b) => b is Map).map((b) => Business.fromJson(Map<String, dynamic>.from(b as Map))).toList();
      
      if (_currentPosition != null) {
        _businesses.sort((a, b) {
          if (a.lat == null || a.lng == null) return 1;
          if (b.lat == null || b.lng == null) return -1;
          double distA = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, a.lat!, a.lng!);
          double distB = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, b.lat!, b.lng!);
          return distA.compareTo(distB);
        });
      }
    } catch (e) {
      _businesses = [];
    } finally {
      _isLoadingBusinesses = false;
      notifyListeners();
    }
  }

  Future<void> fetchBusinessDetail(String businessId) async {
    _isLoadingBusinessDetail = true;
    _currentBusiness = null;
    notifyListeners();
    try {
      final response = await _districtService.getBusinessDetail(businessId);
      if (response != null) {
        _currentBusiness = Business.fromJson(Map<String, dynamic>.from(response));
      }
    } catch (e) {
      debugPrint("Error fetching business detail: $e");
    } finally {
      _isLoadingBusinessDetail = false;
      notifyListeners();
    }
  }

  Future<void> fetchPharmacies(String districtId) async {
    _isLoadingPharmacies = true;
    notifyListeners();
    try {
      final response = await _districtService.getPharmacyAndHealth(districtId);
      
      // Laravel API returns { pharmacies: [], hospitals: [] } inside data
      if (response != null) {
        if (response['pharmacies'] != null && response['pharmacies'] is List) {
          final List pData = response['pharmacies'];
          _pharmacies = pData.map((p) => Pharmacy.fromJson(Map<String, dynamic>.from(p))).toList();
          _dutyPharmacies = _pharmacies.where((p) => p.isDuty).toList();
        } else {
          _pharmacies = [];
          _dutyPharmacies = [];
        }

        if (response['hospitals'] != null && response['hospitals'] is List) {
          final List hData = response['hospitals'];
          _hospitals = hData.map((h) => Hospital.fromJson(Map<String, dynamic>.from(h))).toList();
        } else {
          _hospitals = [];
        }
      }
    } catch (e) {
      debugPrint("Error fetching pharmacies: $e");
      _pharmacies = [];
      _dutyPharmacies = [];
      _hospitals = [];
    } finally {
      _isLoadingPharmacies = false;
      notifyListeners();
    }
  }

  Future<void> fetchAnnouncements(String districtId) async {
    _isLoadingAnnouncements = true;
    notifyListeners();
    try {
      final List response = await _districtService.getAnnouncements(districtId);
      _announcements = response.where((a) => a is Map).map((a) => Announcement.fromJson(Map<String, dynamic>.from(a as Map))).toList();
    } catch (e) {
      _announcements = [];
    } finally {
      _isLoadingAnnouncements = false;
      notifyListeners();
    }
  }

  Future<void> fetchEvents(String districtId) async {
    _isLoadingEvents = true;
    notifyListeners();
    try {
      final List response = await _districtService.getEvents(districtId);
      _events = response.where((e) => e is Map).map((e) => Event.fromJson(Map<String, dynamic>.from(e as Map))).toList();
    } catch (e) {
      _events = [];
    } finally {
      _isLoadingEvents = false;
      notifyListeners();
    }
  }

  Future<void> fetchServices(String districtId) async {
    _isLoadingServices = true;
    notifyListeners();
    try {
      final List response = await _districtService.getServices(districtId);
      _services = response.where((s) => s is Map).map((s) => Service.fromJson(Map<String, dynamic>.from(s as Map))).toList();
    } catch (e) {
      _services = [];
    } finally {
      _isLoadingServices = false;
      notifyListeners();
    }
  }

  Future<void> fetchGuide() async {
    _isLoadingGuide = true;
    notifyListeners();
    try {
      _guideItems = await _districtService.getGuides();
    } catch (e) {
      _guideItems = [];
    } finally {
      _isLoadingGuide = false;
      notifyListeners();
    }
  }

  Future<void> fetchLiveBroadcasts(String districtId) async {
    _isLoadingLive = true;
    notifyListeners();
    try {
      final response = await _districtService.getLiveBroadcasts(districtId);
      _liveBroadcasts = response.map((l) => LiveBroadcast.fromJson(Map<String, dynamic>.from(l as Map))).toList();
    } catch (e) {
      _liveBroadcasts = [];
    } finally {
      _isLoadingLive = false;
      notifyListeners();
    }
  }

  Future<void> fetchCustomMenus(String districtId) async {
    _isLoadingCustomMenus = true;
    notifyListeners();
    try {
      final box = Hive.box('rotarehber_cache');
      final cacheKey = 'custom_menus_$districtId';
      final localData = box.get(cacheKey);

      if (localData != null && localData is List) {
        _customMenus = localData.map((m) => CustomMenu.fromJson(Map<String, dynamic>.from(m as Map))).toList();
        notifyListeners(); // Resimleri bekletmeden hemen yükle
      }

      final response = await _districtService.getCustomMenus(districtId);
      _customMenus = response.map((m) => CustomMenu.fromJson(Map<String, dynamic>.from(m as Map))).toList();
      box.put(cacheKey, response); // Arka planda gelenleri kaydet
    } catch (e) {
      if (_customMenus.isEmpty) _customMenus = [];
    } finally {
      _isLoadingCustomMenus = false;
      notifyListeners();
    }
  }

  Future<void> fetchGlobalEvents() async {
    _isLoadingGlobalEvents = true;
    notifyListeners();
    try {
      final box = Hive.box('rotarehber_cache');
      final localData = box.get('global_events');
      if (localData != null && localData is List) {
        _globalEvents = localData;
        notifyListeners();
      }

      try {
        _globalEvents = await _districtService.getGlobalEvents();
      } catch (e) {
        await Future.delayed(const Duration(seconds: 3));
        _globalEvents = await _districtService.getGlobalEvents();
      }
      box.put('global_events', _globalEvents);
    } catch (e) {
      if (_globalEvents.isEmpty) _globalEvents = [];
    } finally {
      _isLoadingGlobalEvents = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> submitCekGonder(dynamic formData) async {
    if (formData is FormData) {
      return await _districtService.submitCekGonder(formData);
    }
    throw Exception('Invalid form data type');
  }

  Future<void> fetchPlaces(String districtId, {String? category}) async {
    _isLoadingPlaces = true;
    notifyListeners();
    try {
      final response = await _districtService.getPlaces(districtId, category: category);
      _places = response.where((p) => p is Map).map((p) => Place.fromJson(Map<String, dynamic>.from(p as Map))).toList();
      
      if (_currentPosition != null) {
        _places.sort((a, b) {
          if (a.lat == null || a.lng == null) return 1;
          if (b.lat == null || b.lng == null) return -1;
          double distA = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, a.lat!, a.lng!);
          double distB = Geolocator.distanceBetween(_currentPosition!.latitude, _currentPosition!.longitude, b.lat!, b.lng!);
          return distA.compareTo(distB);
        });
      }
    } catch (e) {
      _places = [];
    } finally {
      _isLoadingPlaces = false;
      notifyListeners();
    }
  }

  Future<void> fetchPlaceDetail(int id) async {
    _isLoadingPlaceDetail = true;
    _currentPlace = null;
    notifyListeners();
    try {
      final response = await _districtService.getPlaceDetail(id);
      if (response != null) {
        _currentPlace = Place.fromJson(Map<String, dynamic>.from(response));
      }
    } catch (e) {
      debugPrint("Error fetching place detail: $e");
    } finally {
      _isLoadingPlaceDetail = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────
  // Location Help (getDistanceTo)
  // ─────────────────────────────────────────────
  String? getDistanceTo(double? lat, double? lng) {
    if (_currentPosition == null || lat == null || lng == null) return null;
    try {
      double distanceInMeters = Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        lat,
        lng,
      );
      return (distanceInMeters / 1000).toStringAsFixed(1) + " KM";
    } catch (e) {
      return null;
    }
  }
}
