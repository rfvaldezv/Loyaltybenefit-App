import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';

class GuestPortalScreen extends ConsumerStatefulWidget {
  const GuestPortalScreen({super.key});

  @override
  ConsumerState<GuestPortalScreen> createState() => _GuestPortalScreenState();
}

class _GuestPortalScreenState extends ConsumerState<GuestPortalScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  int? _saldo;

  Future<void> _consultarSaldo() async {
    if (_emailController.text.isEmpty) return;
    
    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/api/portal/balance?email=${_emailController.text}');
      
      if (response.statusCode == 200) {
        setState(() {
          _saldo = response.data['puntos'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Puntos')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.card_giftcard, size: 80, color: Color(0xFF4F46E5)),
            const SizedBox(height: 16),
            const Text(
              'Consulta tu saldo de lealtad',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Tu correo electrónico',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _consultarSaldo,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Consultar Saldo'),
            ),
            if (_saldo != null) ...[
              const SizedBox(height: 32),
              Card(
                color: const Color(0xFF4F46E5),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      const Text('Tu saldo actual', style: TextStyle(color: Colors.white70)),
                      Text(
                        '$_saldo Puntos',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}
