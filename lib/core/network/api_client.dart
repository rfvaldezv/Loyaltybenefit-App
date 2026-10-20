import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiClient {
  final Dio _dio;
  
  // Aquí guardaremos el token en memoria
  String? _token;

  ApiClient()
      : _dio = Dio(
          BaseOptions(
            baseUrl: 'http://localhost:5265',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    // Interceptor: Antes de cada petición, si hay token, lo agregamos al Header
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
    ));
    _dio.interceptors.add(LogInterceptor(responseBody: true));
  }

  void setToken(String token) {
    _token = token;
  }

  void clearToken() {
    _token = null;
  }

  Future<Response> get(String path) => _dio.get(path);
  Future<Response> post(String path, {dynamic data}) => _dio.post(path, data: data);
  // Método para obtener los hoteles (Tenants)
  Future<Response> getTenants() {
    return _dio.get('/api/tenants');
  }
}

// Provider global
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});
