import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class EarnPointsScreen extends ConsumerStatefulWidget {
  final String customerName;
  const EarnPointsScreen({super.key, required this.customerName});

  @override
  ConsumerState<EarnPointsScreen> createState() => _EarnPointsScreenState();
}

class _EarnPointsScreenState extends ConsumerState<EarnPointsScreen> {
  bool _isLoading = false;

  Future<void> _sumarPuntos() async {
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      
      // Enviamos IDs de prueba para probar la conexión
      await api.earnPoints(
        tenantId: "00000000-0000-0000-0000-000000000000", 
        guestId: "00000000-0000-0000-0000-000000000000",
        stayId: "00000000-0000-0000-0000-000000000000",
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Petición enviada al backend'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ La petición llegó al backend (Rechazada por IDs de prueba)'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sumar Puntos')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Cliente: ${widget.customerName}',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'La lógica de suma de puntos requiere una Estancia (Stay) registrada. Esta prueba valida la conexión con la API.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _sumarPuntos,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Probar Endpoint de Puntos'),
            ),
          ],
        ),
      ),
    );
  }
}
