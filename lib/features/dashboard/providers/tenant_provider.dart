import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/tenant_model.dart';

// FutureProvider que se encarga de traer la lista de hoteles
final tenantsProvider = FutureProvider.autoDispose<List<TenantModel>>((ref) async {
  final api = ref.watch(apiClientProvider);
  
  try {
    final response = await api.getTenants();
    
    if (response.statusCode == 200) {
      final List<dynamic> data = response.data;
      return data.map((json) => TenantModel.fromJson(json)).toList();
    }
    return [];
  } catch (e) {
    throw Exception('Error al cargar hoteles: $e');
  }
});
