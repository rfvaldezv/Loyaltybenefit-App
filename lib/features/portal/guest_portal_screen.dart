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

  final String tenantId = '00000000-0000-0000-0000-000000000000'; // Reemplaza con tu GUID real
  
  // Branding
  Color _primaryColor = const Color(0xFF4F46E5);
  Color _secondaryColor = const Color(0xFF8B5CF6);
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _cargarBranding();
  }

  Future<void> _cargarBranding() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.getBranding(tenantId);
      
      if (response.statusCode == 200) {
        setState(() {
          _primaryColor = _hexToColor(response.data['primaryColor'] ?? '#4F46E5');
          _secondaryColor = _hexToColor(response.data['secondaryColor'] ?? '#8B5CF6');
          _logoUrl = response.data['logoUrl'];
        });
      }
    } catch (e) {
      // Colores por defecto si falla
    }
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

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
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Si hay logo, lo mostramos
            if (_logoUrl != null && _logoUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Image.network(
                  'https://api.loyaltybenefit.com$_logoUrl',
                  height: 30,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            const Text('Mis Puntos'),
          ],
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.card_giftcard, size: 80, color: _primaryColor),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Consultar Saldo', style: TextStyle(fontSize: 16)),
            ),
            if (_saldo != null) ...[
              const SizedBox(height: 32),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [_primaryColor, _secondaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
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
                              _consultarSaldo();
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
              ),
            ]
          ],
        ),
      ),
    );
  }
}
