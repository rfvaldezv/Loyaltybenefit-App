import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import 'statement_screen.dart';
import 'rewards_screen.dart';

class GuestPortalScreen extends ConsumerStatefulWidget {
  const GuestPortalScreen({super.key});

  @override
  ConsumerState<GuestPortalScreen> createState() => _GuestPortalScreenState();
}

class _GuestPortalScreenState extends ConsumerState<GuestPortalScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  int? _saldo;

  // ⚠️ Tu GUID de tenant real (para pruebas usamos el dummy)
  final String tenantId = '00000000-0000-0000-0000-000000000000';

  Future<void> _consultarSaldo() async {
    if (_emailController.text.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/api/portal/balance?email=${_emailController.text}&tenantId=$tenantId');

      if (response.statusCode == 200) {
        setState(() {
          _saldo = response.data['puntos'];
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
                      const SizedBox(height: 16),
                      // Botón de Historial
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => StatementScreen(
                                email: _emailController.text,
                                tenantId: tenantId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.history, color: Colors.white),
                        label: const Text('Ver mi historial', style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Botón de Catálogo de Premios
                      OutlinedButton.icon(
                        onPressed: () async {
                          final res = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => RewardsScreen(
                                email: _emailController.text,
                                tenantId: tenantId,
                                currentPoints: _saldo ?? 0,
                              ),
                            ),
                          );
                          if (res == true) {
                            _consultarSaldo(); // Recargar saldo si canjeó algo
                          }
                        },
                        icon: const Icon(Icons.storefront, color: Colors.white),
                        label: const Text('Catálogo de Premios', style: TextStyle(color: Colors.white)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white54),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
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
