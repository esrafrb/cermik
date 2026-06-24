import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/imsakiye_model.dart';
import '../config/app_config.dart';

class ImsakiyeService {
  Future<List<ImsakiyeModel>?> fetchImsakiye(int districtId) async {
    try {
      final response = await http.get(Uri.parse('${AppConfig.webBaseUrl}/api/get_imsakiye.php?district_id=$districtId'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'success' && data['data'] != null) {
          List<ImsakiyeModel> list = [];
          for (var item in data['data']) {
            list.add(ImsakiyeModel.fromJson(item));
          }
          return list;
        }
      }
      return null;
    } catch (e) {
      print('Imsakiye fetch error: $e');
      return null;
    }
  }
}
