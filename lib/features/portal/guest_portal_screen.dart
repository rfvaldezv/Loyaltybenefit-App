import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/network/api_client.dart';
import 'statement_screen.dart';
import 'rewards_screen.dart';

class GuestPortalScreen extends ConsumerStatefulWidget {
  final String? initialEmail;
  final String? initialName;

  const GuestPortalScreen({
    super.key,
    this.initialEmail,
    this.initialName,
  });

  @override
  ConsumerState<GuestPortalScreen> createState() => _GuestPortalScreenState();
}

class _GuestPortalScreenState extends ConsumerState<GuestPortalScreen> {
  final _emailController = TextEditingController();
  int? _saldo;

  final String tenantId = '00000000-0000-0000-0000-000000000000';
  
  Color _primaryColor = const Color(0xFF4F46E5);
  Color _secondaryColor = const Color(0xFF8B5CF6);
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    _cargarBranding();
    
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
      _consultarSaldo();
    }
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
      // Ignorar error de branding
    }
  }

  Color _hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  Future<void> _consultarSaldo() async {
    if (_emailController.text.isEmpty) return;

    try {
      final api = ref.read(apiClientProvider);
      final response = await api.get('/api/portal/balance?email=${_emailController.text}&tenantId=$tenantId');

      if (response.statusCode == 200) {
        setState(() => _saldo = response.data['puntos']);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _mostrarModalOtp() {
    final codeController = TextEditingController();
    final codeFocusNode = FocusNode();
    bool isModalLoading = false;
    bool isCodeSent = false;
    String? debugOtp;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            Future<void> solicitarOtp() async {
              if (_emailController.text.isEmpty) return;
              setStateModal(() => isModalLoading = true);
              
              try {
                final api = ref.read(apiClientProvider);
                final response = await api.requestOtp(_emailController.text.trim());
                if (response.statusCode == 200) {
                  setStateModal(() {
                    isCodeSent = true;
                    debugOtp = response.data['debug_otp'];
                  });
                  Future.delayed(const Duration(milliseconds: 300), () {
                    if (mounted) codeFocusNode.requestFocus();
                  });
                }
              } on DioException catch (e) {
                String msg = e.response?.statusCode == 404 ? 'El correo no está registrado.' : 'Error de conexión.';
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.redAccent));
                }
              } finally {
                setStateModal(() => isModalLoading = false);
              }
            }

            Future<void> verificarOtp() async {
              if (codeController.text.isEmpty) return;
              setStateModal(() => isModalLoading = true);
              
              try {
                final api = ref.read(apiClientProvider);
                final response = await api.verifyOtp(_emailController.text.trim(), codeController.text.trim());
                if (response.statusCode == 200) {
                  if (dialogContext.mounted) Navigator.pop(dialogContext);
                  _consultarSaldo();
                }
              } on DioException {
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(const SnackBar(content: Text('Código incorrecto'), backgroundColor: Colors.redAccent));
                }
              } finally {
                setStateModal(() => isModalLoading = false);
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF1E293B),
              title: Text(isCodeSent ? 'Ingresa el código' : 'Verificar Identidad', style: const TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isCodeSent) ...[
                    const Text('Te enviaremos un código a tu correo.', style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _emailController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Correo electrónico',
                        labelStyle: const TextStyle(color: Colors.white54),
                        filled: true, fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                  ] else ...[
                    Text('Código enviado a ${_emailController.text}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    if (debugOtp != null)
                      Text('(Simulado: $debugOtp)', style: const TextStyle(color: Colors.green, fontSize: 12)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: codeController,
                      focusNode: codeFocusNode,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 6,
                      style: const TextStyle(color: Colors.white, fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        hintText: '000000',
                        hintStyle: const TextStyle(color: Colors.white24, letterSpacing: 8),
                        counterText: '',
                        filled: true, fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.white54)),
                ),
                ElevatedButton(
                  onPressed: isModalLoading ? null : (isCodeSent ? verificarOtp : solicitarOtp),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigoAccent),
                  child: isModalLoading 
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(isCodeSent ? 'Ingresar' : 'Enviar Código'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFromOtp = widget.initialEmail != null && widget.initialEmail!.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_logoUrl != null && _logoUrl!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Image.network('http://localhost:5265$_logoUrl', height: 30, errorBuilder: (c, e, s) => const SizedBox.shrink()),
              ),
            Text(isFromOtp ? 'Hola, ${widget.initialName}' : 'Mis Puntos'),
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
            
            if (!isFromOtp) ...[
              const Text('Consulta tu saldo de lealtad', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                onPressed: () {
                  if (_emailController.text.isNotEmpty) _mostrarModalOtp();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Acceder con OTP', style: TextStyle(fontSize: 16)),
              ),
            ] else ...[
              Text('Bienvenido de nuevo', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[800])),
              const SizedBox(height: 24),
            ],
            
            if (_saldo != null) ...[
              const SizedBox(height: 32),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_primaryColor, _secondaryColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Text('Tu saldo actual', style: TextStyle(color: Colors.white70)),
                        Text('$_saldo Puntos', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => StatementScreen(email: _emailController.text, tenantId: tenantId)));
                          },
                          icon: const Icon(Icons.history, color: Colors.white),
                          label: const Text('Ver mi historial', style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: () async {
                            final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => RewardsScreen(email: _emailController.text, tenantId: tenantId, currentPoints: _saldo ?? 0)));
                            if (res == true) _consultarSaldo();
                          },
                          icon: const Icon(Icons.storefront, color: Colors.white),
                          label: const Text('Catálogo de Premios', style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white54), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
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
