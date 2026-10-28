import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiClient {
  final Dio _dio;
  String? _token;

  ApiClient()
      : _dio = Dio(
          BaseOptions(
            //baseUrl: 'https://api.loyaltybenefit.com',
            baseUrl: 'http://localhost:5265', 
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

  Future<Response> createCustomer(String name, String email, {String? phone}) async {
    final nameParts = name.trim().split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    return _dio.post('/api/customers', data: {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
    });
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

  // ==========================================
  // MÉTODOS DEL PORTAL DEL HUÉSPED
  // ==========================================

  Future<Response> getBranding(String tenantId) {
    return _dio.get('/api/portal/branding', queryParameters: {
      'tenantId': tenantId,
    });
  }

  Future<Response> getStatement(String email, String tenantId) {
    return _dio.get('/api/portal/statement', queryParameters: {
      'email': email,
      'tenantId': tenantId,
    });
  }

  Future<Response> getRewards(String tenantId) {
    return _dio.get('/api/portal/rewards', queryParameters: {
      'tenantId': tenantId,
    });
  }

  Future<Response> redeemReward({
    required String tenantId,
    required String guestEmail,
    required String rewardName,
    required int pointsToRedeem,
    bool isPhysical = false,
    String? shippingAddress,
    String? rewardId,
  }) {
    return _dio.post('/api/portal/redeem', data: {
      'tenantId': tenantId,
      'guestEmail': guestEmail,
      'rewardName': rewardName,
      'pointsToRedeem': pointsToRedeem,
      'isPhysical': isPhysical,
      if (shippingAddress != null) 'shippingAddress': shippingAddress,
      if (rewardId != null) 'rewardId': rewardId,
    });
  }

  Future<Response> requestOtp(String email) {
    return _dio.post('/api/portal/auth/request-otp', data: {'email': email});
  }

  Future<Response> verifyOtp(String email, String code) {
    return _dio.post('/api/portal/auth/verify-otp', data: {'email': email, 'code': code});
  }
}

// EL PROVIDER VA AFUERA DE LA CLASE
final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
