// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'dart:html' as html; // Necesario para leer la URL en Flutter Web
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
  String _tenantId = '00000000-0000-0000-0000-000000000000'; // Default
  
  Color _primaryColor = const Color(0xFF4F46E5);
  Color _secondaryColor = const Color(0xFF8B5CF6);
  String? _logoUrl;

  @override
  void initState() {
    super.initState();
    
    // 1. Lógica para leer el QR (Parámetro 'property' de la URL)
    try {
      final uri = Uri.parse(html.window.location.href);
      final propertyIdFromUrl = uri.queryParameters['property'];
      if (propertyIdFromUrl != null && propertyIdFromUrl.isNotEmpty) {
        _tenantId = propertyIdFromUrl;
      }
    } catch (e) {
      // Si falla (porque no es web o no hay URL), se queda el default
    }

    _cargarBranding();
    
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      _emailController.text = widget.initialEmail!;
      _consultarSaldo();
    }
  }

  Future<void> _cargarBranding() async {
    try {
      final api = ref.read(apiClientProvider);
      final response = await api.getBranding(_tenantId);
      if (response.statusCode == 200) {
        setState(() {
          _primaryColor = _hexToColor(response.data['primaryColor'] ?? '#4F46E5');
          _secondaryColor = _hexToColor(response.data['secondaryColor'] ?? '#8B5CF6');
          _logoUrl = response.data['logoUrl'];
        });
      }
    } catch (e) {
      // Usar colores por defecto si falla
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
      final response = await api.get('/api/portal/balance?email=${_emailController.text}&tenantId=$_tenantId');

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

  void _cerrarSesion() {
    setState(() {
      _saldo = null;
      _emailController.clear();
    });
  }

  void _mostrarModalOtp() {
    final codeController = TextEditingController();
    final codeFocusNode = FocusNode();
    bool isModalLoading = false;
    bool isCodeSent = false;

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
                  setStateModal(() => isCodeSent = true);
                  
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
                    Text('Hemos enviado un código a ${_emailController.text}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
                    TextButton(
                      onPressed: isModalLoading ? null : () => solicitarOtp(),
                      child: const Text('Reenviar código', style: TextStyle(color: Colors.indigoAccent, fontSize: 14)),
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
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_logoUrl != null && _logoUrl!.isNotEmpty && _logoUrl != "")
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Image.network('https://api.loyaltybenefit.com$_logoUrl', height: 30, errorBuilder: (c, e, s) => const SizedBox.shrink()),
              ),
            Text(_saldo != null ? 'Mi Cuenta' : 'Mis Puntos', style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_saldo != null)
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: 'Cerrar Sesión',
              onPressed: _cerrarSesion,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.card_giftcard, size: 100, color: _primaryColor.withValues(alpha: 0.8)),
            const SizedBox(height: 24),

            Text(
              _saldo != null ? 'Bienvenido de nuevo' : 'Bienvenido a tu Programa de Lealtad',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              _saldo != null ? 'Aquí tienes el resumen de tu cuenta.' : 'Consulta tu saldo y descubre los premios que tenemos para ti.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.white54),
            ),
            const SizedBox(height: 32),

            if (_saldo == null) ...[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Tu correo electrónico',
                        labelStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(Icons.email, color: Colors.white54),
                        filled: true,
                        fillColor: const Color(0xFF0F172A),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_emailController.text.isNotEmpty) _mostrarModalOtp();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Ingresar a mi cuenta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Card(
                elevation: 10,
                shadowColor: _primaryColor.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [_primaryColor, _secondaryColor], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        const Text('Tu saldo actual', style: TextStyle(color: Colors.white70, fontSize: 16)),
                        const SizedBox(height: 8),
                        Text('$_saldo Puntos', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildActionButton(Icons.history, 'Historial', () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => StatementScreen(email: _emailController.text, tenantId: _tenantId)));
                            }),
                            _buildActionButton(Icons.storefront, 'Premios', () async {
                              final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => RewardsScreen(email: _emailController.text, tenantId: _tenantId, currentPoints: _saldo ?? 0)));
                              if (res == true) _consultarSaldo();
                            }),
                          ],
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

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 28),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
