import 'package:dio/dio.dart';
import '../constants/app_constants.dart';

class DioClient {
  late final Dio _dio;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConstants.baseUrl,
        connectTimeout: Duration(milliseconds: AppConstants.connectionTimeout),
        receiveTimeout: Duration(milliseconds: AppConstants.receiveTimeout),
        responseType: ResponseType.json, // JSON yanıtlarının otomatik dönüştürülmesi
      ),
    );
  }

  Dio get dio => _dio;
}
