import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class EarnPointsScreen extends ConsumerStatefulWidget {
  final String customerName;
  final String guestId;

  const EarnPointsScreen({
    super.key, 
    required this.customerName,
    required this.guestId,
  });

  @override
  ConsumerState<EarnPointsScreen> createState() => _EarnPointsScreenState();
}

class _EarnPointsScreenState extends ConsumerState<EarnPointsScreen> {
  final _amountController = TextEditingController(text: '1500');
  bool _isLoading = false;

  Future<void> _registrarEstancia() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa un monto válido')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      
      final response = await api.createStay(
        tenantId: "6890d5bd-2eb6-4803-9d0b-2af4868b5ccc", // Concept Hotel
        guestId: widget.guestId,
        stayId: GuidGenerator.generate(),
        amount: amount,
      );

      if (mounted) {
        // Leemos la respuesta del backend
        final data = response.data;
        final puntos = data['puntosGanados'] ?? data['PuntosGanados'] ?? 0;
        final mensaje = data['mensaje'] ?? data['Mensaje'] ?? 'Éxito';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ $mensaje\n⭐ Puntos otorgados: $puntos'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pop(context); // Volver a la pantalla anterior
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ Error: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Estancia')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Cliente: ${widget.customerName}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Ingresa el monto total de la estancia para calcular los puntos.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Monto (MXN)',
                prefixIcon: const Icon(Icons.attach_money),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isLoading ? null : _registrarEstancia,
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Calcular y Sumar Puntos'),
            ),
          ],
        ),
      ),
    );
  }
}

class GuidGenerator {
  static String generate() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replaceAllMapped(RegExp(r'[xy]'), (match) {
      final r = (DateTime.now().microsecondsSinceEpoch % 16).toRadixString(16);
      return match.group(0) == 'x' ? r : (int.parse(r, radix: 16) & 0x3 | 0x8).toRadixString(16);
    });
  }
}
