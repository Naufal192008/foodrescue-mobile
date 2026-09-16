import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../utils/auth_storage.dart';

class ApiException implements Exception {
  final int? statusCode;
  final String message;
  ApiException(this.statusCode, this.message);

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await AuthStorage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          handler.next(error);
        },
      ),
    );
  }

  static final ApiClient _instance = ApiClient._internal();
  static ApiClient get instance => _instance;

  late final Dio dio;

  /// GET dengan parsing error otomatis
  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
  }) async {
    try {
      final res = await dio.get(path, queryParameters: query);
      return res.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<dynamic> post(
    String path, {
    Object? data,
  }) async {
    try {
      final res = await dio.post(path, data: data);
      return res.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<dynamic> put(
    String path, {
    Object? data,
  }) async {
    try {
      final res = await dio.put(path, data: data);
      return res.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<dynamic> patch(
    String path, {
    Object? data,
  }) async {
    try {
      final res = await dio.patch(path, data: data);
      return res.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final res = await dio.delete(path);
      return res.data;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  ApiException _mapError(DioException e) {
    if (e.response?.data is Map) {
      final data = e.response!.data as Map<String, dynamic>;
      if (data['error'] is String) {
        return ApiException(e.response?.statusCode, data['error'] as String);
      }
      if (data['message'] is String) {
        return ApiException(e.response?.statusCode, data['message'] as String);
      }
    }
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException(
          null,
          'Koneksi lambat. Periksa jaringan internet kamu.',
        );
      case DioExceptionType.connectionError:
        return ApiException(
          null,
          'Tidak dapat terhubung ke server. Periksa koneksi internet.',
        );
      default:
        return ApiException(
          e.response?.statusCode,
          e.message ?? 'Terjadi kesalahan tidak dikenal',
        );
    }
  }
}