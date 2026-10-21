import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiClient {
  final Dio _dio;
  String? _token;

  ApiClient()
      : _dio = Dio(
          BaseOptions(
	    baseUrl: 'https://api.loyaltybenefit.com',
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 10),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
    ));
  }

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;

  Future<Response> get(String path) => _dio.get(path);
  Future<Response> post(String path, {dynamic data}) => _dio.post(path, data: data);

  Future<Response> getTenants() => _dio.get('/api/tenants');
  
  Future<Response> getTenantById(String id) => _dio.get('/api/tenants/$id');

  Future<Response> createCustomer({required String name, required String email}) {
    return _dio.post('/api/customers', data: {'name': name, 'email': email});
  }

  Future<Response> earnPoints({
    required String tenantId,
    required String guestId,
    required String stayId,
  }) {
    return _dio.post('/api/loyalty/earn', data: {
      'tenantId': tenantId,
      'guestId': guestId,
      'stayId': stayId,
    });
  }

  // 👇 AQUÍ ESTÁ EL MÉTODO QUE FALTABA (bien adentro de la clase)
  Future<Response> createStay({
    required String tenantId,
    required String guestId,
    required String stayId,
    required double amount,
  }) {
    return _dio.post('/api/stays', data: {
      'tenantId': tenantId,
      'guestId': guestId,
      'stayId': stayId,
      'amount': amount,
    });
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
